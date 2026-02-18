import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/core/api/api_client.dart';
// import 'package:cached_network_image/cached_network_image.dart';
import 'package:tour_guide/features/auth/ui/login_screen.dart';
import 'package:tour_guide/features/community/logic/community_provider.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:tour_guide/features/user/presentation/widgets/my_stories_tab_view.dart';
import 'package:tour_guide/features/user/presentation/widgets/saved_tab_view.dart';
import 'package:tour_guide/features/interest/data/models/interest.dart';
import 'package:tour_guide/features/interest/logic/interest_provider.dart';

// Ensure these paths match your project structure
import '../../../../core/theme/app_colors.dart';
import '../../../auth/logic/auth_provider.dart';
import '../widgets/profile_stats_row.dart';
import '../widgets/settings_tab_view.dart';
import '../widgets/my_trips_tab_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ This code runs EXACTLY ONCE when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final interestProvider = context.read<InterestProvider>();
      // final community = context.read<CommunityProvider>();

      if (auth.isLoggedIn && auth.user != null) {
        interestProvider.load(preselectedIds: auth.user!.interestIds);
        context.read<CommunityProvider>().fetchUserStats(
          auth.user!.id.toString(),
        );
        context.read<CommunityProvider>().fetchMyPosts();
        context.read<ItineraryProvider>().fetchMyPlans();
      }
    });
  }

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    final auth = context.read<AuthProvider>();
    await auth.updateProfileImage(File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final community = context.watch<CommunityProvider>();

    final interestProvider = context.watch<InterestProvider>();

    // 1. Handle Guest View
    if (!auth.isLoggedIn) return const _GuestProfileView();

    final user = auth.user;
    final fullName = "${user?.firstName ?? 'User'} ${user?.lastName ?? ''}";

    final userInterests = user?.interestIds ?? [];

    return DefaultTabController(
      length: 3, // Matches the tabs: Trips, Stories, Saved
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          title: const Text(
            "Profile",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.black),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                    ),
                    child: SettingsTabView(email: user?.email ?? ""),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: user?.profileImage != null
                              ? NetworkImage(
                                  ApiClient.getFullImageUrl(user!.profileImage),
                                )
                              : null,
                          child: user?.profileImage == null
                              ? Text(
                                  user!.fullName.isNotEmpty
                                      ? user.fullName[0].toUpperCase()
                                      : user.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        InkWell(
                          onTap: () => _pickAndUploadImage(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Dynamic Username
                    Text(
                      "@${user?.username ?? 'traveler'}",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),
                    if (userInterests.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: userInterests.map((id) {
                            final interestModel = interestProvider.all
                                .firstWhere(
                                  (i) => i.id == id,
                                  orElse: () =>
                                      Interest(id: id, name: "ID: $id"),
                                );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.8),
                                    AppColors.primary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                "#${interestModel.name}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    else
                      const Text(
                        "No interests added yet",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),

                    const SizedBox(height: 20),
                    // Statistics Row
                    ProfileStatsRow(
                      postCount: community.myPosts.length,
                      totalLikes:
                          community.userStats?['totalLikesReceived'] ?? 0,
                      followersCount: user?.followerCount ?? 0,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              // 6. Sticky Tabs Delegate
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    isScrollable: false, // Better look for 3 tabs
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      _TabItem(
                        icon: Icons.location_on_outlined,
                        label: "Trips",
                      ),
                      _TabItem(
                        icon: Icons.auto_awesome_mosaic_outlined,
                        label: "Stories",
                      ),
                      _TabItem(icon: Icons.bookmark_border, label: "Saved"),
                    ],
                  ),
                ),
              ),
            ],
            body: const TabBarView(
              children: [MyTripsTabView(), MyStoriesTabView(), SavedTabView()],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Internal Helper Widgets to fix "Undefined name" errors ---

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
      ),
    );
  }
}

// This class is REQUIRED to make the TabBar stick to the top
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white, // Background of the sticky bar
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

// Placeholder for your Guest View
class _GuestProfileView extends StatelessWidget {
  const _GuestProfileView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 320,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        width: 110,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                      const Spacer(),
                      const Text(
                        'Your Travel\nJournal Awaits',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Sign in to sync your trips and explore more.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const _FeatureGrid(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "Sign In / Create Account",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildSocialLoginSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLoginSection() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                "or continue with",
                style: TextStyle(color: AppColors.subtext, fontSize: 12),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialBtn(
              icon: Icons.g_mobiledata,
              color: Colors.red,
              label: "Google",
            ),
            const SizedBox(width: 20),
            _SocialBtn(
              icon: Icons.facebook,
              color: AppColors.primary,
              label: "Facebook",
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _FCard(icon: Icons.auto_awesome, title: "AI Planner"),
        _FCard(icon: Icons.favorite_border, title: "Favorites"),
        _FCard(icon: Icons.public, title: "Community"),
        _FCard(icon: Icons.history, title: "Trip History"),
      ],
    );
  }
}

class _FCard extends StatelessWidget {
  final IconData icon;
  final String title;
  const _FCard({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _SocialBtn({
    required this.icon,
    required this.color,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stroke),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
