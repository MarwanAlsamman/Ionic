import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/leaderboard_model.dart';

class RoundResultScreen extends StatefulWidget {
  const RoundResultScreen({super.key});

  @override
  State<RoundResultScreen> createState() => _RoundResultScreenState();
}

class _RoundResultScreenState extends State<RoundResultScreen> {
  @override
  void initState() {
    super.initState();
    _autoNavigate();
  }

  /// Poll until the next question arrives or game ends, then navigate.
  void _autoNavigate() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return false;
      final state = context.read<GameProvider>().state;
      if (state == GameState.question) {
        if (mounted) Navigator.of(context).pop(); // back to game screen
        return false;
      }
      if (state == GameState.gameOver) {
        if (mounted) {
          Navigator.of(context)
              .pushReplacementNamed('/leaderboard');
        }
        return false;
      }
      return state == GameState.roundResult; // keep polling
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final result = game.lastRoundResult;

    if (result == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    final correctOption = result.question.correctOption;
    final correctText = result.question.getOptionText(correctOption);
    final myEntry = result.leaderboard
        .where((e) => e.playerId == game.currentPlayer?.id)
        .firstOrNull;
    final wasCorrect = game.selectedOption?.toUpperCase() ==
        correctOption.toUpperCase();

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Round label
                Center(
                  child: Text(
                    'Round ${result.roundNumber} Complete',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 24),

                // Result banner
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: wasCorrect
                        ? AppTheme.success.withOpacity(0.15)
                        : AppTheme.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: wasCorrect
                          ? AppTheme.success.withOpacity(0.4)
                          : AppTheme.error.withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        wasCorrect
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: wasCorrect ? AppTheme.success : AppTheme.error,
                        size: 52,
                      ).animate().scale(
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(height: 12),
                      Text(
                        wasCorrect ? 'Correct! 🎉' : 'Wrong Answer 😢',
                        style: TextStyle(
                          color: wasCorrect ? AppTheme.success : AppTheme.error,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (myEntry != null && myEntry.scoreThisRound > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          '+${myEntry.scoreThisRound} points',
                          style: const TextStyle(
                            color: AppTheme.warning,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.3),
                      ],
                    ],
                  ),
                ).animate(delay: 100.ms).fadeIn(),

                const SizedBox(height: 20),

                // Correct answer reveal
                _CorrectAnswerCard(
                  correctOption: correctOption,
                  correctText: correctText,
                ),

                const SizedBox(height: 24),

                // Leaderboard
                Text(
                  'Current Rankings',
                  style: Theme.of(context).textTheme.titleLarge,
                ).animate(delay: 400.ms).fadeIn(),

                const SizedBox(height: 12),

                Expanded(
                  child: ListView.builder(
                    itemCount: result.leaderboard.length,
                    itemBuilder: (ctx, i) {
                      final entry = result.leaderboard[i];
                      final isMe =
                          entry.playerId == game.currentPlayer?.id;
                      return _LeaderboardTile(entry: entry, isMe: isMe)
                          .animate(delay: (500 + i * 80).ms)
                          .fadeIn()
                          .slideX(begin: 0.2);
                    },
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: Text(
                    'Next question starting soon...',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                ).animate(delay: 600.ms).fadeIn(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Correct Answer Card ───────────────────────────────────────────────────────

class _CorrectAnswerCard extends StatelessWidget {
  final String correctOption;
  final String correctText;

  const _CorrectAnswerCard({
    required this.correctOption,
    required this.correctText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              correctOption,
              style: const TextStyle(
                color: AppTheme.success,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Correct Answer',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  correctText,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.success, size: 22),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn();
  }
}

// ── Leaderboard Tile ──────────────────────────────────────────────────────────

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;

  const _LeaderboardTile({required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (entry.rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => AppTheme.textSecondary,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.primary.withOpacity(0.1)
            : AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: isMe
            ? Border.all(color: AppTheme.primary.withOpacity(0.4))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.username + (isMe ? ' (You)' : ''),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (entry.scoreThisRound > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${entry.scoreThisRound}',
                style: const TextStyle(
                  color: AppTheme.success,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            '${entry.score} pts',
            style: TextStyle(
              color: rankColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
