import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/home_provider.dart';
import '../widgets/home_shimmer.dart';
import '../widgets/home_cards.dart';
import '../widgets/top_bar.dart';
import '../widgets/category_chips.dart';
import '../widgets/section_header.dart';

class TourBookHome extends StatefulWidget {
  const TourBookHome({super.key, this.onProfileTap});
  final VoidCallback? onProfileTap;

  @override
  State<TourBookHome> createState() => _TourBookHomeState();
}

class _TourBookHomeState extends State<TourBookHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: home.loadHomeData,
        child: CustomScrollView(
          slivers: [
            // 1. Top Bar with Search (Use 'sliver:' instead of 'child:')
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
              // ✅ Corrected: SliverPadding uses 'sliver'
              sliver: SliverToBoxAdapter(child: TopBar(onProfileTap: widget.onProfileTap)),
            ),

            // 2. Categories
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // ✅ Corrected: SliverPadding uses 'sliver'
              sliver: SliverToBoxAdapter(child: CategoryChips(chips: const ['All', 'Nearby', 'Popular', 'Budget', 'Nature'])),
            ),

            // 3. Teal Hero Planner Card
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // ✅ Corrected: SliverPadding uses 'sliver'
              sliver: SliverToBoxAdapter(child: _buildPlannerHero()),
            ),

            // 4. Recommended Section
            _buildSectionHeader("Recommended for You"),
            SliverToBoxAdapter(
              child: home.isLoading 
                ? const HomeShimmer() 
                : _buildHorizontalList(home.recommended),
            ),

            // 5. Popular/Featured Destinations
            _buildSectionHeader("Popular Destinations"),
            SliverToBoxAdapter(
              child: home.isLoading 
                ? const HomeShimmer(isLarge: true) 
                : _buildHorizontalList(home.featured, isLarge: true),
            ),

            // 6. Community Section
            _buildSectionHeader("Community"),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // ✅ Corrected logic: Conditional rendering inside the sliver
              sliver: home.isLoading 
                ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => CommunityCard(post: home.communityPosts[index]),
                      childCount: home.communityPosts.length,
                    ),
                  ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ✅ Helper method updated to use 'sliver:'
  Widget _buildSectionHeader(String title) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      sliver: SliverToBoxAdapter(
        child: SectionHeader(title: title, actionText: "See all"),
      ),
    );
  }

  Widget _buildHorizontalList(List items, {bool isLarge = false}) {
    return SizedBox(
      height: isLarge ? 260 : 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: items.length,
        itemBuilder: (context, i) => RecommendationCard(destination: items[i]),
      ),
    );
  }

  Widget _buildPlannerHero() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF00BFA5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Plan your next escape", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("Discover destinations and build itineraries with AI", style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _heroAction(Icons.explore, "Explore"),
              _heroAction(Icons.calendar_month, "Planner"),
              _heroAction(Icons.map, "Itinerary"),
              _heroAction(Icons.auto_awesome, "AI Suggest"),
            ],
          )
        ],
      ),
    );
  }

  Widget _heroAction(IconData icon, String label) {
    return Container(
      width: 70, height: 85,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}