import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/auth/logic/auth_provider.dart';
import 'package:tour_guide/features/community/data/services/community_service.dart';
import 'package:tour_guide/features/community/presentation/widgets/community_post_card.dart';
import 'package:tour_guide/features/destination/data/destination_service.dart';
import 'package:tour_guide/features/destination/ui/destination_card.dart';
import 'package:tour_guide/features/destination/ui/destination_list_screen.dart';
import 'package:tour_guide/features/home/presentation/widgets/category_chips.dart';
import 'package:tour_guide/features/home/presentation/widgets/feature_cards.dart';
import 'package:tour_guide/features/home/presentation/widgets/plan_header.dart';
import 'package:tour_guide/features/home/presentation/widgets/section_header.dart';
import 'package:tour_guide/features/home/presentation/widgets/top_bar.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/theme/app_colors.dart';

// 2. Import the MODEL with the MD prefix (to use MD.Destination)
import 'package:tour_guide/features/destination/data/destination.dart' as MD;

// 3. Keep your community import as is
import 'package:tour_guide/features/community/data/models/community_post.dart' as CP;

class TourBookHome extends StatefulWidget {
  const TourBookHome({super.key, this.onProfileTap});
  final VoidCallback? onProfileTap;

  @override
  State<TourBookHome> createState() => _TourBookHomeState();
}

class _TourBookHomeState extends State<TourBookHome> {
  bool _showAllPosts = false;
  bool _loadingFeatured = true;
  bool _loadingCommunity = true;
  List<MD.Destination> _featuredDestinations = [];
  List<CP.CommunityPost> _communityPosts = [];
  String? _featuredError;
  String? _communityError;

  @override
  void initState() {
    super.initState();
    // Load data after the first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHomeData());
  }

  Future<void> _loadHomeData() async {
    await Future.wait([
      _loadFeatured(),
      _loadCommunity(),
    ]);
  }

  String? _formatImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${ApiClient.baseUrl}$path';
  }

  Future<void> _loadFeatured() async {
    setState(() { _loadingFeatured = true; _featuredError = null; });
    try {
      final list = await DestinationService.popular();
      if (mounted) setState(() => _featuredDestinations = list);
    } catch (e) {
      if (mounted) setState(() => _featuredError = "Failed to load destinations");
    } finally {
      if (mounted) setState(() => _loadingFeatured = false);
    }
  }

  Future<void> _loadCommunity() async {
    setState(() { _loadingCommunity = true; _communityError = null; });
    try {
      final posts = await CommunityService.trending();
      if (mounted) setState(() => _communityPosts = posts);
    } catch (e) {
      if (mounted) setState(() => _communityError = "Failed to load community posts");
    } finally {
      if (mounted) setState(() => _loadingCommunity = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access user data for greeting (e.g., "Hello, [Name]")
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.fullName ?? "Traveler";

    final featureCards = [
      FeatureCardData(
        'Explore', 
        Icons.explore_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DestinationListScreen())),
      ),
      const FeatureCardData('Trip Planner', Icons.event_note_outlined),
      const FeatureCardData('Itineraries', Icons.route_outlined),
    ];

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
                // TopBar now has access to the user through the provider indirectly
                TopBar(onProfileTap: widget.onProfileTap),
                const SizedBox(height: 12),
                Text("Hello, $userName!", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const CategoryChips(chips: ['Nearby', 'Popular', 'Budget', 'Nature', 'Adventure', 'Luxury']),
                const SizedBox(height: 16),
                const PlanHeader(),
                const SizedBox(height: 12),
                FeatureCardsRow(cards: featureCards),
                const SizedBox(height: 22),
                
                _buildSectionHeader('Featured destinations', onSeeAll: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const DestinationListScreen()));
                }),
                _buildFeaturedList(),
                
                const SizedBox(height: 22),
                _buildSectionHeader(
                  'Community posts', 
                  action: _showAllPosts ? 'Show less' : 'Show more',
                  onSeeAll: () => setState(() => _showAllPosts = !_showAllPosts)
                ),
                _buildCommunityList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildSectionHeader(String title, {String action = 'See all', required VoidCallback onSeeAll}) {
    return SectionHeader(title: title, actionText: action, onActionTap: onSeeAll);
  }

  Widget _buildFeaturedList() {
    if (_loadingFeatured) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    if (_featuredError != null) return _buildErrorWidget(_featuredError!, _loadFeatured);
    
    return FeaturedList(
      destinations: _featuredDestinations.map((d) {
        final imgUrl = _formatImageUrl(d.images.isNotEmpty ? d.images.first : null);
        return DestinationCardData(
          title: d.name,
          subtitle: d.shortDescription,
          tag: (d.tags.isNotEmpty ? d.tags.first : 'Dest'),
          tagColor: AppColors.primary,
          imageUrl: imgUrl ?? "", 
          metaIcon: Icons.location_on,
        );
      }).toList(),
    );
  }

  Widget _buildCommunityList() {
    if (_loadingCommunity) return const Center(child: CircularProgressIndicator());
    if (_communityError != null) return _buildErrorWidget(_communityError!, _loadCommunity);

    return Column(
      children: (_showAllPosts ? _communityPosts : _communityPosts.take(2))
          .map((post) {
            final String? firstMediaUrl = post.media.isNotEmpty ? post.media.first.mediaUrl : null;
            final imgUrl = _formatImageUrl(firstMediaUrl);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CommunityPostCard(
                post: CommunityPostData(
                  title: post.title,
                  author: post.user?.fullName ?? 'Traveler',
                  likes: post.totalLikes,
                  comments: 0,
                  imageUrl: imgUrl ?? "",
                  accent: AppColors.primary,
                ),
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