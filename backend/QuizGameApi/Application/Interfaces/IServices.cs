using QuizGame.Application.DTOs;
using QuizGame.Domain.Entities;

namespace QuizGame.Application.Interfaces;

/// <summary>User management operations</summary>
public interface IUserService
{
    Task<UserDto> CreateUserAsync(string username);
    Task<UserDto?> GetUserByIdAsync(Guid id);
    Task<UserDto?> GetUserByUsernameAsync(string username);
}

/// <summary>Game room lifecycle management</summary>
public interface IGameRoomService
{
    Task<GameRoomDto> CreateRoomAsync(Guid hostUserId, int maxPlayers, int totalQuestions);
    Task<GameRoomDto?> GetRoomByCodeAsync(string roomCode);
    Task<GameRoomDto?> GetRoomByIdAsync(Guid roomId);
    Task<PlayerDto> JoinRoomAsync(string roomCode, Guid userId, string connectionId);
    Task LeaveRoomAsync(Guid roomId, Guid userId);
    Task UpdatePlayerConnectionAsync(Guid userId, Guid roomId, string connectionId);
}

/// <summary>
/// Core game engine — controls rounds, timers, scoring, and SignalR broadcasts.
/// Runs the game loop as a background Task for each active room.
/// </summary>
public interface IGameManager
{
    /// <summary>Start the game for a room (host only)</summary>
    Task StartGameAsync(Guid roomId);

    /// <summary>Called by the Hub when a player submits an answer</summary>
    Task SubmitAnswerAsync(Guid roomId, Guid playerId, Guid questionId, string selectedOption, long answerTimeMs);

    /// <summary>Force-stop a game (e.g. host disconnected)</summary>
    Task StopGameAsync(Guid roomId);

    /// <summary>Check whether a game is currently active for a room</summary>
    bool IsGameActive(Guid roomId);
}
