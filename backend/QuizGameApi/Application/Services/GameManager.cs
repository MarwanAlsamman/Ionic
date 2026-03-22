using System.Collections.Concurrent;
using AutoMapper;
using Microsoft.AspNetCore.SignalR;
using QuizGame.Application.DTOs;
using QuizGame.Application.Interfaces;
using QuizGame.Domain.Entities;
using QuizGame.Domain.Enums;
using QuizGame.Domain.Interfaces;
using QuizGame.Presentation.Hubs;

namespace QuizGame.Application.Services;

/// <summary>
/// Core game engine — singleton service that manages all active game loops.
///
/// DESIGN:
/// - Each game room gets its own Task-based loop (RunGameLoopAsync)
/// - CancellationTokenSource per room allows stopping mid-game
/// - Answers collected in a thread-safe ConcurrentDictionary during each round
/// - Scoring: +10 for correct, +0–5 speed bonus based on response time
/// </summary>
public class GameManager : IGameManager
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<GameManager> _logger;

    // roomId → CancellationTokenSource (for stopping games)
    private readonly ConcurrentDictionary<Guid, CancellationTokenSource> _activeGames = new();

    // roomId → (playerId → PlayerAnswer) for the current round
    private readonly ConcurrentDictionary<Guid, ConcurrentDictionary<Guid, PlayerAnswer>> _roundAnswers = new();

    // roomId → current GameRound (so Hub can look up round context for submitted answers)
    private readonly ConcurrentDictionary<Guid, GameRound> _currentRounds = new();

    // SignalR hub context (injected via IHubContext<GameHub>)
    private readonly IHubContext<GameHub> _gameHubContext;

    public GameManager(
        IHubContext<GameHub> gameHubContext,
        IServiceScopeFactory scopeFactory,
        ILogger<GameManager> logger)
    {
        _gameHubContext = gameHubContext;
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    public bool IsGameActive(Guid roomId) => _activeGames.ContainsKey(roomId);

    public async Task StartGameAsync(Guid roomId)
    {
        if (_activeGames.ContainsKey(roomId))
        {
            _logger.LogWarning("Game for room {RoomId} is already active.", roomId);
            return;
        }

        var cts = new CancellationTokenSource();
        _activeGames[roomId] = cts;

        // Fire-and-forget — the loop manages itself
        _ = Task.Run(() => RunGameLoopAsync(roomId, cts.Token), cts.Token);
        _logger.LogInformation("Game started for room {RoomId}.", roomId);
    }

    public async Task StopGameAsync(Guid roomId)
    {
        if (_activeGames.TryRemove(roomId, out var cts))
        {
            cts.Cancel();
            cts.Dispose();
        }
        _roundAnswers.TryRemove(roomId, out _);
        _currentRounds.TryRemove(roomId, out _);
        _logger.LogInformation("Game stopped for room {RoomId}.", roomId);
    }

    public async Task SubmitAnswerAsync(Guid roomId, Guid playerId, Guid questionId,
        string selectedOption, long answerTimeMs)
    {
        // Validate round is active and question matches
        if (!_currentRounds.TryGetValue(roomId, out var currentRound))
            return;

        if (currentRound.QuestionId != questionId)
            return; // Answer for a different (stale) question — ignore

        var answers = _roundAnswers.GetOrAdd(roomId, _ => new ConcurrentDictionary<Guid, PlayerAnswer>());

        // Only accept the FIRST answer from each player per round
        answers.TryAdd(playerId, new PlayerAnswer
        {
            PlayerId = playerId,
            QuestionId = questionId,
            GameRoundId = currentRound.Id,
            SelectedOption = selectedOption.ToUpper(),
            AnswerTimeMs = answerTimeMs
        });
    }

    // ─── Private: Game Loop ──────────────────────────────────────────────

    private async Task RunGameLoopAsync(Guid roomId, CancellationToken ct)
    {
        try
        {
            using var scope = _scopeFactory.CreateScope();
            var roomRepo = scope.ServiceProvider.GetRequiredService<IRepository<GameRoom>>();
            var playerRepo = scope.ServiceProvider.GetRequiredService<IRepository<Player>>();
            var questionRepo = scope.ServiceProvider.GetRequiredService<IRepository<Question>>();
            var userRepo = scope.ServiceProvider.GetRequiredService<IRepository<User>>();
            var mapper = scope.ServiceProvider.GetRequiredService<IMapper>();

            // ── Load room ─────────────────────────────────────────────
            var room = await roomRepo.GetByIdAsync(roomId);
            if (room == null) { _logger.LogError("Room {Id} not found at game start.", roomId); return; }

            // Mark room as InProgress
            room.Status = GameStatus.InProgress;
            await roomRepo.UpdateAsync(room);

            // ── Load players ──────────────────────────────────────────
            var players = (await playerRepo.FindAsync(p => p.GameRoomId == roomId)).ToList();
            foreach (var p in players)
                p.User = await userRepo.GetByIdAsync(p.UserId);

            // ── Select & shuffle questions ────────────────────────────
            var allQuestions = (await questionRepo.GetAllAsync()).ToList();
            var questions = allQuestions
                .OrderBy(_ => Guid.NewGuid())
                .Take(room.TotalQuestions)
                .ToList();

            int totalRounds = questions.Count;

            // Broadcast: game has started
            await _gameHubContext.Clients.Group(roomId.ToString())
                .SendAsync("GameStarted", new { TotalRounds = totalRounds }, ct);

            await Task.Delay(1000, ct); // brief pause before first question

            // ── Round loop ────────────────────────────────────────────
            for (int roundNum = 1; roundNum <= totalRounds; roundNum++)
            {
                if (ct.IsCancellationRequested) break;

                var question = questions[roundNum - 1];

                // Create a GameRound record
                var round = new GameRound
                {
                    GameRoomId = roomId,
                    QuestionId = question.Id,
                    RoundNumber = roundNum,
                    StartTime = DateTime.UtcNow
                };
                _currentRounds[roomId] = round;

                // Initialize answer bucket for this round
                _roundAnswers[roomId] = new ConcurrentDictionary<Guid, PlayerAnswer>();

                // Send question (NO correct answer revealed yet)
                var questionDto = mapper.Map<QuestionDto>(question);
                questionDto = questionDto with
                {
                    RoundNumber = roundNum,
                    TotalRounds = totalRounds
                };

                await _gameHubContext.Clients.Group(roomId.ToString())
                    .SendAsync("QuestionReceived", questionDto, ct);

                // ── Countdown timer (10 seconds) ──────────────────────
                const int roundSeconds = 10;
                for (int t = roundSeconds; t >= 0; t--)
                {
                    if (ct.IsCancellationRequested) break;
                    await _gameHubContext.Clients.Group(roomId.ToString())
                        .SendAsync("TimerTick", t, ct);
                    await Task.Delay(1000, ct);
                }

                round.EndTime = DateTime.UtcNow;

                // ── Calculate scores ──────────────────────────────────
                if (_roundAnswers.TryGetValue(roomId, out var answers))
                {
                    foreach (var (playerId, answer) in answers)
                    {
                        answer.IsCorrect = answer.SelectedOption == question.CorrectOption;
                        if (answer.IsCorrect)
                        {
                            // Base score = 10; speed bonus up to 5 (faster = more)
                            int speedBonus = CalculateSpeedBonus(answer.AnswerTimeMs, roundSeconds * 1000);
                            answer.ScoreEarned = 10 + speedBonus;
                        }

                        // Update player score in memory
                        var player = players.FirstOrDefault(p => p.Id == playerId);
                        if (player != null)
                        {
                            player.Score += answer.ScoreEarned;
                            await playerRepo.UpdateAsync(player);
                        }
                    }
                }

                // ── Build leaderboard ─────────────────────────────────
                var leaderboard = BuildLeaderboard(players, answers);

                // Reveal correct answer + scores
                var reveal = mapper.Map<QuestionRevealDto>(question);
                var roundResult = new RoundResultDto(roundNum, reveal, leaderboard);

                await _gameHubContext.Clients.Group(roomId.ToString())
                    .SendAsync("RoundEnded", roundResult, ct);

                // Pause between rounds (show results for 4 seconds)
                if (roundNum < totalRounds)
                    await Task.Delay(4000, ct);
            }

            // ── Game over ─────────────────────────────────────────────
            var finalLeaderboard = BuildLeaderboard(players, null);
            var gameEndedDto = new GameEndedDto(finalLeaderboard);

            await _gameHubContext.Clients.Group(roomId.ToString())
                .SendAsync("GameEnded", gameEndedDto, ct);

            // Mark room as finished
            room.Status = GameStatus.Finished;
            await roomRepo.UpdateAsync(room);

            _logger.LogInformation("Game finished for room {RoomId}. Winner: {Winner}",
                roomId, finalLeaderboard.FirstOrDefault()?.Username ?? "None");
        }
        catch (OperationCanceledException)
        {
            _logger.LogInformation("Game loop cancelled for room {RoomId}.", roomId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled error in game loop for room {RoomId}.", roomId);
        }
        finally
        {
            _activeGames.TryRemove(roomId, out _);
            _roundAnswers.TryRemove(roomId, out _);
            _currentRounds.TryRemove(roomId, out _);
        }
    }

    // ─── Private: Scoring Helpers ────────────────────────────────────────

    /// <summary>
    /// Speed bonus: 0–5 points.
    /// Full bonus if answered in under 2s, zero bonus at 10s.
    /// </summary>
    private static int CalculateSpeedBonus(long answerTimeMs, int totalTimeMs)
    {
        if (answerTimeMs <= 0) return 5;
        double ratio = 1.0 - Math.Min((double)answerTimeMs / totalTimeMs, 1.0);
        return (int)Math.Round(ratio * 5);
    }

    /// <summary>Build a sorted leaderboard from current player scores</summary>
    private static List<LeaderboardEntryDto> BuildLeaderboard(
        List<Player> players,
        ConcurrentDictionary<Guid, PlayerAnswer>? roundAnswers)
    {
        return players
            .OrderByDescending(p => p.Score)
            .Select((p, idx) =>
            {
                int roundScore = 0;
                if (roundAnswers != null && roundAnswers.TryGetValue(p.Id, out var ans))
                    roundScore = ans.ScoreEarned;

                return new LeaderboardEntryDto(
                    Rank: idx + 1,
                    PlayerId: p.Id,
                    Username: p.User?.Username ?? "Unknown",
                    Score: p.Score,
                    ScoreThisRound: roundScore);
            })
            .ToList();
    }
}
