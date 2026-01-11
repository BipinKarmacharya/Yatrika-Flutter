import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/user_model.dart';

class AuthService {
  static Future<AuthResponse> login(String username, String password) async {
    final data = await ApiClient.post(ApiEndpoints.login, body: {
      'username': username,
      'password': password,
    });
    final authRes = AuthResponse.fromJson(data);
    await ApiClient.setAuthToken(authRes.token);
    return authRes;
  }

  static Future<AuthResponse> register(Map<String, dynamic> body) async {
    final data = await ApiClient.post(ApiEndpoints.register, body: body);
    final authRes = AuthResponse.fromJson(data);
    await ApiClient.setAuthToken(authRes.token);
    return authRes;
  }

  static Future<UserModel> getMe() async {
    // Ensure you add 'static const String me = "/api/auth/me";' to ApiEndpoints
    final response = await ApiClient.get('/api/auth/me'); 
    return UserModel.fromJson(response);
  }

  static Future<void> logout() async => await ApiClient.logout();
}