import 'dart:convert';
import 'dart:io';
import '../../../../core/api/api_client.dart';
import '../models/community_post.dart';

class CommunityService {
  static List<CommunityPost> _mapResponse(dynamic data) {
    if (data == null) return [];
    if (data is Map<String, dynamic> && data.containsKey('content')) {
      return (data['content'] as List)
          .map((e) => CommunityPost.fromJson(e))
          .toList();
    }
    if (data is List) {
      return data.map((e) => CommunityPost.fromJson(e)).toList();
    }
    return [];
  }

  // Use a base path variable to make versioning changes easier
  static const String _base = '/api/community/posts';

  static Future<List<CommunityPost>> getPublicPosts({
    int page = 0,
    int size = 20,
  }) async {
    final data = await ApiClient.get(
      '$_base/public',
      query: {'page': page, 'size': size},
    );
    return _mapResponse(data);
  }

  static Future<CommunityPost> create(
    CommunityPost post,
    List<File> imageFiles,
  ) async {
    final data = await ApiClient.multipart(
      _base,
      fields: {'data': jsonEncode(post.toJson())},
      files: imageFiles,
      fileKey: 'images',
    );
    return CommunityPost.fromJson(data);
  }

  static Future<CommunityPost> update(
    int id,
    CommunityPost post,
    List<File> newImageFiles,
  ) async {
    final data = await ApiClient.multipart(
      '$_base/$id',
      method: 'PUT',
      fields: {'data': jsonEncode(post.toJson())},
      files: newImageFiles,
      fileKey: 'images',
    );
    return CommunityPost.fromJson(data);
  }

  static Future<List<CommunityPost>> trending() async {
    try {
      final response = await ApiClient.get(
        '/api/community/posts/trending?page=0&size=3',
      );

      if (response != null && response['content'] != null) {
        final List<dynamic> content = response['content'];
        return content.map((json) => CommunityPost.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching trending posts: $e");
      rethrow;
    }
  }

  static Future<CommunityPost> toggleLike(int id) async {
    final data = await ApiClient.post('$_base/$id/like/toggle');
    return CommunityPost.fromJson(data);
  }

  static Future<List<CommunityPost>> getMyPosts() async {
    final data = await ApiClient.get('$_base/my');
    return _mapResponse(data);
  }

  static Future<List<CommunityPost>> search(String query) async {
    final data = await ApiClient.get('$_base/search', query: {'query': query});
    return _mapResponse(data);
  }

  static Future<CommunityPost> getById(int id) async {
    final data = await ApiClient.get('$_base/$id');
    return CommunityPost.fromJson(data);
  }

  static Future<void> deletePost(int id) async {
    await ApiClient.delete('$_base/$id');
  }

  static Future<Map<String, dynamic>> userStats(String userId) async {
    final data = await ApiClient.get('$_base/user/$userId/stats');
    return data as Map<String, dynamic>;
  }
}