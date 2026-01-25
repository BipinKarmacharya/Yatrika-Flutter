import 'package:flutter/material.dart';
import '../data/services/community_service.dart';
import '../data/models/community_post.dart';

class CommunityProvider extends ChangeNotifier {
  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCreating = false;

  List<CommunityPost> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isCreating => _isCreating;

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
// class CommunityProvider extends ChangeNotifier {
//   List<CommunityPost> _posts = [];
//   bool _isLoading = false;
//   String? _errorMessage;
//   bool _isCreating = false;

//   List<CommunityPost> get posts => _posts;
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;
//   bool get isCreating => _isCreating;

//   /// Loads posts from the server
//   Future<void> loadPosts() async {
//     // FIX: Remove the 'if (_posts.isNotEmpty) return;' to ensure 
//     // we can actually fetch data if the app state needs it.
//     await refreshPosts();
//   }

//   /// Forces a reload of posts
//   Future<void> refreshPosts() async {
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();

//     try {
//       // Ensure this service method fetches the latest from your Spring Boot backend
//       _posts = await CommunityService.getPublicPosts();
//     } catch (e) {
//       _errorMessage = "Could not load posts. Please try again.";
//       debugPrint("Load Error: $e");
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   /// Create a post using the Raw Payload from the Modal
//   /// This ensures the destination, tags, and itinerary are actually saved.
//   Future<bool> createPostFromRaw(Map<String, dynamic> payload) async {
//     _isCreating = true;
//     notifyListeners();

//     try {
//       // Call the service that talks to your Spring Boot backend
//       await CommunityService.createRaw(payload);
      
//       // SUCCESS: Refresh the list so the new post appears at the top
//       await refreshPosts(); 
//       return true;
//     } catch (e) {
//       _errorMessage = e.toString();
//       return false;
//     } finally {
//       _isCreating = false;
//       notifyListeners();
//     }
//   }

//   Future<void> toggleLike(int postId) async {
//     final index = _posts.indexWhere((p) => p.id == postId);
//     if (index == -1) return;

//     final post = _posts[index];
//     final wasLiked = post.isLiked;

//     _posts[index] = post.copyWith(
//       isLiked: !wasLiked,
//       totalLikes: wasLiked ? post.totalLikes - 1 : post.totalLikes + 1,
//     );
//     notifyListeners();

//     try {
//       if (wasLiked) {
//         await CommunityService.unlike(postId.toString());
//       } else {
//         await CommunityService.like(postId.toString());
//       }
//     } catch (e) {
//       _posts[index] = post;
//       notifyListeners();
//     }
//   }
// }