using AutoMapper;
using QuizGame.Application.DTOs;
using QuizGame.Application.Interfaces;
using QuizGame.Domain.Entities;
using QuizGame.Domain.Enums;
using QuizGame.Domain.Interfaces;

namespace QuizGame.Application.Services;

public class GameRoomService : IGameRoomService
{
    private readonly IRepository<GameRoom> _roomRepo;
    private readonly IRepository<Player> _playerRepo;
    private readonly IRepository<User> _userRepo;
    private readonly IMapper _mapper;
    private readonly ILogger<GameRoomService> _logger;

    public GameRoomService(
        IRepository<GameRoom> roomRepo,
        IRepository<Player> playerRepo,
        IRepository<User> userRepo,
        IMapper mapper,
        ILogger<GameRoomService> logger)
    {
        _roomRepo = roomRepo;
        _playerRepo = playerRepo;
        _userRepo = userRepo;
        _mapper = mapper;
        _logger = logger;
    }

    public async Task<GameRoomDto> CreateRoomAsync(Guid hostUserId, int maxPlayers, int totalQuestions)
    {
        var host = await _userRepo.GetByIdAsync(hostUserId)
            ?? throw new InvalidOperationException($"User {hostUserId} not found.");

        var room = new GameRoom
        {
            RoomCode = GenerateRoomCode(),
            HostUserId = hostUserId,
            MaxPlayers = Math.Clamp(maxPlayers, 2, 16),
            TotalQuestions = Math.Clamp(totalQuestions, 5, 30),
            Status = GameStatus.Waiting
        };

        await _roomRepo.AddAsync(room);

        // Auto-add host as first player
        var hostPlayer = new Player
        {
            UserId = hostUserId,
            GameRoomId = room.Id,
            IsReady = true,
            User = host
        };
        await _playerRepo.AddAsync(hostPlayer);

        room.Players.Add(hostPlayer);

        _logger.LogInformation("Room {Code} created by {Username}.", room.RoomCode, host.Username);
        return MapRoom(room);
    }

    public async Task<GameRoomDto?> GetRoomByCodeAsync(string roomCode)
    {
        var room = await _roomRepo.FirstOrDefaultAsync(r => r.RoomCode == roomCode.ToUpper());
        if (room == null) return null;
        await HydrateRoom(room);
        return MapRoom(room);
    }

    public async Task<GameRoomDto?> GetRoomByIdAsync(Guid roomId)
    {
        var room = await _roomRepo.GetByIdAsync(roomId);
        if (room == null) return null;
        await HydrateRoom(room);
        return MapRoom(room);
    }

    public async Task<PlayerDto> JoinRoomAsync(string roomCode, Guid userId, string connectionId)
    {
        var room = await _roomRepo.FirstOrDefaultAsync(r => r.RoomCode == roomCode.ToUpper())
            ?? throw new InvalidOperationException($"Room '{roomCode}' not found.");

        if (room.Status != GameStatus.Waiting)
            throw new InvalidOperationException("Cannot join a game that is already in progress or finished.");

        var user = await _userRepo.GetByIdAsync(userId)
            ?? throw new InvalidOperationException($"User {userId} not found.");

        // Check if player is already in the room
        var existingPlayer = await _playerRepo.FirstOrDefaultAsync(
            p => p.UserId == userId && p.GameRoomId == room.Id);

        if (existingPlayer != null)
        {
            existingPlayer.ConnectionId = connectionId;
            existingPlayer.User = user;
            await _playerRepo.UpdateAsync(existingPlayer);
            return _mapper.Map<PlayerDto>(existingPlayer);
        }

        await HydrateRoom(room);
        if (room.Players.Count >= room.MaxPlayers)
            throw new InvalidOperationException("Room is full.");

        var player = new Player
        {
            UserId = userId,
            GameRoomId = room.Id,
            ConnectionId = connectionId,
            IsReady = false,
            User = user
        };

        await _playerRepo.AddAsync(player);
        _logger.LogInformation("Player {Username} joined room {Code}.", user.Username, roomCode);
        return _mapper.Map<PlayerDto>(player);
    }

    public async Task LeaveRoomAsync(Guid roomId, Guid userId)
    {
        var player = await _playerRepo.FirstOrDefaultAsync(
            p => p.UserId == userId && p.GameRoomId == roomId);

        if (player != null)
            await _playerRepo.DeleteAsync(player.Id);
    }

    public async Task UpdatePlayerConnectionAsync(Guid userId, Guid roomId, string connectionId)
    {
        var player = await _playerRepo.FirstOrDefaultAsync(
            p => p.UserId == userId && p.GameRoomId == roomId);

        if (player != null)
        {
            player.ConnectionId = connectionId;
            await _playerRepo.UpdateAsync(player);
        }
    }

    // ─── Private Helpers ─────────────────────────────────────────────────

    /// <summary>Fill in navigation collections (Players + their Users)</summary>
    private async Task HydrateRoom(GameRoom room)
    {
        var players = (await _playerRepo.FindAsync(p => p.GameRoomId == room.Id)).ToList();
        foreach (var p in players)
            p.User = await _userRepo.GetByIdAsync(p.UserId);

        room.Players = players;
    }

    private GameRoomDto MapRoom(GameRoom room) => _mapper.Map<GameRoomDto>(room);

    /// <summary>Generate a unique 6-character uppercase alphanumeric room code</summary>
    private static string GenerateRoomCode()
    {
        const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        var random = new Random();
        return new string(Enumerable.Repeat(chars, 6)
            .Select(s => s[random.Next(s.Length)]).ToArray());
    }
}
