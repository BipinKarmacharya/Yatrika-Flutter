import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/auth/logic/auth_provider.dart';
import 'package:tour_guide/features/community/presentation/widgets/community_search_delegate.dart';
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
    // 1. Initial Load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().refreshPosts();
    });

    // 2. Add Scroll Listener for Pagination (Backend searching technique)
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // If user is 200 pixels from the bottom, fetch next page
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Logic for provider.loadMorePosts() can go here if you implement paging
      // For now, it ensures the controller is ready for future paging updates
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll); // Clean up listener
    _scrollController.dispose();
    super.dispose();
  }

  // Handle Login Check and Modal
  void _handleCreatePost() {
    final auth = context.read<AuthProvider>();

    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please login to share your adventures!"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // Ensures it doesn't overlap status bar
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePostModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // watch() is correct here to rebuild when the list changes
    final provider = context.watch<CommunityProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Community Stories',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black54),
            onPressed: () async {
              await showSearch(
                context: context,
                delegate: CommunitySearchDelegate(),
              );
              // Optional: Refresh original feed after closing search
              if (context.mounted) {
                context.read<CommunityProvider>().refreshPosts();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Floating Action Button for better reachability
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreatePost,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshPosts(),
        color: AppColors.primary,
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(CommunityProvider provider) {
    // Case 1: Initial Loading
    if (provider.isLoading && provider.posts.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: 3,
        itemBuilder: (context, index) => const _SkeletonCard(),
      );
    }

    // Case 2: Error State
    if (provider.errorMessage != null && provider.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => provider.refreshPosts(),
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
            ),
          ],
        ),
      );
    }

    // Case 3: Empty List
    if (provider.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://cdn-icons-png.flaticon.com/512/6598/6598519.png', // Example placeholder
              height: 150,
              opacity: const AlwaysStoppedAnimation(0.5),
            ),
            const SizedBox(height: 20),
            const Text("No stories yet. Start the journey!"),
          ],
        ),
      );
    }

    // Case 4: Data List
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: provider.posts.length,
      itemBuilder: (context, index) {
        return CommunityPostFeedCard(post: provider.posts[index]);
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
                    ShimmerLoading(
                      width: 28,
                      height: 28,
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
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
