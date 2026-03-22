import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/app_constants.dart';

/// Manages the current logged-in user.
/// Persists the user to SharedPreferences so login survives app restarts.
class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  /// Try to restore user from local storage on app start
  Future<void> tryRestoreUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.userIdKey);
    final username = prefs.getString(AppConstants.usernameKey);

    if (userId != null && username != null) {
      _currentUser = UserModel(
        id: userId,
        username: username,
        createdAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// Create (or retrieve) a user by username, then persist locally.
  Future<bool> login(String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await ApiService.instance.createUser(username.trim());
      _currentUser = user;

      // Persist for next app launch
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userIdKey, user.id);
      await prefs.setString(AppConstants.usernameKey, user.username);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.usernameKey);
    _currentUser = null;
    notifyListeners();
  }
}
