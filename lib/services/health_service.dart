import '../core/api/api_client.dart';

class HealthService {
  static Future<Map<String, dynamic>> health() async {
    final data = await ApiClient.get('/api/health');
    return data as Map<String, dynamic>;
  }
}
