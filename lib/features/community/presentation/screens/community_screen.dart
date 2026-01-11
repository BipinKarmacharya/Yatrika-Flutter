// import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/auth/logic/auth_provider.dart';
import 'package:tour_guide/features/community/presentation/widgets/create_post_modal.dart';
import '../../../../core/theme/app_colors.dart';
import '../../logic/community_provider.dart';

import '../../presentation/widgets/community_post_feed_card.dart';
import '../../../../../shared/widgets/shimmer_loading.dart';
// Note: We will move the CreatePost logic to its own widget/file later
// import 'widgets/create_post_modal.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    // Load posts once on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadPosts();
    });
  }

  void _handleCreatePost() {
    final auth = context.read<AuthProvider>();

    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please login to share your adventures!"),
          backgroundColor: Colors.orange,
        ),
      );
      // Optional: Redirect to login or show login sheet here
      return;
    }

    // Show the creation UI
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePostModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Travel Community',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
              size: 28,
            ),
            onPressed:
              _handleCreatePost,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshPosts(),
        color: AppColors.primary,
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(CommunityProvider provider) {
    if (provider.isLoading && provider.posts.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => const _SkeletonCard(),
      );
    }

    if (provider.errorMessage != null && provider.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(provider.errorMessage!),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => provider.refreshPosts(),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (provider.posts.isEmpty) {
      return const Center(child: Text("No adventures shared yet."));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16), // Simplified padding
      itemCount: provider.posts.length,
      itemBuilder: (context, index) {
        final postItem = provider.posts[index];
        return CommunityPostFeedCard(
          post: postItem, // Fixed: parameter name is 'post'
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              ShimmerLoading(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              SizedBox(width: 12),
              ShimmerLoading(width: 100, height: 12),
            ],
          ),
          SizedBox(height: 16),
          ShimmerLoading(
            width: double.infinity,
            height: 150,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ],
      ),
    );
  }
}
