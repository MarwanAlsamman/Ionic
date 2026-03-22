using QuizGame.Domain.Enums;

namespace QuizGame.Domain.Entities;

/// <summary>A trivia question with four multiple-choice options</summary>
public class Question
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Text { get; set; } = string.Empty;
    public string OptionA { get; set; } = string.Empty;
    public string OptionB { get; set; } = string.Empty;
    public string OptionC { get; set; } = string.Empty;
    public string OptionD { get; set; } = string.Empty;

    /// <summary>The correct answer: "A", "B", "C", or "D"</summary>
    public string CorrectOption { get; set; } = string.Empty;

    public Difficulty Difficulty { get; set; } = Difficulty.Medium;
    public string Category { get; set; } = string.Empty;
}
