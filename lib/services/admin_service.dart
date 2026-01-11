import '../core/api/api_client.dart';

class AdminService {
  static Future<Map<String, dynamic>> stats() async {
    final data = await ApiClient.get('/api/admin/stats');
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> analyticsUserGrowth() async {
    final data = await ApiClient.get('/api/admin/analytics/user-growth');
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> analyticsPopularDestinations() async {
    final data = await ApiClient.get(
      '/api/admin/analytics/popular-destinations',
    );
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> analyticsActivityTimes() async {
    final data = await ApiClient.get('/api/admin/analytics/activity-times');
    return data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getContentFlags() async {
    final data = await ApiClient.get('/api/admin/content-flags');
    return data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> resolveContentFlag(
    String flagId,
    Map<String, dynamic> body,
  ) async {
    final data = await ApiClient.post(
      '/api/admin/content-flags/$flagId/resolve',
      body: body,
    );
    return data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> listUsers({Map<String, dynamic>? query}) async {
    final data = await ApiClient.get('/api/admin/users', query: query);
    return data as List<dynamic>;
  }
}
