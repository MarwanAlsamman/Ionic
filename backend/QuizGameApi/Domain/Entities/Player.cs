namespace QuizGame.Domain.Entities;

/// <summary>Represents a user participating in a specific game room</summary>
public class Player
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public Guid GameRoomId { get; set; }
    public int Score { get; set; } = 0;
    public bool IsReady { get; set; } = false;

    /// <summary>SignalR connection ID — updated on each connection</summary>
    public string ConnectionId { get; set; } = string.Empty;

    // Navigation
    public User? User { get; set; }
    public GameRoom? GameRoom { get; set; }
    public ICollection<PlayerAnswer> Answers { get; set; } = new List<PlayerAnswer>();
}
