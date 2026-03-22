import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/game_provider.dart';
import '../../core/theme/app_theme.dart';

class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for game state changes and navigate accordingly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForGameStart();
    });
  }

  void _listenForGameStart() {
    final game = context.read<GameProvider>();
    if (game.state == GameState.starting || game.state == GameState.question) {
      Navigator.of(context).pushReplacementNamed('/game');
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Room code copied!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final user = context.watch<UserProvider>().currentUser;
    final room = game.currentRoom;

    // Navigate when game starts
    if (game.state == GameState.starting || game.state == GameState.question) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/game');
      });
    }

    return WillPopScope(
      onWillPop: () async {
        await game.leaveRoom();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: const Text('Waiting Room'),
          leading: IconButton(
            icon: const Icon(Icons.exit_to_app_rounded),
            onPressed: () async {
              await game.leaveRoom();
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ),
        body: room == null
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),

                      // Room Code card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'ROOM CODE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _copyCode(room.roomCode),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    room.roomCode,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.copy_rounded,
                                      color: Colors.white70, size: 20),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to copy • Share with friends',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),

                      const SizedBox(height: 28),

                      // Player count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Players',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundCard,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${room.players.length}/${room.maxPlayers}',
                              style: const TextStyle(
                                color: AppTheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ).animate(delay: 200.ms).fadeIn(),

                      const SizedBox(height: 16),

                      // Players list
                      Expanded(
                        child: ListView.builder(
                          itemCount: room.players.length,
                          itemBuilder: (ctx, i) {
                            final player = room.players[i];
                            final isHost =
                                player.userId == room.hostUserId;
                            final isMe = player.userId == user?.id;

                            return _PlayerTile(
                              username: player.username,
                              isHost: isHost,
                              isReady: player.isReady,
                              isMe: isMe,
                            )
                                .animate(delay: (i * 80).ms)
                                .fadeIn()
                                .slideX(begin: 0.2);
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Questions count info
                      Center(
                        child: Text(
                          '${room.totalQuestions} questions • 10 seconds each',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Start Game button (host only) or Waiting indicator
                      if (game.isHost) ...[
                        ElevatedButton.icon(
                          onPressed: room.players.length < 1
                              ? null
                              : () => game.startGame(),
                          icon: const Icon(Icons.play_arrow_rounded, size: 28),
                          label: const Text(
                            'Start Game',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ).animate(delay: 400.ms).fadeIn().scale(),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundCard,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppTheme.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Waiting for host to start...',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ).animate(delay: 400.ms).fadeIn(),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final String username;
  final bool isHost;
  final bool isReady;
  final bool isMe;

  const _PlayerTile({
    required this.username,
    required this.isHost,
    required this.isReady,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.primary.withOpacity(0.15)
            : AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: isMe
            ? Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: isHost
                ? AppTheme.warning.withOpacity(0.2)
                : AppTheme.primary.withOpacity(0.2),
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: TextStyle(
                color: isHost ? AppTheme.warning : AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Badges
          Row(
            children: [
              if (isHost)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          color: AppTheme.warning, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Host',
                        style: TextStyle(
                            color: AppTheme.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
