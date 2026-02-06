import 'package:flutter/material.dart';
import 'package:tour_guide/core/api/api_client.dart';
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

  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;

  // RANKED FEED LOGIC: Simple Score-based sorting
  void _sortPostsByRank() {
    _posts.sort((a, b) {
      // We use .toInt() to ensure the result is an integer
      int scoreA =
          ((a.totalLikes * 2) + (a.user?.isFollowing == true ? 100 : 0))
              .toInt();
      int scoreB =
          ((b.totalLikes * 2) + (b.user?.isFollowing == true ? 100 : 0))
              .toInt();

      return scoreB.compareTo(scoreA); // Descending order
    });
  }

  // FOLLOW SYSTEM
  Future<void> toggleFollow(int authorId) async {
    // 1. Optimistically update all posts by this author in the feed
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
      // 2. Call Backend: POST /api/users/{id}/follow
      await ApiClient.post('/api/users/$authorId/follow');
    } catch (e) {
      // 3. Revert on failure
      _errorMessage = "Failed to update follow status";
      refreshPosts(); // Reload to sync with server state
    }
  }

  // REFRESH with Ranking
  Future<void> refreshPosts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _posts = await CommunityService.getPublicPosts();
      _sortPostsByRank(); // Apply ranking after fetch
    } catch (e) {
      _errorMessage = "Could not load posts.";
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

  Future<bool> updatePost(int id, Map<String, dynamic> data) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // API Call: PUT /api/community/posts/{id}
      final response = await ApiClient.put(
        '/api/community/posts/$id',
        body: data,
      );

      // Update local list so user sees changes immediately without a full reload
      final index = _posts.indexWhere((p) => p.id == id);
      if (index != -1 && response != null) {
        _posts[index] = CommunityPost.fromJson(response);
      }

      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isUpdating = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePost(int id) async {
    try {
      await CommunityService.deletePost(id);
      // Remove from local list immediately for snappy UI
      _posts.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
