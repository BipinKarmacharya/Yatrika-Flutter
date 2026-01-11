import 'package:flutter/material.dart';
import 'package:tour_guide/core/api/api_client.dart';
import 'package:tour_guide/features/auth/data/models/user_model.dart';
import 'package:tour_guide/features/auth/data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isGuest = false;

  // --- GETTERS ---
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _error;
  bool get isGuest => _isGuest;
  bool get isLoggedIn => _user != null;

  // ✅ Fix for CreatePostModal: Added token getter
  String? get token => ApiClient.getToken();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void continueAsGuest() {
    _isGuest = true;
    _user = null;
    _error = null;
    notifyListeners();
  }

  /// Loads user session on app start
  Future<void> checkSession() async {
    _setLoading(true);
    _error = null;

    final savedToken = ApiClient.getToken();
    if (savedToken == null || savedToken.isEmpty) {
      _user = null;
      _isGuest = false;
      _setLoading(false);
      return;
    }

    try {
      _user = await AuthService.getMe();
      _isGuest = false;
    } catch (e) {
      await logout();
    } finally {
      _setLoading(false);
    }
  }

  /// Handles Login Logic
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiClient.post(
        '/api/auth/login',
        body: {'emailOrUsername': email, 'password': password},
      );

      // 1. Be flexible with the token key (check both 'token' and 'accessToken')
      final String? token = response['token'] ?? response['accessToken'];

      if (token != null) {
        // 2. Clear old session completely before saving new one
        await ApiClient.setAuthToken(token);

        // 3. Handle the user object safely
        if (response['user'] != null) {
          _user = UserModel.fromJson(response['user']);
        } else {
          // Fallback if user object isn't in login response
          _user = await AuthService.getMe();
        }

        _isGuest = false;
        _error = null; // Ensure error is null on success
        notifyListeners();
        return true;
      }
      // If we reach here, the server returned 200 OK but no token was found in JSON
      _error = "Server response missing security token";
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Fix for RegisterScreen: Added register method
  Future<bool> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiClient.post(
        '/api/auth/register',
        body: userData,
      );

      // Check for token or accessToken depending on your backend response
      final token = response['token'] ?? response['accessToken'];

      if (token != null) {
        await ApiClient.setAuthToken(token);
        _user = await AuthService.getMe();
        _isGuest = false;
        notifyListeners();
        return true;
      }
      _error = "Registration failed: No token received";
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await ApiClient.logout();
    _user = null;
    _isGuest = false;
    _error = null;
    notifyListeners();
  }
}
