import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/auth/logic/auth_provider.dart';
import 'package:tour_guide/features/community/presentation/widgets/create_post_modal.dart';
import '../../../../core/theme/app_colors.dart';
import '../../logic/community_provider.dart';
import '../../presentation/widgets/community_post_feed_card.dart';
import '../../../../../shared/widgets/shimmer_loading.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadPosts();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      return;
    }

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
      backgroundColor: const Color(0xFFF9FAFB), // Slightly off-white background to make cards pop
      appBar: AppBar(
        title: const Text(
          'Travel Community',
          style: TextStyle(
            color: Colors.black, 
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: false, // Align title to left like modern apps
        elevation: 0.5, // Subtle shadow for depth
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
              size: 28,
            ),
            onPressed: _handleCreatePost,
          ),
          const SizedBox(width: 8),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: 3,
        itemBuilder: (context, index) => const _SkeletonCard(),
      );
    }

    if (provider.errorMessage != null && provider.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(provider.errorMessage!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => provider.refreshPosts(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Retry", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (provider.posts.isEmpty) {
      return const Center(
        child: Text("No adventures shared yet. Be the first!"),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 100), // Room for bottom nav
      itemCount: provider.posts.length,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return CommunityPostFeedCard(
          post: provider.posts[index],
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(0), // Mirroring the card shape
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(
            width: double.infinity,
            height: 220,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    ShimmerLoading(width: 28, height: 28, borderRadius: BorderRadius.all(Radius.circular(14))),
                    SizedBox(width: 8),
                    ShimmerLoading(width: 100, height: 14),
                  ],
                ),
                const SizedBox(height: 16),
                const ShimmerLoading(width: 200, height: 18),
                const SizedBox(height: 12),
                const ShimmerLoading(width: double.infinity, height: 12),
                const SizedBox(height: 6),
                const ShimmerLoading(width: 150, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}