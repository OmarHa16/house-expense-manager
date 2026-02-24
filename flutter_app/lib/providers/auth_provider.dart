import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  User? _user;
  String? _token;
  bool _isLoading = true;

  AuthProvider(this._prefs) {
    _loadAuthData();
  }

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _user != null && _token != null;
  bool get isLoading => _isLoading;
  bool get isAdmin => _user?.isAdmin ?? false;

  Future<void> _loadAuthData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _token = _prefs.getString('auth_token');
      if (_token != null) {
        apiService.setAuthToken(_token);
        // Verify token is still valid
        final currentUser = await apiService.getCurrentUser();
        if (currentUser != null) {
          _user = currentUser;
        } else {
          // Token expired or invalid
          await logout();
        }
      }
    } catch (e) {
      debugPrint('Error loading auth data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String name, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.login(name, password);
      _token = response.token;
      _user = response.user;
      
      // Save to preferences
      await _prefs.setString('auth_token', _token!);
      apiService.setAuthToken(_token);
      
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    apiService.setAuthToken(null);
    await _prefs.remove('auth_token');
    notifyListeners();
  }

  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }
}
