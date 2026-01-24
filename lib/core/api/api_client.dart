import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message; 
}

class ApiClient {

  static String get baseUrl {
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    return 'http://127.0.0.1:8080';
  }
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}

  // static const String baseUrl = 'https://yatrika-ympz.onrender.com'; // Render

  static final http.Client _http = http.Client();
  static String? _authToken;
  static const String _tokenKey = 'auth_token';
  
  static String? getToken() => _authToken;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
  }

  static Future<void> setAuthToken(String? token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
  }

  static Future<void> logout() async {
    await setAuthToken(null);
  }

  static Map<String, String> _defaultHeaders() {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (_authToken != null && _authToken!.isNotEmpty) 
        'Authorization': 'Bearer $_authToken',
    };
  }

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    // Ensure no double slashes
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse(baseUrl + cleanPath);
    if (query != null) {
      return uri.replace(
        queryParameters: query.map((k, v) => MapEntry(k, '$v')),
      );
    }
    return uri;
  }

  // --- Unified Request Handler ---
  static Future<dynamic> _handleRequest(Future<http.Response> Function() request) async {
    try {
      final res = await request().timeout(const Duration(seconds: 20));
      return _decodeOrThrow(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Connection error: ${e.toString()}");
    }
  }

  static Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _handleRequest(() => _http.get(_uri(path, query), headers: _defaultHeaders()));

  static Future<dynamic> post(String path, {Object? body}) =>
      _handleRequest(() => _http.post(
            _uri(path),
            headers: _defaultHeaders(),
            body: body is String ? body : jsonEncode(body),
          ));

  static Future<dynamic> put(String path, {Object? body}) =>
      _handleRequest(() => _http.put(
            _uri(path),
            headers: _defaultHeaders(),
            body: body is String ? body : jsonEncode(body),
          ));

  static Future<dynamic> delete(String path) =>
      _handleRequest(() => _http.delete(_uri(path), headers: _defaultHeaders()));

  static dynamic _decodeOrThrow(http.Response res) {
    final code = res.statusCode;
    if (code == 401) {
      logout();
      throw ApiException("Session expired. Please log in again.", statusCode: 401);
    }

    if (code >= 200 && code < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    } else {
      String message = "Server Error";
      try {
        final errorBody = jsonDecode(res.body);
        message = errorBody['message'] ?? errorBody['error'] ?? message;
      } catch (_) {}
      throw ApiException(message, statusCode: code);
    }
  }

  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return "$baseUrl$cleanPath";
  }
}