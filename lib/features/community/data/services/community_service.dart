// import 'dart:convert';
// import 'package:http/http.dart' as http;
import '../../../../core/api/api_client.dart';
import '../models/community_post.dart';

class CommunityService {
  // We don't need a hardcoded baseUrl here anymore because ApiClient handles it

  /// Helper to handle both simple Lists and Spring Boot Page objects ('content' key)
  static List<CommunityPost> _mapResponse(dynamic data) {
    if (data == null) return [];

    // Check for Spring Boot Pagination wrapper
    if (data is Map<String, dynamic> && data.containsKey('content')) {
      final List list = data['content'];
      return list.map((e) => CommunityPost.fromJson(e as Map<String, dynamic>)).toList();
    }

    // Check if it's a direct list
    if (data is List) {
      return data.map((e) => CommunityPost.fromJson(e as Map<String, dynamic>)).toList();
    }

    return [];
  }

  static Future<List<CommunityPost>> getPublicPosts({
    Map<String, dynamic>? query,
  }) async {
    final data = await ApiClient.get('/api/community/posts/public', query: query);
    return _mapResponse(data);
  }

  static Future<List<CommunityPost>> trending() async {
    final data = await ApiClient.get('/api/community/posts/trending');
    return _mapResponse(data);
  }

  static Future<List<CommunityPost>> getMyPosts() async {
    final data = await ApiClient.get('/api/community/posts/my');
    return _mapResponse(data);
  }

  static Future<List<CommunityPost>> search({
    Map<String, dynamic>? query,
  }) async {
    final data = await ApiClient.get('/api/community/posts/search', query: query);
    return _mapResponse(data);
  }

  static Future<CommunityPost> getById(String id) async {
    final data = await ApiClient.get('/api/community/posts/$id');
    return CommunityPost.fromJson(data as Map<String, dynamic>);
  }

  static Future<CommunityPost> create(CommunityPost post) async {
    final data = await ApiClient.post(
      '/api/community/posts',
      body: post.toJson(),
    );
    return CommunityPost.fromJson(data as Map<String, dynamic>);
  }

  static Future<CommunityPost> update(String id, CommunityPost post) async {
    final data = await ApiClient.put(
      '/api/community/posts/$id',
      body: post.toJson(),
    );
    return CommunityPost.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> delete(String id) async {
    await ApiClient.delete('/api/community/posts/$id');
  }

  static Future<void> like(String id) async {
    await ApiClient.post('/api/community/posts/$id/like');
  }

  static Future<void> unlike(String id) async {
    await ApiClient.delete('/api/community/posts/$id/like');
  }

  static Future<Map<String, dynamic>> userStats(String userId) async {
    final data = await ApiClient.get('/api/community/posts/user/$userId/stats');
    return data as Map<String, dynamic>;
  }

  /// ✅ UPDATED: Now uses ApiClient to handle the Token and URL automatically
  static Future<CommunityPost> createRaw(Map<String, dynamic> payload) async {
    final data = await ApiClient.post(
      '/api/community/posts',
      body: payload,
    );

    // ApiClient already decodes the JSON and handles errors (401, 403, etc.)
    return CommunityPost.fromJson(data as Map<String, dynamic>);
  }
}