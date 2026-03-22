using QuizGame.Domain.Entities;
using QuizGame.Domain.Enums;

namespace QuizGame.Infrastructure.Data;

/// <summary>
/// Seeds 30+ trivia questions across 5 categories on application startup.
/// Called once from Program.cs after EF Core ensures the DB is created.
/// </summary>
public static class DataSeeder
{
    public static async Task SeedAsync(QuizGameDbContext context)
    {
        // Only seed if the questions table is empty
        if (context.Questions.Any()) return;

        var questions = new List<Question>
        {
            // ─── SCIENCE (10 questions) ───────────────────────────────

            new()
            {
                Text = "What is the chemical formula for water?",
                OptionA = "H2O", OptionB = "CO2", OptionC = "NaCl", OptionD = "H2SO4",
                CorrectOption = "A", Difficulty = Difficulty.Easy, Category = "Science"
            },
            new()
            {
                Text = "Which planet is closest to the Sun?",
                OptionA = "Venus", OptionB = "Earth", OptionC = "Mercury", OptionD = "Mars",
                CorrectOption = "C", Difficulty = Difficulty.Easy, Category = "Science"
            },
            new()
            {
                Text = "What is the powerhouse of the cell?",
                OptionA = "Nucleus", OptionB = "Ribosome", OptionC = "Golgi body", OptionD = "Mitochondria",
                CorrectOption = "D", Difficulty = Difficulty.Easy, Category = "Science"
            },
            new()
            {
                Text = "What is the atomic number of Carbon?",
                OptionA = "8", OptionB = "6", OptionC = "12", OptionD = "14",
                CorrectOption = "B", Difficulty = Difficulty.Medium, Category = "Science"
            },
            new()
            {
                Text = "Approximately how fast does light travel?",
                OptionA = "150,000 km/s", OptionB = "450,000 km/s", OptionC = "300,000 km/s", OptionD = "600,000 km/s",
                CorrectOption = "C", Difficulty = Difficulty.Medium, Category = "Science"
            },
            new()
            {
                Text = "What does DNA stand for?",
                OptionA = "Deoxyribonucleic Acid", OptionB = "Dinitrogen Acid", OptionC = "Dioxin Acid", OptionD = "Diphenyl Acid",
                CorrectOption = "A", Difficulty = Difficulty.Medium, Category = "Science"
            },
            new()
            {
                Text = "Which element has the chemical symbol 'Au'?",
                OptionA = "Silver", OptionB = "Copper", OptionC = "Aluminum", OptionD = "Gold",
                CorrectOption = "D", Difficulty = Difficulty.Medium, Category = "Science"
            },
            new()
            {
                Text = "What fundamental force keeps planets in orbit around the Sun?",
                OptionA = "Magnetic force", OptionB = "Gravity", OptionC = "Nuclear force", OptionD = "Electromagnetic force",
                CorrectOption = "B", Difficulty = Difficulty.Easy, Category = "Science"
            },
            new()
            {
                Text = "What is the approximate half-life of Carbon-14?",
                OptionA = "1,000 years", OptionB = "500 years", OptionC = "10,000 years", OptionD = "5,730 years",
                CorrectOption = "D", Difficulty = Difficulty.Hard, Category = "Science"
            },
            new()
            {
                Text = "The Higgs boson is best described as:",
                OptionA = "A type of electron", OptionB = "A radioactive isotope", OptionC = "A fundamental particle giving mass", OptionD = "A type of atom",
                CorrectOption = "C", Difficulty = Difficulty.Hard, Category = "Science"
            },

            // ─── GEOGRAPHY (5 questions) ──────────────────────────────

            new()
            {
                Text = "What is the capital city of Australia?",
                OptionA = "Sydney", OptionB = "Melbourne", OptionC = "Brisbane", OptionD = "Canberra",
                CorrectOption = "D", Difficulty = Difficulty.Medium, Category = "Geography"
            },
            new()
            {
                Text = "Which is the longest river in the world?",
                OptionA = "Amazon", OptionB = "Mississippi", OptionC = "Yangtze", OptionD = "Nile",
                CorrectOption = "D", Difficulty = Difficulty.Medium, Category = "Geography"
            },
            new()
            {
                Text = "Which country has the largest population as of 2024?",
                OptionA = "China", OptionB = "USA", OptionC = "India", OptionD = "Indonesia",
                CorrectOption = "C", Difficulty = Difficulty.Easy, Category = "Geography"
            },
            new()
            {
                Text = "Which is the world's smallest country by area?",
                OptionA = "Monaco", OptionB = "Vatican City", OptionC = "Liechtenstein", OptionD = "San Marino",
                CorrectOption = "B", Difficulty = Difficulty.Medium, Category = "Geography"
            },
            new()
            {
                Text = "Mount Everest sits on the border of which two countries?",
                OptionA = "India and Tibet", OptionB = "China and Bhutan", OptionC = "Nepal and China", OptionD = "Nepal and India",
                CorrectOption = "C", Difficulty = Difficulty.Hard, Category = "Geography"
            },

            // ─── HISTORY (5 questions) ────────────────────────────────

            new()
            {
                Text = "In what year did World War II end?",
                OptionA = "1943", OptionB = "1944", OptionC = "1946", OptionD = "1945",
                CorrectOption = "D", Difficulty = Difficulty.Easy, Category = "History"
            },
            new()
            {
                Text = "Who was the first President of the United States?",
                OptionA = "Abraham Lincoln", OptionB = "Thomas Jefferson", OptionC = "George Washington", OptionD = "John Adams",
                CorrectOption = "C", Difficulty = Difficulty.Easy, Category = "History"
            },
            new()
            {
                Text = "In which year did the French Revolution begin?",
                OptionA = "1776", OptionB = "1789", OptionC = "1801", OptionD = "1756",
                CorrectOption = "B", Difficulty = Difficulty.Medium, Category = "History"
            },
            new()
            {
                Text = "The ancient Library of Alexandria was located in which country?",
                OptionA = "Greece", OptionB = "Rome", OptionC = "Turkey", OptionD = "Egypt",
                CorrectOption = "D", Difficulty = Difficulty.Medium, Category = "History"
            },
            new()
            {
                Text = "Which empire was historically the largest by land area?",
                OptionA = "Roman Empire", OptionB = "British Empire", OptionC = "Mongol Empire", OptionD = "Ottoman Empire",
                CorrectOption = "B", Difficulty = Difficulty.Hard, Category = "History"
            },

            // ─── MATHEMATICS (5 questions) ────────────────────────────

            new()
            {
                Text = "What is the square root of 144?",
                OptionA = "10", OptionB = "11", OptionC = "13", OptionD = "12",
                CorrectOption = "D", Difficulty = Difficulty.Easy, Category = "Mathematics"
            },
            new()
            {
                Text = "What is the value of Pi (π) to 2 decimal places?",
                OptionA = "2.71", OptionB = "1.61", OptionC = "3.14", OptionD = "4.13",
                CorrectOption = "C", Difficulty = Difficulty.Easy, Category = "Mathematics"
            },
            new()
            {
                Text = "What is 2 raised to the power of 10?",
                OptionA = "512", OptionB = "256", OptionC = "2048", OptionD = "1024",
                CorrectOption = "D", Difficulty = Difficulty.Medium, Category = "Mathematics"
            },
            new()
            {
                Text = "Which sequence represents Fibonacci numbers?",
                OptionA = "1, 2, 4, 8, 16", OptionB = "1, 1, 2, 3, 5, 8", OptionC = "2, 4, 6, 8, 10", OptionD = "1, 3, 5, 7, 9",
                CorrectOption = "B", Difficulty = Difficulty.Medium, Category = "Mathematics"
            },
            new()
            {
                Text = "What is the indefinite integral of x²?",
                OptionA = "2x + C", OptionB = "x³ + C", OptionC = "x²/2 + C", OptionD = "x³/3 + C",
                CorrectOption = "D", Difficulty = Difficulty.Hard, Category = "Mathematics"
            },

            // ─── TECHNOLOGY (5 questions) ─────────────────────────────

            new()
            {
                Text = "Who co-founded Apple Inc. in 1976?",
                OptionA = "Bill Gates", OptionB = "Mark Zuckerberg", OptionC = "Steve Jobs", OptionD = "Jeff Bezos",
                CorrectOption = "C", Difficulty = Difficulty.Easy, Category = "Technology"
            },
            new()
            {
                Text = "What does HTTP stand for?",
                OptionA = "High Tech Transfer Protocol", OptionB = "HyperText Transfer Protocol", OptionC = "Hybrid Text Transport Protocol", OptionD = "HyperText Transport Procedure",
                CorrectOption = "B", Difficulty = Difficulty.Medium, Category = "Technology"
            },
            new()
            {
                Text = "What does RAM stand for?",
                OptionA = "Read Access Memory", OptionB = "Rapid Access Memory", OptionC = "Random Access Memory", OptionD = "Remote Access Memory",
                CorrectOption = "C", Difficulty = Difficulty.Easy, Category = "Technology"
            },
            new()
            {
                Text = "What is the binary representation of the decimal number 10?",
                OptionA = "1001", OptionB = "0101", OptionC = "1100", OptionD = "1010",
                CorrectOption = "D", Difficulty = Difficulty.Medium, Category = "Technology"
            },
            new()
            {
                Text = "Which programming language was primarily designed for Android development before Kotlin?",
                OptionA = "Swift", OptionB = "C++", OptionC = "Java", OptionD = "Python",
                CorrectOption = "C", Difficulty = Difficulty.Medium, Category = "Technology"
            },

            // ─── BONUS QUESTIONS (to hit 30+) ─────────────────────────

            new()
            {
                Text = "Which company developed the Flutter framework?",
                OptionA = "Microsoft", OptionB = "Facebook", OptionC = "Apple", OptionD = "Google",
                CorrectOption = "D", Difficulty = Difficulty.Easy, Category = "Technology"
            },
            new()
            {
                Text = "What ocean is the largest by area?",
                OptionA = "Atlantic Ocean", OptionB = "Indian Ocean", OptionC = "Arctic Ocean", OptionD = "Pacific Ocean",
                CorrectOption = "D", Difficulty = Difficulty.Easy, Category = "Geography"
            }
        };

        await context.Questions.AddRangeAsync(questions);
        await context.SaveChangesAsync();
    }
}
