import 'dart:io';

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
  String? get token => ApiClient.getToken();

  // --- INTERNAL HELPERS ---

  void _setLoading(bool value) {
    if (_isLoading == value) return; // Prevent unnecessary UI rebuilds
    _isLoading = value;
    notifyListeners();
  }

  /// Manually clear errors before new actions
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // --- AUTH ACTIONS ---

  void continueAsGuest() {
    _isGuest = true;
    _user = null;
    _error = null;
    notifyListeners();
  }

  /// Checks for stored credentials on app launch
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
      debugPrint("Session check failed: $e");
      await logout(); // Token likely expired
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiClient.post(
        '/api/v1/auth/login',
        body: {'emailOrUsername': email, 'password': password},
      );

      final String? token = response['token'] ?? response['accessToken'];

      if (token != null) {
        // Handle cases where user data might not be in the initial response
        if (response['user'] != null) {
          _user = UserModel.fromJson(response['user']);
        } else {
          // If the login response only gives a token, fetch user profile immediately
          // Temporarily set token manually to allow the getMe() call to work
          await ApiClient.setAuthToken(token, null);
          _user = await AuthService.getMe();
        }

        // Save permanent token with the correct User ID
        await ApiClient.setAuthToken(token, int.tryParse(_user!.id.toString()));

        _isGuest = false;
        _error = null;
        notifyListeners();
        return true;
      }
      _error = "Authentication failed: No token received.";
      return false;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiClient.post(
        '/api/v1/auth/register',
        body: userData,
      );
      final token = response['token'] ?? response['accessToken'];

      if (token != null) {
        // Set temporary token to fetch full user model
        await ApiClient.setAuthToken(token, null);
        _user = await AuthService.getMe();

        // Finalize token storage with ID
        await ApiClient.setAuthToken(token, int.tryParse(_user!.id.toString()));

        _isGuest = false;
        notifyListeners();
        return true;
      }
      _error = "Account created, but could not sign in automatically.";
      return false;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- USER PROFILE ACTIONS ---

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String username,
    required List<int> interestIds,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // 1. Update basic info
      await ApiClient.put(
        '/api/v1/users/${_user?.id}',
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
        },
      );

      // 2. Update interests separately
      await ApiClient.put('/api/v1/users/me/interests', body: interestIds);

      // 3. Refresh user state from server to ensure local data is 100% accurate
      final refreshedUser = await AuthService.getMe();
      _user = refreshedUser;

      notifyListeners();
      return true;
    } catch (e) {
      _error = "Failed to update profile. Please try again.";
      debugPrint("Update Profile Error: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfileImage(File image) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiClient.multipart(
        '/api/v1/users/me/profile-image', // ✅ match backend
        files: [image],
        method: 'PATCH', // ✅ specify PATCH explicitly
        fileKey: 'file', // ✅ must match backend @RequestParam
      );

      // Update local user state
      _user = UserModel.fromJson(response);
      notifyListeners();
    } catch (e) {
      _error = "Failed to update profile image";
      debugPrint("Profile image update error: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await ApiClient.logout();
    } finally {
      _user = null;
      _isGuest = false;
      _error = null;
      _setLoading(false);
    }
  }
}
