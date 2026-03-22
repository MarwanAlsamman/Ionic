import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/providers/user_provider.dart';
import 'features/providers/game_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/game_room/waiting_room_screen.dart';
import 'features/game/game_screen.dart';
import 'features/game/round_result_screen.dart';
import 'features/game/leaderboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for the quiz game
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Dark status bar icons on transparent background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const QuizBattleApp());
}

class QuizBattleApp extends StatelessWidget {
  const QuizBattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // User auth state
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Game state — driven by SignalR events
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: MaterialApp(
        title: 'QuizBattle',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        // ── Named Routes ─────────────────────────────────────────────
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
          '/waiting-room': (_) => const WaitingRoomScreen(),
          '/game': (_) => const GameScreen(),
          '/round-result': (_) => const RoundResultScreen(),
          '/leaderboard': (_) => const LeaderboardScreen(),
        },
      ),
    );
  }
}
