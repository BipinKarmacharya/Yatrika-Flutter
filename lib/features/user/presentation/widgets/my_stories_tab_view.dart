import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../community/logic/community_provider.dart'; // Adjust path
import '../../../community/presentation/screens/community_post_detail_screen.dart'; // Adjust path

class MyStoriesTabView extends StatelessWidget {
  const MyStoriesTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();
    final posts = provider.posts; // Eventually filter this for 'myPosts' in your provider logic

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty) {
      return const Center(child: Text("You haven't shared any stories yet."));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommunityPostDetailScreen(post: post),
              ),
            );
          },
          child: CachedNetworkImage(
            imageUrl: post.coverImageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[200]),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        );
      },
    );
  }
}