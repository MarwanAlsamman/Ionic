namespace QuizGame.Domain.Enums;

/// <summary>Game room lifecycle states</summary>
public enum GameStatus
{
    Waiting,    // Players are joining
    InProgress, // Game is running
    Finished    // Game has ended
}

/// <summary>Question difficulty level</summary>
public enum Difficulty
{
    Easy,
    Medium,
    Hard
}
