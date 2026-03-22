import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../core/constants/app_constants.dart';

/// Manages the SignalR connection to the .NET GameHub.
///
/// Usage pattern:
///   1. Call [connect()] once when entering the game
///   2. Register event listeners with [on()]
///   3. Invoke hub methods with [invoke()]
///   4. Call [disconnect()] when leaving
///
/// All server→client events are routed via [GameProvider] which
/// listens here and updates the UI state.
class SignalRService {
  SignalRService._();
  static final SignalRService instance = SignalRService._();

  HubConnection? _connection;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // ── Connect / Disconnect ─────────────────────────────────────────────────

  Future<void> connect() async {
    if (_isConnected) return;

    _connection = HubConnectionBuilder()
        .withUrl(AppConstants.hubUrl)
        .withAutomaticReconnect()
        .build();

    _connection!.onclose(({Exception? error}) {
      _isConnected = false;
      debugPrint('[SignalR] Disconnected: ${error?.toString() ?? "clean"}');
    });

    _connection!.onreconnecting(({Exception? error}) {
      debugPrint('[SignalR] Reconnecting...');
    });

    _connection!.onreconnected(({String? connectionId}) {
      debugPrint('[SignalR] Reconnected. ConnectionId: $connectionId');
    });

    try {
      await _connection!.start();
      _isConnected = true;
      debugPrint('[SignalR] Connected. ConnectionId: ${_connection!.connectionId}');
    } catch (e) {
      _isConnected = false;
      debugPrint('[SignalR] Connection failed: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.stop();
      _isConnected = false;
      debugPrint('[SignalR] Disconnected manually.');
    }
  }

  // ── Event Registration ────────────────────────────────────────────────────

  /// Register a listener for a server→client event.
  /// [methodName] must match exactly what the server calls.
  void on(String methodName, Function(List<Object?>? args) handler) {
    _connection?.on(methodName, handler);
  }

  /// Remove a listener for a server→client event.
  void off(String methodName) {
    _connection?.off(methodName);
  }

  // ── Hub Method Invocations (Client → Server) ─────────────────────────────

  /// Join a game room. Server adds the connection to the SignalR group.
  Future<void> joinRoom(String roomCode, String userId) async {
    await _invoke('JoinRoom', [roomCode, userId]);
  }

  /// Mark self as ready to play.
  Future<void> playerReady(String roomCode) async {
    await _invoke('PlayerReady', [roomCode]);
  }

  /// Host starts the game.
  Future<void> startGame(String roomCode) async {
    await _invoke('StartGame', [roomCode]);
  }

  /// Submit an answer for the current question.
  /// [answerTimeMs] is milliseconds since the question was displayed.
  Future<void> submitAnswer({
    required String questionId,
    required String selectedOption,
    required int answerTimeMs,
  }) async {
    await _invoke('SubmitAnswer', [questionId, selectedOption, answerTimeMs]);
  }

  /// Explicitly leave the room.
  Future<void> leaveRoom() async {
    await _invoke('LeaveRoom', []);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _invoke(String method, List<Object?> args) async {
    if (_connection == null || !_isConnected) {
      debugPrint('[SignalR] Cannot invoke "$method" — not connected.');
      return;
    }
    try {
      await _connection!.invoke(method, args: args);
    } catch (e) {
      debugPrint('[SignalR] Error invoking "$method": $e');
      rethrow;
    }
  }
}
