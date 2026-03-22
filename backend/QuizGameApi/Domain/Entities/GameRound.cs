namespace QuizGame.Domain.Entities;

/// <summary>One round = one question being asked in a game room</summary>
public class GameRound
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid GameRoomId { get; set; }
    public Guid QuestionId { get; set; }
    public int RoundNumber { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }

    // Navigation
    public Question? Question { get; set; }
    public ICollection<PlayerAnswer> PlayerAnswers { get; set; } = new List<PlayerAnswer>();
}
