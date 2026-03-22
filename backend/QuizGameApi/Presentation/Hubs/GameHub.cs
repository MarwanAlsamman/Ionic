using System.Collections.Concurrent;
using Microsoft.AspNetCore.SignalR;
using QuizGame.Application.Interfaces;
using QuizGame.Domain.Interfaces;
using QuizGame.Domain.Entities;

namespace QuizGame.Presentation.Hubs;

/// <summary>
/// SignalR Hub — the real-time backbone of the quiz game.
///
/// CLIENT → SERVER methods (invoked by Flutter app):
///   JoinRoom(roomCode, userId)     — join SignalR group for a room
///   LeaveRoom()                    — leave current room
///   SubmitAnswer(questionId, option, timeMs) — answer a question
///   StartGame(roomCode)            — host starts the game
///   PlayerReady(roomCode)          — mark self as ready
///
/// SERVER → CLIENT events (received by Flutter app):
///   PlayerJoined(PlayerJoinedDto)
///   PlayerLeft(PlayerLeftDto)
///   PlayerReady(playerId, username)
///   GameStarted({TotalRounds})
///   QuestionReceived(QuestionDto)
///   TimerTick(secondsLeft)
///   RoundEnded(RoundResultDto)
///   GameEnded(GameEndedDto)
///   Error(message)
/// </summary>
public class GameHub : Hub
{
    // Maps connectionId → (userId, roomId) for quick lookups on disconnect
    private static readonly ConcurrentDictionary<string, (Guid UserId, Guid RoomId)> _connectionMap = new();

    private readonly IGameRoomService _roomService;
    private readonly IGameManager _gameManager;
    private readonly IRepository<Player> _playerRepo;
    private readonly IRepository<User> _userRepo;
    private readonly ILogger<GameHub> _logger;

    public GameHub(
        IGameRoomService roomService,
        IGameManager gameManager,
        IRepository<Player> playerRepo,
        IRepository<User> userRepo,
        ILogger<GameHub> logger)
    {
        _roomService = roomService;
        _gameManager = gameManager;
        _playerRepo = playerRepo;
        _userRepo = userRepo;
        _logger = logger;
    }

    // ─── Connection lifecycle ────────────────────────────────────────────

    public override async Task OnConnectedAsync()
    {
        _logger.LogInformation("Client connected: {ConnectionId}", Context.ConnectionId);
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        _logger.LogInformation("Client disconnected: {ConnectionId}", Context.ConnectionId);

        // Auto-leave the room if connection drops
        if (_connectionMap.TryRemove(Context.ConnectionId, out var info))
        {
            await HandlePlayerLeave(info.UserId, info.RoomId);
        }

        await base.OnDisconnectedAsync(exception);
    }

    // ─── Hub Methods (Client → Server) ───────────────────────────────────

    /// <summary>
    /// Join a game room. Creates SignalR group membership and updates
    /// the player's ConnectionId in the database.
    /// </summary>
    public async Task JoinRoom(string roomCode, string userId)
    {
        try
        {
            if (!Guid.TryParse(userId, out var userGuid))
            {
                await Clients.Caller.SendAsync("Error", "Invalid user ID format.");
                return;
            }

            // Register player in the room (creates player record if needed)
            var player = await _roomService.JoinRoomAsync(roomCode, userGuid, Context.ConnectionId);

            // Get updated room info
            var room = await _roomService.GetRoomByCodeAsync(roomCode);
            if (room == null)
            {
                await Clients.Caller.SendAsync("Error", "Room not found.");
                return;
            }

            // Track connection → user/room mapping
            _connectionMap[Context.ConnectionId] = (userGuid, room.Id);

            // Join the SignalR group for this room
            await Groups.AddToGroupAsync(Context.ConnectionId, room.Id.ToString());

            // Update player's ConnectionId in DB
            await _roomService.UpdatePlayerConnectionAsync(userGuid, room.Id, Context.ConnectionId);

            // Notify all players in the room
            await Clients.Group(room.Id.ToString()).SendAsync("PlayerJoined", new
            {
                Player = player,
                TotalPlayers = room.Players.Count
            });

            // Send current room state to the caller
            await Clients.Caller.SendAsync("RoomJoined", room);

            _logger.LogInformation("User {UserId} joined room {RoomCode}", userId, roomCode);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in JoinRoom for {ConnectionId}", Context.ConnectionId);
            await Clients.Caller.SendAsync("Error", ex.Message);
        }
    }

    /// <summary>Mark the current player as ready to play</summary>
    public async Task PlayerReady(string roomCode)
    {
        try
        {
            if (!_connectionMap.TryGetValue(Context.ConnectionId, out var info))
            {
                await Clients.Caller.SendAsync("Error", "You are not in a room.");
                return;
            }

            var player = await _playerRepo.FirstOrDefaultAsync(
                p => p.UserId == info.UserId && p.GameRoomId == info.RoomId);

            if (player == null)
            {
                await Clients.Caller.SendAsync("Error", "Player not found.");
                return;
            }

            player.IsReady = true;
            await _playerRepo.UpdateAsync(player);

            var user = await _userRepo.GetByIdAsync(player.UserId);

            await Clients.Group(info.RoomId.ToString()).SendAsync("PlayerReady", new
            {
                PlayerId = player.Id,
                Username = user?.Username ?? "Unknown"
            });
        }
        catch (Exception ex)
        {
            await Clients.Caller.SendAsync("Error", ex.Message);
        }
    }

    /// <summary>
    /// Host starts the game. Only the host of the room may call this.
    /// Delegates to GameManager which runs the game loop as a background Task.
    /// </summary>
    public async Task StartGame(string roomCode)
    {
        try
        {
            var room = await _roomService.GetRoomByCodeAsync(roomCode);
            if (room == null)
            {
                await Clients.Caller.SendAsync("Error", "Room not found.");
                return;
            }

            if (!_connectionMap.TryGetValue(Context.ConnectionId, out var info))
            {
                await Clients.Caller.SendAsync("Error", "You are not in a room.");
                return;
            }

            // Only the host can start
            if (room.HostUserId != info.UserId)
            {
                await Clients.Caller.SendAsync("Error", "Only the host can start the game.");
                return;
            }

            if (_gameManager.IsGameActive(room.Id))
            {
                await Clients.Caller.SendAsync("Error", "Game is already running.");
                return;
            }

            _logger.LogInformation("Host {UserId} starting game in room {RoomCode}", info.UserId, roomCode);
            await _gameManager.StartGameAsync(room.Id);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in StartGame");
            await Clients.Caller.SendAsync("Error", ex.Message);
        }
    }

    /// <summary>
    /// Player submits an answer for the current question.
    /// GameManager validates it against the current round and records it.
    /// </summary>
    public async Task SubmitAnswer(string questionId, string selectedOption, long answerTimeMs)
    {
        try
        {
            if (!_connectionMap.TryGetValue(Context.ConnectionId, out var info))
            {
                await Clients.Caller.SendAsync("Error", "You are not in a room.");
                return;
            }

            if (!Guid.TryParse(questionId, out var questionGuid))
            {
                await Clients.Caller.SendAsync("Error", "Invalid question ID.");
                return;
            }

            var player = await _playerRepo.FirstOrDefaultAsync(
                p => p.UserId == info.UserId && p.GameRoomId == info.RoomId);

            if (player == null)
            {
                await Clients.Caller.SendAsync("Error", "Player not found.");
                return;
            }

            await _gameManager.SubmitAnswerAsync(
                info.RoomId, player.Id, questionGuid, selectedOption, answerTimeMs);

            // Acknowledge receipt
            await Clients.Caller.SendAsync("AnswerReceived", new { QuestionId = questionId, SelectedOption = selectedOption });
        }
        catch (Exception ex)
        {
            await Clients.Caller.SendAsync("Error", ex.Message);
        }
    }

    /// <summary>Leave the current room explicitly</summary>
    public async Task LeaveRoom()
    {
        if (_connectionMap.TryRemove(Context.ConnectionId, out var info))
        {
            await HandlePlayerLeave(info.UserId, info.RoomId);
        }
    }

    // ─── Private Helpers ─────────────────────────────────────────────────

    private async Task HandlePlayerLeave(Guid userId, Guid roomId)
    {
        try
        {
            var user = await _userRepo.GetByIdAsync(userId);
            var player = await _playerRepo.FirstOrDefaultAsync(
                p => p.UserId == userId && p.GameRoomId == roomId);

            if (player != null)
            {
                var remainingCount = (await _playerRepo.FindAsync(p => p.GameRoomId == roomId)).Count() - 1;

                await Clients.Group(roomId.ToString()).SendAsync("PlayerLeft", new
                {
                    PlayerId = player.Id,
                    Username = user?.Username ?? "Unknown",
                    TotalPlayers = Math.Max(0, remainingCount)
                });

                await _roomService.LeaveRoomAsync(roomId, userId);
            }

            await Groups.RemoveFromGroupAsync(Context.ConnectionId, roomId.ToString());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error handling player leave for UserId={UserId}", userId);
        }
    }
}
