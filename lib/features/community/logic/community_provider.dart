import 'package:flutter/material.dart';
import 'package:tour_guide/core/api/api_client.dart';
import '../data/services/community_service.dart';
import '../data/models/community_post.dart'; // Import the API model directly

class CommunityProvider extends ChangeNotifier {
  // Use the API model list directly
  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCreating = false;
  bool get isCreating => _isCreating;

  List<CommunityPost> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Loads posts from the server
  Future<void> loadPosts() async {
    if (_posts.isNotEmpty) return; 
    await refreshPosts();
  }

  /// Forces a reload of posts
  Future<void> refreshPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // CommunityService already returns List<CommunityPost>
      _posts = await CommunityService.getPublicPosts();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles the like status of a post
  Future<void> toggleLike(int postId) async { // Changed to int to match CommunityPost ID
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final wasLiked = post.isLiked;

    // Optimistic Update
    // Note: CommunityPost must have a copyWith method for this to work
    _posts[index] = post.copyWith(
      isLiked: !wasLiked,
      totalLikes: wasLiked ? post.totalLikes - 1 : post.totalLikes + 1,
    );
    notifyListeners();

    try {
      if (wasLiked) {
        await CommunityService.unlike(postId.toString());
      } else {
        await CommunityService.like(postId.toString());
      }
    } catch (e) {
      // Revert if server fails
      _posts[index] = post;
      notifyListeners();
    }
  }

  Future<bool> createPost(String content, List<String> images) async {
    _isCreating = true;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        '/api/community/posts',
        body: {
          'content': content,
          'images': images,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      if (response != null) {
        // Optionally fetch latest posts again to refresh the feed
        await refreshPosts(); 
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }
}