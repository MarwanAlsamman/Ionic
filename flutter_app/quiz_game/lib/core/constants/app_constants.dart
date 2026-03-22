/// Central place for all app-wide constants.
/// Change [baseUrl] to point to your backend server.
class AppConstants {
  AppConstants._();

  // ── Backend URLs ────────────────────────────────────────────────────────
  /// For Android emulator, use 10.0.2.2 to reach host machine localhost.
  /// For physical device or iOS simulator, use your machine's LAN IP, e.g.:
  ///   static const String baseUrl = 'http://192.168.1.100:5000';
  static const String baseUrl = 'http://10.0.2.2:5000';
  static const String hubUrl = '$baseUrl/gamehub';

  // ── API Endpoints ────────────────────────────────────────────────────────
  static const String createUserEndpoint = '$baseUrl/api/user';
  static const String createRoomEndpoint = '$baseUrl/api/gameroom/create';
  static const String joinRoomEndpoint = '$baseUrl/api/gameroom/join';
  static const String getRoomEndpoint = '$baseUrl/api/gameroom';

  // ── Local Storage Keys ───────────────────────────────────────────────────
  static const String userIdKey = 'quiz_user_id';
  static const String usernameKey = 'quiz_username';

  // ── Game Config ──────────────────────────────────────────────────────────
  static const int roundDurationSeconds = 10;
  static const int resultDisplaySeconds = 4;

  // ── Score ────────────────────────────────────────────────────────────────
  static const int baseScore = 10;
  static const int maxSpeedBonus = 5;
}
