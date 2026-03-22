using QuizGame.Domain.Enums;

namespace QuizGame.Domain.Entities;

/// <summary>A game lobby/room that players join and compete in</summary>
public class GameRoom
{
    public Guid Id { get; set; } = Guid.NewGuid();

    /// <summary>Unique 6-character alphanumeric code players use to join</summary>
    public string RoomCode { get; set; } = string.Empty;

    public Guid HostUserId { get; set; }
    public GameStatus Status { get; set; } = GameStatus.Waiting;
    public int MaxPlayers { get; set; } = 8;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>Total number of questions to ask in this game</summary>
    public int TotalQuestions { get; set; } = 10;

    // Navigation
    public ICollection<Player> Players { get; set; } = new List<Player>();
    public ICollection<GameRound> Rounds { get; set; } = new List<GameRound>();
}
