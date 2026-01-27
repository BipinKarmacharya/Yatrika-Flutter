import 'package:flutter/material.dart';
import '../data/services/community_service.dart';
import '../data/models/community_post.dart';

class CommunityProvider extends ChangeNotifier {
  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCreating = false;
  String _searchQuery = "";
  List<CommunityPost> _myPosts = [];
  Map<String, dynamic>? _userStats;

  List<CommunityPost> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isCreating => _isCreating;
  List<CommunityPost> get myPosts => _myPosts;
  Map<String, dynamic>? get userStats => _userStats;

  Future<void> refreshPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await CommunityService.getPublicPosts();
    } catch (e) {
      _errorMessage = "Could not load posts. Please try again.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyPosts() async {
    try {
      // Assuming your service has a getMyPosts method using the /api/community/posts/my
      _myPosts = await CommunityService.getMyPosts();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching my posts: $e");
    }
  }

  // NEW: Fetch user stats (likes, post count)
  Future<void> fetchUserStats(String userId) async {
    try {
      _userStats = await CommunityService.userStats(userId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    }
  }

  Future<void> searchPosts(String query) async {
    if (query.isEmpty) {
      await refreshPosts(); // Go back to normal feed if search is cleared
      return;
    }

    _searchQuery = query;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Assuming your CommunityService has a search method
      // If not, it usually calls the same list endpoint with a ?search= parameter
      final results = await CommunityService.search(query);
      _posts = results;
    } catch (e) {
      _errorMessage = "Search failed. Please try again.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(int postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final wasLiked = post.isLiked;

    // Optimistic UI Update: update the screen immediately
    _posts[index] = post.copyWith(
      isLiked: !wasLiked,
      totalLikes: wasLiked ? post.totalLikes - 1 : post.totalLikes + 1,
    );
    notifyListeners();

    try {
      if (wasLiked) {
        // Backend: DELETE /api/community/posts/{id}/like
        await CommunityService.unlike(postId.toString());
      } else {
        // Backend: POST /api/community/posts/{id}/like
        await CommunityService.like(postId.toString());
      }
    } catch (e) {
      // Revert if the server request fails
      _posts[index] = post;
      _errorMessage = "Could not update like. Please check connection.";
      notifyListeners();
    }
  }

  // Use this for the "Post Creation" modal
  Future<bool> createPostFromRaw(Map<String, dynamic> payload) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await CommunityService.createRaw(payload);
      await refreshPosts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }
}