import 'player_model.dart';
import 'question_model.dart';

class LeaderboardEntry {
  final int rank;
  final String playerId;
  final String username;
  final int score;
  final int scoreThisRound;

  const LeaderboardEntry({
    required this.rank,
    required this.playerId,
    required this.username,
    required this.score,
    required this.scoreThisRound,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        rank: json['rank'] as int? ?? 0,
        playerId: json['playerId'] as String? ?? '',
        username: json['username'] as String? ?? 'Unknown',
        score: json['score'] as int? ?? 0,
        scoreThisRound: json['scoreThisRound'] as int? ?? 0,
      );
}

class RoundResultModel {
  final int roundNumber;
  final QuestionRevealModel question;
  final List<LeaderboardEntry> leaderboard;

  const RoundResultModel({
    required this.roundNumber,
    required this.question,
    required this.leaderboard,
  });

  factory RoundResultModel.fromJson(Map<String, dynamic> json) =>
      RoundResultModel(
        roundNumber: json['roundNumber'] as int? ?? 0,
        question: QuestionRevealModel.fromJson(
            json['question'] as Map<String, dynamic>),
        leaderboard: (json['leaderboard'] as List<dynamic>?)
                ?.map((e) =>
                    LeaderboardEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class GameEndedModel {
  final List<LeaderboardEntry> finalLeaderboard;

  const GameEndedModel({required this.finalLeaderboard});

  factory GameEndedModel.fromJson(Map<String, dynamic> json) => GameEndedModel(
        finalLeaderboard: (json['finalLeaderboard'] as List<dynamic>?)
                ?.map((e) =>
                    LeaderboardEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
