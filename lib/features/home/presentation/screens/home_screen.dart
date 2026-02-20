import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/home/logic/home_provider.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';

import '../widgets/home_header.dart';
import '../widgets/smart_search_section.dart';
import '../widgets/dynamic_hero.dart';
import '../widgets/section_header.dart';
import '../widgets/itinerary_card.dart';
import '../widgets/community_card.dart';
import '../widgets/home_shimmer.dart';

class TourBookHome extends StatefulWidget {
  const TourBookHome({super.key});

  @override
  State<TourBookHome> createState() => _TourBookHomeState();
}

class _TourBookHomeState extends State<TourBookHome> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load initial data
      context.read<HomeProvider>().loadHomeData(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers for changes
    final myPlans = context.watch<ItineraryProvider>().myPlans;
    final home = context.watch<HomeProvider>();
    
    // Get visible trips (sorted/filtered)
    final visibleTrips = home.getVisibleTrips(myPlans);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => home.loadHomeData(context),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Header (Greeting + Notifications)
            const SliverToBoxAdapter(child: HomeHeader()),

            // 2. Search & Prompts (UNCOMMENTED AND FIXED)
            SliverToBoxAdapter(
              child: SmartSearchSection(
                controller: _searchController,
                isProcessing: home.isAiPlanning,
                onSearch: (query) {
                  // Call the new refactored method
                  home.planWithSmartAI(context, query);
                  _searchController.clear(); // Optional: clear after search
                },
              ),
            ),

            // 3. AI Planner/Active Trip Hero
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              sliver: SliverToBoxAdapter(
                child: DynamicHero(
                  trips: visibleTrips,
                  onPlanTap: () => FocusScope.of(context).nextFocus(),
                  onDismiss: (id) => home.dismissTrip(id),
                ),
              ),
            ),

            // 4. Recommendations
            SliverToBoxAdapter(
              child: SectionHeader(
                title: "Recommended for You",
                onSeeAll: () {},
              ),
            ),
            SliverToBoxAdapter(child: _buildRecommendationList(home)),

            // 5. Community Feed
            SliverToBoxAdapter(
              child: SectionHeader(
                title: "From the Community",
                onSeeAll: () {},
              ),
            ),
            _buildCommunityFeed(home),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationList(HomeProvider home) {
    if (home.isLoading) return const HomeShimmer();
    if (home.recommended.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: home.recommended.length,
        itemBuilder: (context, index) =>
            ItineraryCard(itinerary: home.recommended[index]),
      ),
    );
  }

  Widget _buildCommunityFeed(HomeProvider home) {
    if (home.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => CommunityCard(post: home.communityPosts[index]),
          childCount: home.communityPosts.length,
        ),
      ),
    );
  }
}