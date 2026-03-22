namespace QuizGame.Application.DTOs;

// ─────────────────────────────────────────────
// REQUEST DTOs
// ─────────────────────────────────────────────

/// <summary>Create a new user (username-only registration)</summary>
public record CreateUserRequest(string Username);

/// <summary>Create a new game room</summary>
public record CreateRoomRequest(Guid HostUserId, int MaxPlayers = 8, int TotalQuestions = 10);

/// <summary>Join an existing room using its 6-char code</summary>
public record JoinRoomRequest(string RoomCode, Guid UserId);

// ─────────────────────────────────────────────
// RESPONSE DTOs
// ─────────────────────────────────────────────

/// <summary>Public representation of a user</summary>
public record UserDto(Guid Id, string Username, DateTime CreatedAt);

/// <summary>Player info within a game room</summary>
public record PlayerDto(Guid Id, Guid UserId, string Username, int Score, bool IsReady);

/// <summary>Game room summary including player list</summary>
public record GameRoomDto(
    Guid Id,
    string RoomCode,
    Guid HostUserId,
    string Status,
    int MaxPlayers,
    int TotalQuestions,
    List<PlayerDto> Players,
    DateTime CreatedAt);

/// <summary>
/// Question sent to clients — CorrectOption is intentionally omitted
/// so players cannot cheat by inspecting network traffic.
/// </summary>
public record QuestionDto(
    Guid Id,
    string Text,
    string OptionA,
    string OptionB,
    string OptionC,
    string OptionD,
    string Difficulty,
    string Category,
    int RoundNumber,
    int TotalRounds);

/// <summary>
/// Question data including the correct answer — sent AFTER the round ends
/// </summary>
public record QuestionRevealDto(
    Guid Id,
    string Text,
    string OptionA,
    string OptionB,
    string OptionC,
    string OptionD,
    string CorrectOption,
    string Difficulty,
    string Category);

/// <summary>One entry in the leaderboard</summary>
public record LeaderboardEntryDto(int Rank, Guid PlayerId, string Username, int Score, int ScoreThisRound);

/// <summary>Result sent after each round ends</summary>
public record RoundResultDto(
    int RoundNumber,
    QuestionRevealDto Question,
    List<LeaderboardEntryDto> Leaderboard);

/// <summary>Final game result</summary>
public record GameEndedDto(List<LeaderboardEntryDto> FinalLeaderboard);

/// <summary>Broadcast when a player joins the room</summary>
public record PlayerJoinedDto(PlayerDto Player, int TotalPlayers);

/// <summary>Broadcast when a player leaves the room</summary>
public record PlayerLeftDto(Guid PlayerId, string Username, int TotalPlayers);
