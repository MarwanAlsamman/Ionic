import 'player_model.dart';

class GameRoomModel {
  final String id;
  final String roomCode;
  final String hostUserId;
  final String status;
  final int maxPlayers;
  final int totalQuestions;
  final List<PlayerModel> players;
  final DateTime createdAt;

  const GameRoomModel({
    required this.id,
    required this.roomCode,
    required this.hostUserId,
    required this.status,
    required this.maxPlayers,
    required this.totalQuestions,
    required this.players,
    required this.createdAt,
  });

  factory GameRoomModel.fromJson(Map<String, dynamic> json) => GameRoomModel(
        id: json['id'] as String,
        roomCode: json['roomCode'] as String,
        hostUserId: json['hostUserId'] as String,
        status: json['status'] as String? ?? 'Waiting',
        maxPlayers: json['maxPlayers'] as int? ?? 8,
        totalQuestions: json['totalQuestions'] as int? ?? 10,
        players: (json['players'] as List<dynamic>?)
                ?.map((p) => PlayerModel.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  GameRoomModel copyWith({
    String? id,
    String? roomCode,
    String? hostUserId,
    String? status,
    int? maxPlayers,
    int? totalQuestions,
    List<PlayerModel>? players,
    DateTime? createdAt,
  }) =>
      GameRoomModel(
        id: id ?? this.id,
        roomCode: roomCode ?? this.roomCode,
        hostUserId: hostUserId ?? this.hostUserId,
        status: status ?? this.status,
        maxPlayers: maxPlayers ?? this.maxPlayers,
        totalQuestions: totalQuestions ?? this.totalQuestions,
        players: players ?? this.players,
        createdAt: createdAt ?? this.createdAt,
      );
}
