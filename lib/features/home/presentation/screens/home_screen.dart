import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/auth/logic/auth_provider.dart';
import 'package:tour_guide/features/community/data/services/community_service.dart';
import 'package:tour_guide/features/destination/data/services/destination_service.dart';
import 'package:tour_guide/features/destination/presentation/screens/destination_list_screen.dart';
import 'package:tour_guide/features/destination/presentation/widgets/destination_card.dart';
import 'package:tour_guide/features/home/presentation/widgets/category_chips.dart';
import 'package:tour_guide/features/home/presentation/widgets/feature_cards.dart';
import 'package:tour_guide/features/home/presentation/widgets/plan_header.dart';
import 'package:tour_guide/features/home/presentation/widgets/section_header.dart';
import 'package:tour_guide/features/home/presentation/widgets/top_bar.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/theme/app_colors.dart';

// Import the MODEL with prefix
import 'package:tour_guide/features/destination/data/models/destination.dart'
    as MD;
import 'package:tour_guide/features/community/data/models/community_post.dart'
    as CP;

class TourBookHome extends StatefulWidget {
  const TourBookHome({super.key, this.onProfileTap, this.onNavigateToDiscover});
  final VoidCallback? onProfileTap;
  final VoidCallback? onNavigateToDiscover;

  @override
  State<TourBookHome> createState() => _TourBookHomeState();
}

class _TourBookHomeState extends State<TourBookHome> {
  bool _showAllPosts = false;
  bool _loadingFeatured = true;
  bool _loadingCommunity = true;
  bool _loadingRecommended = true;

  List<MD.Destination> _featuredDestinations = [];
  List<MD.Destination> _recommendedDestinations = [];
  List<CP.CommunityPost> _communityPosts = [];

  String? _featuredError;
  String? _communityError;
  String? _recommendedError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHomeData());
  }

  Future<void> _loadHomeData() async {
    // Parallel loading
    await Future.wait([
      _loadFeatured(),
      _loadCommunity(),
      _loadRecommendations(),
    ]);
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) return;
    setState(() {
      _loadingRecommended = true;
      _recommendedError = null;
    });
    try {
      final list = await DestinationService.getRecommendations();
      debugPrint("Recommendations Loaded: ${list.length} items"); // DEBUG PRINT
      if (mounted) setState(() => _recommendedDestinations = list);
    } catch (e) {
      debugPrint("Recommendation Error: $e"); // DEBUG PRINT
      if (mounted) {
        setState(() => _recommendedError = "Failed to load recommendations");
      }
    } finally {
      if (mounted) setState(() => _loadingRecommended = false);
    }
  }

  // Same for _loadFeatured and _loadCommunity...
  Future<void> _loadFeatured() async {
    if (!mounted) return;
    setState(() {
      _loadingFeatured = true;
      _featuredError = null;
    });
    try {
      final list = await DestinationService.popular();
      if (mounted) setState(() => _featuredDestinations = list);
    } catch (e) {
      if (mounted) {
        setState(() => _featuredError = "Failed to load destinations");
      }
    } finally {
      if (mounted) setState(() => _loadingFeatured = false);
    }
  }

  Future<void> _loadCommunity() async {
    if (!mounted) return;
    setState(() {
      _loadingCommunity = true;
      _communityError = null;
    });
    try {
      final posts = await CommunityService.trending();
      if (mounted) setState(() => _communityPosts = posts);
    } catch (e) {
      if (mounted) {
        setState(() => _communityError = "Failed to load community posts");
      }
    } finally {
      if (mounted) setState(() => _loadingCommunity = false);
    }
  }

  String? _formatImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${ApiClient.baseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.fullName ?? "Traveler";

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHomeData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TopBar(onProfileTap: widget.onProfileTap),
                const SizedBox(height: 12),
                Text(
                  "Hello, $userName!",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const CategoryChips(
                  chips: [
                    'Nearby',
                    'Popular',
                    'Budget',
                    'Nature',
                    'Adventure',
                    'Luxury',
                  ],
                ),
                const SizedBox(height: 16),
                const PlanHeader(),
                const SizedBox(height: 12),
                FeatureCardsRow(
                  cards: [
                    FeatureCardData('Explore', Icons.explore_outlined),
                    const FeatureCardData(
                      'Trip Planner',
                      Icons.event_note_outlined,
                    ),
                    const FeatureCardData('Itineraries', Icons.route_outlined),
                  ],
                ),
                const SizedBox(height: 22),

                // --- IMPROVED RECOMMENDATIONS SECTION ---
                if (auth.isLoggedIn) ...[
                  _buildSectionHeader('Recommended for You', onSeeAll: () {}),
                  _buildRecommendationList(),
                  const SizedBox(height: 22),
                ],

                _buildSectionHeader(
                  'Featured destinations',
                  onSeeAll: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DestinationListScreen(),
                    ),
                  ),
                ),
                _buildFeaturedList(),

                const SizedBox(height: 22),
                _buildSectionHeader(
                  'Community posts',
                  action: _showAllPosts ? 'Show less' : 'Show more',
                  onSeeAll: () =>
                      setState(() => _showAllPosts = !_showAllPosts),
                ),
                _buildCommunityList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationList() {
    if (_loadingRecommended) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // If list is empty, show a nice hint instead of nothing
    if (_recommendedDestinations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          "Update your interests in settings to see personalized trips!",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return FeaturedList(destinations: _recommendedDestinations);
  }

  // --- UI HELPERS ---

  Widget _buildSectionHeader(
    String title, {
    String action = 'See all',
    required VoidCallback onSeeAll,
  }) {
    return SectionHeader(
      title: title,
      actionText: action,
      onActionTap: onSeeAll,
    );
  }

  Widget _buildFeaturedList() {
    if (_loadingFeatured) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_featuredError != null) {
      return _buildErrorWidget(_featuredError!, _loadFeatured);
    }

    return FeaturedList(destinations: _featuredDestinations);
  }

  Widget _buildCommunityList() {
    if (_loadingCommunity) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_communityError != null) {
      return _buildErrorWidget(_communityError!, _loadCommunity);
    }

    final displayedPosts = _showAllPosts
        ? _communityPosts
        : _communityPosts.take(3).toList();

    return Column(
      children: displayedPosts.map((post) {
        final imgUrl = _formatImageUrl(
          post.coverImageUrl.isNotEmpty
              ? post.coverImageUrl
              : (post.media.isNotEmpty ? post.media.first.mediaUrl : null),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imgUrl ?? "https://via.placeholder.com/100",
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, size: 40),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "by ${post.authorName} • ${post.tripDurationDays} days",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        children: [
          Text(error, style: const TextStyle(color: Colors.red)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
