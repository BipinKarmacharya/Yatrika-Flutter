import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/auth/logic/auth_provider.dart';
import 'package:tour_guide/features/community/data/services/community_service.dart';
import 'package:tour_guide/features/destination/data/services/destination_service.dart';
import 'package:tour_guide/features/destination/presentation/screens/destination_list_screen.dart';
import 'package:tour_guide/features/home/presentation/widgets/category_chips.dart';
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
      if (mounted) setState(() => _recommendedDestinations = list);
    } catch (e) {
      if (mounted) {
        setState(() => _recommendedError = "Failed to load recommendations");
      }
    } finally {
      if (mounted) setState(() => _loadingRecommended = false);
    }
  }

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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHomeData,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // --- App Bar Section ---
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 600 ? 24 : 16,
                    vertical: 12,
                  ),
                  child: TopBar(onProfileTap: widget.onProfileTap),
                ),
              ),

              // --- Welcome Section ---
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 600 ? 24 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        "Hello, $userName! 👋",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Where do you want to explore today?",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // --- Category Chips ---
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 600 ? 24 : 16,
                  ),
                  child: CategoryChips(
                    chips: [
                      'Nearby',
                      'Popular',
                      'Budget',
                      'Nature',
                      'Adventure',
                      'Luxury',
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // --- Plan Header ---
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 600 ? 24 : 16,
                  ),
                  child: const PlanHeader(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // --- Feature Cards ---
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 600 ? 24 : 16,
                  ),
                  child: _buildFeatureCardsRow(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // --- Recommended Section ---
              if (auth.isLoggedIn) ...[
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth > 600 ? 24 : 16,
                    ),
                    child: SectionHeader(
                      title: 'Recommended for You',
                      actionText: 'See all',
                      onActionTap: () {},
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.only(
                      left: screenWidth > 600 ? 24 : 16,
                      top: 12,
                      bottom: 20,
                    ),
                    height: 220,
                    child: _buildRecommendationList(),
                  ),
                ),
              ],

              // --- Featured Destinations ---
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 600 ? 24 : 16,
                  ),
                  child: SectionHeader(
                    title: 'Featured Destinations',
                    actionText: 'See all',
                    onActionTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DestinationListScreen(),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.only(
                    left: screenWidth > 600 ? 24 : 16,
                    top: 12,
                    bottom: 20,
                  ),
                  height: 280,
                  child: _buildFeaturedList(),
                ),
              ),

              // --- Community Posts ---
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 600 ? 24 : 16,
                  ),
                  child: SectionHeader(
                    title: 'Community Stories',
                    actionText: _showAllPosts ? 'Show less' : 'Show more',
                    onActionTap: () =>
                        setState(() => _showAllPosts = !_showAllPosts),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 600 ? 24 : 16,
                  ),
                  child: _buildCommunityList(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCardsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFeatureCard(
            'Explore',
            Icons.explore_outlined,
            const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 12),
          _buildFeatureCard(
            'Trip Planner',
            Icons.event_note_outlined,
            const Color(0xFF2196F3),
          ),
          const SizedBox(width: 12),
          _buildFeatureCard(
            'Itineraries',
            Icons.route_outlined,
            const Color(0xFF9C27B0),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String label, IconData icon, Color color) {
    return SizedBox(
      width: 140,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationList() {
    if (_loadingRecommended) {
      return _buildSkeletonList();
    }

    if (_recommendedError != null) {
      return _buildErrorCard(_recommendedError!, _loadRecommendations);
    }

    if (_recommendedDestinations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.travel_explore,
        title: "No recommendations yet",
        subtitle: "Update your interests to see personalized trips",
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _recommendedDestinations.length,
      itemBuilder: (context, index) {
        final destination = _recommendedDestinations[index];
        return _buildRecommendationCard(destination);
      },
    );
  }

  Widget _buildFeaturedList() {
    if (_loadingFeatured) {
      return _buildSkeletonList(isLarge: true);
    }

    if (_featuredError != null) {
      return _buildErrorCard(_featuredError!, _loadFeatured);
    }

    if (_featuredDestinations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.location_on_outlined,
        title: "No destinations found",
        subtitle: "Check back later for new places",
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _featuredDestinations.length,
      itemBuilder: (context, index) {
        final destination = _featuredDestinations[index];
        return _buildFeaturedCard(destination);
      },
    );
  }

  Widget _buildCommunityList() {
    if (_loadingCommunity) {
      return _buildCommunitySkeleton();
    }

    if (_communityError != null) {
      return _buildErrorCard(_communityError!, _loadCommunity);
    }

    final displayedPosts = _showAllPosts
        ? _communityPosts
        : _communityPosts.take(3).toList();

    if (displayedPosts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: "No community posts",
        subtitle: "Be the first to share your travel story",
      );
    }

    return Column(
      children: [
        ...displayedPosts.map((post) => _buildCommunityCard(post)),
        if (!_showAllPosts && _communityPosts.length > 3)
          TextButton(
            onPressed: () => setState(() => _showAllPosts = true),
            child: const Text(
              'View all stories',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // --- Card Builders ---

  Widget _buildRecommendationCard(MD.Destination destination) {
    final imageUrl = destination.images.isNotEmpty 
        ? destination.images.first 
        : null;
    
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image
              if (imageUrl != null)
                Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.photo_outlined,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                )
              else
                Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.photo_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                ),
              
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      destination.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            destination.district ?? 'Unknown location',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                const Shadow(
                                  blurRadius: 4,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          destination.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${destination.totalReviews})',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(MD.Destination destination) {
    final imageUrl = destination.images.isNotEmpty 
        ? destination.images.first 
        : null;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 280 : 240;
    
    return Container(
      width: cardWidth.toDouble(),
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Container(
                height: 160,
                width: double.infinity,
                color: Colors.grey[200],
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          destination.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              destination.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          destination.district ?? 'Unknown location',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Explore Now',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityCard(CP.CommunityPost post) {
    final imgUrl = post.coverImageUrl.isNotEmpty
        ? _formatImageUrl(post.coverImageUrl)
        : (post.media.isNotEmpty ? _formatImageUrl(post.media.first.mediaUrl) : null);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: imgUrl != null
                      ? Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImagePlaceholder(small: true),
                        )
                      : _buildImagePlaceholder(small: true),
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text(
                            post.authorName.isNotEmpty
                                ? post.authorName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'by ${post.authorName}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          color: Colors.grey[500],
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.tripDurationDays} days',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.favorite_outline,
                          color: Colors.grey[500],
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.totalLikes} likes',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Chevron
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSkeletonList({bool isLarge = false}) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: isLarge ? 240 : 180,
          margin: const EdgeInsets.only(right: 16),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isLarge ? 24 : 20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skeleton image
                Container(
                  height: isLarge ? 160 : 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(isLarge ? 24 : 20),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommunitySkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error, VoidCallback onRetry) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder({bool small = false}) {
    return Center(
      child: Icon(
        Icons.photo_outlined,
        size: small ? 40 : 60,
        color: Colors.grey[400],
      ),
    );
  }
}