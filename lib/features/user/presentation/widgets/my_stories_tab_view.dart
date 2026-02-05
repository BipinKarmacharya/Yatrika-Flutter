import 'package:flutter/material.dart'; // Changed from cupertino.dart
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tour_guide/features/community/logic/community_provider.dart';
import 'package:tour_guide/features/community/data/models/community_post.dart';
import 'package:tour_guide/features/community/presentation/screens/community_post_detail_screen.dart';

class MyStoriesTabView extends StatelessWidget {
  const MyStoriesTabView({super.key});

  // Helper to open the full post detail
  void _navigateToDetail(BuildContext context, CommunityPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityPostDetailScreen(post: post),
      ),
    );
  }

  // Helper for the empty state appearance
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "Your travel gallery is empty",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "Share your first story with the community!",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityProvider>();

    if (community.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (community.myPosts.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: community.myPosts.length,
      itemBuilder: (context, index) {
        final post = community.myPosts[index];
        return GestureDetector(
          onTap: () => _navigateToDetail(context, post),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The Post Thumbnail
              CachedNetworkImage(
                imageUrl: post.coverImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
              
              // Multiple media indicator (Top Right)
              if (post.media.length > 1)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.layers, color: Colors.white, size: 14),
                  ),
                ),
                
              // Subtle Gradient Overlay for Stats (Bottom)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        "${post.totalLikes}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}