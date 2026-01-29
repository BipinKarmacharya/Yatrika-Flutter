import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/user_model.dart';

class AuthService {
  static Future<AuthResponse> login(String username, String password) async {
    final data = await ApiClient.post(
      ApiEndpoints.login,
      body: {'username': username, 'password': password},
    );
    final authRes = AuthResponse.fromJson(data);

    // 1. Convert String ID to int
    // 2. Use authRes.user.id (removing the ? if authRes is guaranteed)
    final userId = int.tryParse(authRes.user.id.toString());

    // Save both token and user ID
    await ApiClient.setAuthToken(authRes.token, userId);
    return authRes;
  }

  static Future<AuthResponse> register(Map<String, dynamic> body) async {
    final data = await ApiClient.post(ApiEndpoints.register, body: body);
    final authRes = AuthResponse.fromJson(data);
    
    // Parse ID for registration as well
    final userId = int.tryParse(authRes.user.id.toString());
    
    await ApiClient.setAuthToken(authRes.token, userId);
    return authRes;
  }

  static Future<UserModel> getMe() async {
    // Ensure you add 'static const String me = "/api/auth/me";' to ApiEndpoints
    final response = await ApiClient.get('/api/auth/me');
    return UserModel.fromJson(response);
  }

  static Future<void> logout() async => await ApiClient.logout();
}
