import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tour_guide/core/api/api_client.dart';
import '../data/services/community_service.dart';
import '../data/models/community_post.dart';

class CommunityProvider extends ChangeNotifier {
  List<CommunityPost> _posts = [];
  List<CommunityPost> _myPosts = [];
  Map<String, dynamic>? _userStats;

  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  String? _errorMessage;

  // Getters
  List<CommunityPost> get posts => _posts;
  List<CommunityPost> get myPosts => _myPosts;
  Map<String, dynamic>? get userStats => _userStats;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  // ================= FEED LOGIC =================

  void _sortPostsByRank() {
    _posts.sort((a, b) {
      int scoreA =
          ((a.totalLikes * 2) + (a.user?.isFollowing == true ? 100 : 0))
              .toInt();
      int scoreB =
          ((b.totalLikes * 2) + (b.user?.isFollowing == true ? 100 : 0))
              .toInt();
      return scoreB.compareTo(scoreA);
    });
  }

  Future<void> refreshPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _posts = await CommunityService.getPublicPosts();
      _sortPostsByRank();
    } catch (e) {
      _errorMessage = "Could not load posts: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearUserData() {
    _myPosts = [];
    _userStats = null;
    notifyListeners();
  }

  Future<void> fetchMyPosts() async {
    try {
      _myPosts = await CommunityService.getMyPosts();
      notifyListeners();
    } catch (e) {
      _myPosts = [];
      debugPrint("Error fetching my posts: $e");
      notifyListeners();
    }
  }

  Future<void> searchPosts(String query) async {
    if (query.isEmpty) {
      await refreshPosts();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      _posts = await CommunityService.search(query);
    } catch (e) {
      _errorMessage = "Search failed.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================= ACTIONS =================

  Future<bool> createPost(CommunityPost post, List<File> images) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await CommunityService.create(post, images);
      await refreshPosts();
      await fetchMyPosts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<bool> updatePost(
    int id,
    CommunityPost post,
    List<File> newImages,
  ) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedPost = await CommunityService.update(id, post, newImages);

      final index = _posts.indexWhere((p) => p.id == id);
      if (index != -1) {
        _posts[index] = updatedPost;
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(int postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final originalPost = _posts[index];
    final wasLiked = originalPost.isLiked;

    // Optimistic Update
    _posts[index] = originalPost.copyWith(
      isLiked: !wasLiked,
      totalLikes: wasLiked
          ? originalPost.totalLikes - 1
          : originalPost.totalLikes + 1,
    );
    notifyListeners();

    try {
      // Backend uses the toggle endpoint we built in Java
      await CommunityService.toggleLike(postId);
    } catch (e) {
      // Revert on failure
      _posts[index] = originalPost;
      _errorMessage = "Connection error. Like not saved.";
      notifyListeners();
    }
  }

  Future<void> toggleFollow(int authorId) async {
    // Optimistic Update for all posts by this author
    for (int i = 0; i < _posts.length; i++) {
      if (_posts[i].user?.id == authorId) {
        bool currentStatus = _posts[i].user?.isFollowing ?? false;
        _posts[i] = _posts[i].copyWith(
          user: _posts[i].user?.copyWith(isFollowing: !currentStatus),
        );
      }
    }
    notifyListeners();

    try {
      // This endpoint should be in your User/Auth Service usually
      await ApiClient.post('/api/v1/users/$authorId/follow');
    } catch (e) {
      _errorMessage = "Failed to update follow status";
      refreshPosts();
    }
  }

  Future<bool> deletePost(int id) async {
    try {
      await CommunityService.deletePost(id);
      _posts.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchUserStats(String userId) async {
    try {
      _userStats = await CommunityService.userStats(userId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    }
  }
}
