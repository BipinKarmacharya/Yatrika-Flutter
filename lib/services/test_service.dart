import '../core/api/api_client.dart';

class TestService {
  static Future<dynamic> public() async =>
      await ApiClient.get('/api/test/public');
  static Future<dynamic> protected() async =>
      await ApiClient.get('/api/test/protected');
  static Future<dynamic> admin() async =>
      await ApiClient.get('/api/test/admin');
}
