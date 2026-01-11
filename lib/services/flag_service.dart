import '../core/api/api_client.dart';

class FlagService {
  static Future<Map<String, dynamic>> flagContent(
    Map<String, dynamic> body,
  ) async {
    final data = await ApiClient.post('/api/flags', body: body);
    return data as Map<String, dynamic>;
  }
}
