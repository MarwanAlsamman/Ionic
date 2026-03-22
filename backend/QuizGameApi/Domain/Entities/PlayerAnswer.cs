namespace QuizGame.Domain.Entities;

/// <summary>Records one player's answer to a specific question in a round</summary>
public class PlayerAnswer
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid PlayerId { get; set; }
    public Guid QuestionId { get; set; }
    public Guid GameRoundId { get; set; }

    /// <summary>"A", "B", "C", or "D"</summary>
    public string SelectedOption { get; set; } = string.Empty;

    public bool IsCorrect { get; set; }

    /// <summary>How many milliseconds after the round started the player answered</summary>
    public long AnswerTimeMs { get; set; }

    /// <summary>Points earned this round (base + speed bonus)</summary>
    public int ScoreEarned { get; set; }
}
