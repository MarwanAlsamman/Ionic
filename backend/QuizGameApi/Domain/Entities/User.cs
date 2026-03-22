namespace QuizGame.Domain.Entities;

/// <summary>A registered user in the system (username-only auth)</summary>
public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Username { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public ICollection<Player> Players { get; set; } = new List<Player>();
}
