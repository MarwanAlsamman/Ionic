import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/game_room_model.dart';
import '../models/player_model.dart';
import '../../core/constants/app_constants.dart';

/// REST API client — handles all HTTP communication with the .NET backend.
/// Real-time game events go through [SignalRService] instead.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final _client = http.Client();

  // ── Headers ────────────────────────────────────────────────────────────
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ── Users ──────────────────────────────────────────────────────────────

  /// Create a new user or retrieve existing one by username.
  Future<UserModel> createUser(String username) async {
    final response = await _client.post(
      Uri.parse(AppConstants.createUserEndpoint),
      headers: _headers,
      body: jsonEncode({'username': username}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return UserModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw ApiException('Failed to create user: ${response.body}', response.statusCode);
  }

  // ── Game Rooms ─────────────────────────────────────────────────────────

  /// Create a new game room. Returns the room with its 6-char code.
  Future<GameRoomModel> createRoom({
    required String hostUserId,
    int maxPlayers = 8,
    int totalQuestions = 10,
  }) async {
    final response = await _client.post(
      Uri.parse(AppConstants.createRoomEndpoint),
      headers: _headers,
      body: jsonEncode({
        'hostUserId': hostUserId,
        'maxPlayers': maxPlayers,
        'totalQuestions': totalQuestions,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return GameRoomModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw ApiException('Failed to create room: ${response.body}', response.statusCode);
  }

  /// Validate room code and get room info before connecting via SignalR.
  Future<GameRoomModel> getRoomByCode(String code) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.getRoomEndpoint}/${code.toUpperCase()}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return GameRoomModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    if (response.statusCode == 404) {
      throw ApiException('Room "$code" not found.', 404);
    }
    throw ApiException('Failed to get room: ${response.body}', response.statusCode);
  }

  /// Pre-join a room via REST (creates player record).
  /// SignalR JoinRoom will then attach the ConnectionId.
  Future<Map<String, dynamic>> joinRoom({
    required String roomCode,
    required String userId,
  }) async {
    final response = await _client.post(
      Uri.parse(AppConstants.joinRoomEndpoint),
      headers: _headers,
      body: jsonEncode({
        'roomCode': roomCode.toUpperCase(),
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Failed to join room: ${response.body}', response.statusCode);
  }
}

/// Typed API error with HTTP status code
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
