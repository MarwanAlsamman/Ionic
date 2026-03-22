import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../../core/theme/app_theme.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    // Navigate when round ends
    if (game.state == GameState.roundResult && game.lastRoundResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pushNamed('/round-result');
      });
    }

    // Navigate when game ends
    if (game.state == GameState.gameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/leaderboard');
      });
    }

    final question = game.currentQuestion;

    if (question == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 16),
              Text(
                'Game starting...',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation during game
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Bar: Round info + timer ─────────────────────────
              _TopBar(
                roundNumber: question.roundNumber,
                totalRounds: question.totalRounds,
                timerSeconds: game.timerSeconds,
                timerController: _timerController,
              ),

              // ── Question ────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          '${question.category} • ${question.difficulty}',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ).animate().fadeIn(),

                      const SizedBox(height: 24),

                      // Question text
                      Text(
                        question.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                    ],
                  ),
                ),
              ),

              // ── Answer Options ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _AnswerButton(
                          label: 'A',
                          text: question.optionA,
                          color: AppTheme.optionA,
                          onTap: () => game.submitAnswer('A'),
                          isSelected: game.selectedOption == 'A',
                          isDisabled: game.hasAnswered,
                        ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.3),
                        const SizedBox(width: 12),
                        _AnswerButton(
                          label: 'B',
                          text: question.optionB,
                          color: AppTheme.optionB,
                          onTap: () => game.submitAnswer('B'),
                          isSelected: game.selectedOption == 'B',
                          isDisabled: game.hasAnswered,
                        ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.3),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _AnswerButton(
                          label: 'C',
                          text: question.optionC,
                          color: AppTheme.optionC,
                          onTap: () => game.submitAnswer('C'),
                          isSelected: game.selectedOption == 'C',
                          isDisabled: game.hasAnswered,
                        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3),
                        const SizedBox(width: 12),
                        _AnswerButton(
                          label: 'D',
                          text: question.optionD,
                          color: AppTheme.optionD,
                          onTap: () => game.submitAnswer('D'),
                          isSelected: game.selectedOption == 'D',
                          isDisabled: game.hasAnswered,
                        ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.3),
                      ],
                    ),
                  ],
                ),
              ),

              // Answered indicator
              if (game.hasAnswered)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.success.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppTheme.success, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Answer submitted! Waiting for others...',
                        style: TextStyle(
                            color: AppTheme.success, fontSize: 13),
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top Bar with Timer ────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int roundNumber;
  final int totalRounds;
  final int timerSeconds;
  final AnimationController timerController;

  const _TopBar({
    required this.roundNumber,
    required this.totalRounds,
    required this.timerSeconds,
    required this.timerController,
  });

  Color get _timerColor {
    if (timerSeconds > 6) return AppTheme.success;
    if (timerSeconds > 3) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          // Round counter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$roundNumber / $totalRounds',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Circular Timer
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 6,
                    color: AppTheme.backgroundCard,
                  ),
                ),
                // Timer progress
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: timerSeconds / 10.0,
                    strokeWidth: 6,
                    color: _timerColor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Time number
                Text(
                  '$timerSeconds',
                  style: TextStyle(
                    color: _timerColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          // Progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Progress',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: roundNumber / totalRounds,
                    backgroundColor: AppTheme.backgroundCard,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Answer Button ─────────────────────────────────────────────────────────────

class _AnswerButton extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isDisabled;

  const _AnswerButton({
    required this.label,
    required this.text,
    required this.color,
    required this.onTap,
    required this.isSelected,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isSelected ? color : color.withOpacity(0.7);

    return Expanded(
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 120,
          decoration: BoxDecoration(
            color: isSelected ? effectiveColor : AppTheme.backgroundCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.4),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Option label (A/B/C/D)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.3)
                        : color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
