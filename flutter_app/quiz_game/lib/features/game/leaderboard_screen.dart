import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/leaderboard_model.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final user = context.watch<UserProvider>().currentUser;
    final result = game.gameResult;

    if (result == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final leaderboard = result.finalLeaderboard;
    final winner = leaderboard.isNotEmpty ? leaderboard.first : null;
    final myEntry = leaderboard
        .where((e) => e.playerId == game.currentPlayer?.id)
        .firstOrNull;
    final isWinner = myEntry?.rank == 1;

    return WillPopScope(
      onWillPop: () async {
        await _playAgain(context, game);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Trophy / Game Over header
                Column(
                  children: [
                    // Winner trophy animation
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    )
                        .animate()
                        .scale(
                          duration: 700.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(),

                    const SizedBox(height: 16),

                    Text(
                      isWinner ? '🎉 You Won!' : 'Game Over!',
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                      textAlign: TextAlign.center,
                    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3),

                    if (winner != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        isWinner
                            ? 'Congratulations!'
                            : '${winner.username} wins with ${winner.score} pts',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ).animate(delay: 350.ms).fadeIn(),
                    ],

                    if (myEntry != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Your rank: #${myEntry.rank} • ${myEntry.score} points',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ).animate(delay: 450.ms).fadeIn(),
                    ],
                  ],
                ),

                const SizedBox(height: 28),

                // Leaderboard title
                Text(
                  'Final Leaderboard',
                  style: Theme.of(context).textTheme.titleLarge,
                ).animate(delay: 500.ms).fadeIn(),

                const SizedBox(height: 12),

                // Top 3 podium (if enough players)
                if (leaderboard.length >= 3)
                  _Podium(leaderboard: leaderboard)
                      .animate(delay: 600.ms)
                      .fadeIn(),

                const SizedBox(height: 16),

                // Full list
                Expanded(
                  child: ListView.builder(
                    itemCount: leaderboard.length,
                    itemBuilder: (ctx, i) {
                      final entry = leaderboard[i];
                      final isMe = entry.playerId == game.currentPlayer?.id;
                      return _FinalLeaderboardTile(
                        entry: entry,
                        isMe: isMe,
                      )
                          .animate(delay: (700 + i * 80).ms)
                          .fadeIn()
                          .slideX(begin: i.isEven ? -0.2 : 0.2);
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Play Again button
                ElevatedButton.icon(
                  onPressed: () => _playAgain(context, game),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text(
                    'Play Again',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ).animate(delay: 900.ms).fadeIn().scale(),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () async {
                    await game.leaveRoom();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home', (route) => false);
                    }
                  },
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ).animate(delay: 1000.ms).fadeIn(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _playAgain(BuildContext context, GameProvider game) async {
    await game.leaveRoom();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }
}

// ── Podium Widget ─────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> leaderboard;

  const _Podium({required this.leaderboard});

  @override
  Widget build(BuildContext context) {
    final first = leaderboard[0];
    final second = leaderboard[1];
    final third = leaderboard.length > 2 ? leaderboard[2] : null;

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2nd place
          _PodiumColumn(
            entry: second,
            height: 80,
            color: const Color(0xFFC0C0C0),
            medal: '🥈',
          ),
          const SizedBox(width: 8),
          // 1st place
          _PodiumColumn(
            entry: first,
            height: 110,
            color: const Color(0xFFFFD700),
            medal: '🥇',
          ),
          const SizedBox(width: 8),
          // 3rd place
          if (third != null)
            _PodiumColumn(
              entry: third,
              height: 60,
              color: const Color(0xFFCD7F32),
              medal: '🥉',
            ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final Color color;
  final String medal;

  const _PodiumColumn({
    required this.entry,
    required this.height,
    required this.color,
    required this.medal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(medal, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          entry.username.length > 8
              ? '${entry.username.substring(0, 6)}...'
              : entry.username,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          alignment: Alignment.center,
          child: Text(
            '${entry.score}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Final Leaderboard Tile ────────────────────────────────────────────────────

class _FinalLeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;

  const _FinalLeaderboardTile({required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final rankEmoji = switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#${entry.rank}',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.primary.withOpacity(0.1) : AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: isMe
            ? Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Rank emoji or number
          SizedBox(
            width: 40,
            child: Text(
              rankEmoji,
              style: TextStyle(
                fontSize: entry.rank <= 3 ? 22 : 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primary.withOpacity(0.2),
            child: Text(
              entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
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
                fontSize: 15,
              ),
            ),
          ),
          Text(
            '${entry.score} pts',
            style: TextStyle(
              color: entry.rank == 1
                  ? const Color(0xFFFFD700)
                  : AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
