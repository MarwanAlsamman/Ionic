import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../data/models/game_room_model.dart';
import '../../data/models/player_model.dart';
import '../../data/models/question_model.dart';
import '../../data/models/leaderboard_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/signalr_service.dart';

/// All possible states the game screen can be in
enum GameState {
  idle,          // Nothing happening
  joiningRoom,   // API call in progress
  waitingRoom,   // In lobby, waiting for host to start
  starting,      // "Game Started" broadcast received
  question,      // Question being displayed, timer running
  roundResult,   // Round ended, showing results
  gameOver,      // Final leaderboard
}

/// Central game state — driven by SignalR events.
/// All screens listen to this provider and rebuild when state changes.
class GameProvider extends ChangeNotifier {
  GameState _state = GameState.idle;
  GameRoomModel? _currentRoom;
  PlayerModel? _currentPlayer;
  QuestionModel? _currentQuestion;
  RoundResultModel? _lastRoundResult;
  GameEndedModel? _gameResult;
  int _timerSeconds = 10;
  String? _selectedOption;
  bool _hasAnswered = false;
  String? _error;
  DateTime? _questionReceivedAt;
  int _totalRounds = 10;

  // ── Getters ──────────────────────────────────────────────────────────────
  GameState get state => _state;
  GameRoomModel? get currentRoom => _currentRoom;
  PlayerModel? get currentPlayer => _currentPlayer;
  QuestionModel? get currentQuestion => _currentQuestion;
  RoundResultModel? get lastRoundResult => _lastRoundResult;
  GameEndedModel? get gameResult => _gameResult;
  int get timerSeconds => _timerSeconds;
  String? get selectedOption => _selectedOption;
  bool get hasAnswered => _hasAnswered;
  String? get error => _error;
  int get totalRounds => _totalRounds;
  bool get isHost => _currentRoom?.hostUserId == _currentPlayer?.userId;

  // ── Room Actions ─────────────────────────────────────────────────────────

  /// Create a new room and immediately connect via SignalR.
  Future<void> createRoom({
    required String userId,
    int maxPlayers = 8,
    int totalQuestions = 10,
  }) async {
    _setLoading();
    try {
      final room = await ApiService.instance.createRoom(
        hostUserId: userId,
        maxPlayers: maxPlayers,
        totalQuestions: totalQuestions,
      );
      _currentRoom = room;

      // The host is always the first player in the room
      final hostPlayer = room.players
          .where((p) => p.userId == userId)
          .firstOrNull;
      if (hostPlayer != null) _currentPlayer = hostPlayer;

      await _connectAndJoin(room.roomCode, userId);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Validate room code via REST, then join via SignalR.
  Future<void> joinRoom(String roomCode, String userId) async {
    _setLoading();
    try {
      // Pre-join via REST to create player record
      final result = await ApiService.instance.joinRoom(
        roomCode: roomCode,
        userId: userId,
      );

      _currentRoom = GameRoomModel.fromJson(
          result['room'] as Map<String, dynamic>);

      // Store our own player info
      if (result['player'] != null) {
        _currentPlayer = PlayerModel.fromJson(
            result['player'] as Map<String, dynamic>);
      }

      await _connectAndJoin(roomCode, userId);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> _connectAndJoin(String roomCode, String userId) async {
    try {
      await SignalRService.instance.connect();
      _registerSignalREvents();
      await SignalRService.instance.joinRoom(roomCode, userId);
    } catch (e) {
      _setError('Failed to connect: $e');
    }
  }

  /// Mark self as ready (shown in waiting room)
  Future<void> setReady() async {
    if (_currentRoom == null) return;
    try {
      await SignalRService.instance.playerReady(_currentRoom!.roomCode);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Host starts the game
  Future<void> startGame() async {
    if (_currentRoom == null) return;
    try {
      await SignalRService.instance.startGame(_currentRoom!.roomCode);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Submit an answer to the current question
  Future<void> submitAnswer(String option) async {
    if (_hasAnswered || _currentQuestion == null) return;

    _selectedOption = option;
    _hasAnswered = true;
    notifyListeners();

    final answerTimeMs = _questionReceivedAt != null
        ? DateTime.now().difference(_questionReceivedAt!).inMilliseconds
        : 5000;

    try {
      await SignalRService.instance.submitAnswer(
        questionId: _currentQuestion!.id,
        selectedOption: option,
        answerTimeMs: answerTimeMs,
      );
    } catch (e) {
      debugPrint('Error submitting answer: $e');
    }
  }

  /// Leave room and disconnect
  Future<void> leaveRoom() async {
    try {
      await SignalRService.instance.leaveRoom();
      await SignalRService.instance.disconnect();
    } catch (_) {}
    _reset();
  }

  // ── SignalR Event Registration ────────────────────────────────────────────

  void _registerSignalREvents() {
    final hub = SignalRService.instance;

    // Room state events
    hub.on('RoomJoined', _onRoomJoined);
    hub.on('PlayerJoined', _onPlayerJoined);
    hub.on('PlayerLeft', _onPlayerLeft);
    hub.on('PlayerReady', _onPlayerReady);

    // Game flow events
    hub.on('GameStarted', _onGameStarted);
    hub.on('QuestionReceived', _onQuestionReceived);
    hub.on('TimerTick', _onTimerTick);
    hub.on('RoundEnded', _onRoundEnded);
    hub.on('GameEnded', _onGameEnded);

    // Error
    hub.on('Error', _onError);
  }

  // ── SignalR Event Handlers ────────────────────────────────────────────────

  void _onRoomJoined(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final data = _parseArg(args[0]);
    if (data == null) return;

    _currentRoom = GameRoomModel.fromJson(data);

    // If we didn't set the player yet from the REST call, find them in the room
    if (_currentPlayer != null) {
      // Try to refresh from the room player list (may have updated info)
      final found = _currentRoom!.players
          .where((p) => p.id == _currentPlayer!.id)
          .firstOrNull;
      if (found != null) _currentPlayer = found;
    }

    _state = GameState.waitingRoom;
    notifyListeners();
  }

  void _onPlayerJoined(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final data = _parseArg(args[0]);
    if (data == null) return;

    final newPlayer = PlayerModel.fromJson(
        data['player'] as Map<String, dynamic>);
    final totalPlayers = data['totalPlayers'] as int? ?? 0;

    if (_currentRoom != null) {
      final existing = _currentRoom!.players.any((p) => p.id == newPlayer.id);
      if (!existing) {
        final updatedPlayers = [..._currentRoom!.players, newPlayer];
        _currentRoom = _currentRoom!.copyWith(players: updatedPlayers);
      }
      notifyListeners();
    }
  }

  void _onPlayerLeft(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final data = _parseArg(args[0]);
    if (data == null) return;

    final playerId = data['playerId'] as String?;
    if (playerId != null && _currentRoom != null) {
      final updatedPlayers =
          _currentRoom!.players.where((p) => p.id != playerId).toList();
      _currentRoom = _currentRoom!.copyWith(players: updatedPlayers);
      notifyListeners();
    }
  }

  void _onPlayerReady(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final data = _parseArg(args[0]);
    if (data == null) return;

    final playerId = data['playerId'] as String?;
    if (playerId != null && _currentRoom != null) {
      final updatedPlayers = _currentRoom!.players.map((p) {
        if (p.id == playerId) return p.copyWith(isReady: true);
        return p;
      }).toList();
      _currentRoom = _currentRoom!.copyWith(players: updatedPlayers);
      notifyListeners();
    }
  }

  void _onGameStarted(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final data = _parseArg(args[0]);
      if (data != null) {
        _totalRounds = data['totalRounds'] as int? ?? 10;
      }
    }
    _state = GameState.starting;
    notifyListeners();
  }

  void _onQuestionReceived(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final data = _parseArg(args[0]);
    if (data == null) return;

    _currentQuestion = QuestionModel.fromJson(data);
    _questionReceivedAt = DateTime.now();
    _selectedOption = null;
    _hasAnswered = false;
    _timerSeconds = 10;
    _state = GameState.question;
    notifyListeners();
  }

  void _onTimerTick(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final seconds = args[0];
    if (seconds is int) {
      _timerSeconds = seconds;
      notifyListeners();
    }
  }

  void _onRoundEnded(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final data = _parseArg(args[0]);
    if (data == null) return;

    _lastRoundResult = RoundResultModel.fromJson(data);

    // Update player scores from leaderboard
    if (_currentRoom != null && _lastRoundResult != null) {
      final updatedPlayers = _currentRoom!.players.map((p) {
        final entry = _lastRoundResult!.leaderboard
            .where((e) => e.playerId == p.id)
            .firstOrNull;
        if (entry != null) return p.copyWith(score: entry.score);
        return p;
      }).toList();
      _currentRoom = _currentRoom!.copyWith(players: updatedPlayers);
    }

    _state = GameState.roundResult;
    notifyListeners();
  }

  void _onGameEnded(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final data = _parseArg(args[0]);
    if (data == null) return;

    _gameResult = GameEndedModel.fromJson(data);
    _state = GameState.gameOver;
    notifyListeners();
  }

  void _onError(List<Object?>? args) {
    final message = args?.isNotEmpty == true ? args![0]?.toString() : 'Unknown error';
    _error = message;
    notifyListeners();
    // Clear error after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _error = null;
      notifyListeners();
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void setCurrentPlayer(PlayerModel player) {
    _currentPlayer = player;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading() {
    _state = GameState.joiningRoom;
    _error = null;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    _state = GameState.idle;
    notifyListeners();
  }

  void _reset() {
    _state = GameState.idle;
    _currentRoom = null;
    _currentPlayer = null;
    _currentQuestion = null;
    _lastRoundResult = null;
    _gameResult = null;
    _timerSeconds = 10;
    _selectedOption = null;
    _hasAnswered = false;
    _error = null;
    notifyListeners();
  }

  /// Safely parse a SignalR argument to a Map
  Map<String, dynamic>? _parseArg(Object? arg) {
    if (arg == null) return null;
    if (arg is Map<String, dynamic>) return arg;
    if (arg is String) {
      try {
        return jsonDecode(arg) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    // signalr_netcore may return Map<Object?, Object?>
    if (arg is Map) {
      return arg.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }
}
