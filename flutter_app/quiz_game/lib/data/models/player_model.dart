class PlayerModel {
  final String id;
  final String userId;
  final String username;
  final int score;
  final bool isReady;

  const PlayerModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.score,
    required this.isReady,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) => PlayerModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        username: json['username'] as String? ?? 'Unknown',
        score: json['score'] as int? ?? 0,
        isReady: json['isReady'] as bool? ?? false,
      );

  PlayerModel copyWith({
    String? id,
    String? userId,
    String? username,
    int? score,
    bool? isReady,
  }) =>
      PlayerModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        username: username ?? this.username,
        score: score ?? this.score,
        isReady: isReady ?? this.isReady,
      );
}
