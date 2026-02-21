import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/auth/logic/auth_provider.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_detail_screen.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/progress_stats.dart';
// Add this
import 'package:tour_guide/features/plan/presentation/screens/plan_setup_screen.dart'; // Add this
// Add this
import 'package:tour_guide/features/plan/presentation/widgets/plan_options_grid.dart';
import 'package:tour_guide/features/plan/presentation/screens/plan_with_ai_screen.dart';

class PlanScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToDiscover;

  const PlanScreen({super.key, this.onBack, this.onNavigateToDiscover});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  // Use a local controller since the old external controller is gone
  final TextEditingController _quickDestinationController =
      TextEditingController();

  @override
  void dispose() {
    _quickDestinationController.dispose();
    super.dispose();
  }

  // Navigates to the new multi-step setup screen
  void _navigateToManualSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlanSetupScreen()),
    );
  }

  // Handle the Quick Start (Input field + Start button)
  // void _onQuickStart() {
  //   final destination = _quickDestinationController.text.trim();
  //   if (destination.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Please enter a destination first')),
  //     );
  //     return;
  //   }

  //   // 1. Initialize the draft via Provider
  //   context.read<TripCreatorProvider>().initNewTrip(
  //     title: 'Trip to $destination',
  //     totalDays: 3, // Default for quick start
  //   );

  //   // 2. Clear input and jump straight to activity builder
  //   _quickDestinationController.clear();
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => const ManualItineraryBuilderScreen(),
  //     ),
  //   );
  // }

  // void _onPickDestination() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Select Destination'),
  //       content: SingleChildScrollView(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             _buildDestinationTile('Kathmandu, Nepal'),
  //             _buildDestinationTile('Pokhara, Nepal'),
  //             _buildDestinationTile('Tokyo, Japan'),
  //             _buildDestinationTile('Paris, France'),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildDestinationTile(String destination) {
  //   return ListTile(
  //     leading: const Icon(Icons.location_on_outlined),
  //     title: Text(destination),
  //     onTap: () {
  //       setState(() => _quickDestinationController.text = destination);
  //       Navigator.pop(context);
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.select<AuthProvider, bool>(
      (auth) => auth.isLoggedIn,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildTitleSection(),
              const SizedBox(height: 20),

              if (isLoggedIn) ...[
                _buildOngoingTrips(context.watch<ItineraryProvider>().myPlans),
                _buildPlanOptions(),
                const SizedBox(height: 24),

                // Pass the local controller here
                // QuickStartSection(
                //   destinationController: _quickDestinationController,
                //   onUseAI: _navigateToAIPlan,
                //   onStartTrip: _onQuickStart,
                //   onPickDestination: _onPickDestination,
                // ),
                // const SizedBox(height: 16),
              ],

              if (!isLoggedIn) ...[
                _buildGuestMessage(),
                const SizedBox(height: 20),
              ],

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Tip: You can add activities, notes and schedules after creating your trip.',
                  style: TextStyle(color: AppColors.subtext, fontSize: 13),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOngoingTrips(List<Itinerary> myPlans) {
    final ongoing = myPlans
        .where((p) => p.status != 'COMPLETED')
        .where((p) {
          final hasItems = p.items?.isNotEmpty ?? false;
          final hasSummaryActivities = (p.summary?.activityCount ?? 0) > 0;
          final hasDescription = p.description?.trim().isNotEmpty ?? false;
          return hasItems || hasSummaryActivities || hasDescription;
        })
        .toList()
      ..sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    if (ongoing.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "My Trips",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              Text(
                "${ongoing.length} active",
                style: const TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140, // Increased height for better padding
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: ongoing.length,
            itemBuilder: (context, index) {
              final trip = ongoing[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16, bottom: 10, top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.stroke.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItineraryDetailScreen(itinerary: trip),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_fix_high,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                trip.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ProgressStats.forTripCard(itinerary: trip),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1),
        ),
      ],
    );
  }

  // Updated options to point to _navigateToManualSetup
  Widget _buildPlanOptions() {
    final options = [
      PlanOption(
        icon: Icons.calendar_today_outlined,
        iconBgColor: const Color(0xFFE6F6EE),
        iconColor: AppColors.primary,
        title: 'Create detailed trip',
        subtitle: 'Set destination, dates, travelers, and budget manually.',
        onTap: _navigateToManualSetup,
      ),
      PlanOption(
        icon: Icons.auto_awesome,
        iconBgColor: const Color(0xFFE6F6EE),
        iconColor: AppColors.primary,
        title: 'Plan with AI',
        subtitle:
            'Tell us your vibe and constraints; get a tailored itinerary.',
        onTap: _navigateToAIPlan,
      ),
      if (widget.onNavigateToDiscover != null)
        PlanOption(
          icon: Icons.grid_view_rounded,
          iconBgColor: const Color(0xFFE6F6EE),
          iconColor: AppColors.primary,
          title: 'View tour packages',
          subtitle: 'Browse curated trips from trusted partners.',
          onTap: widget.onNavigateToDiscover!,
        ),
    ];

    return PlanOptionsGrid(options: options);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
 
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              Text(
                'Start a new trip',
                style: TextStyle(color: AppColors.subtext, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          // User avatar and notifications
          // _buildUserSection(),
        ],
      ),
    );
  }

  // Widget _buildUserSection() {
  //   return Row(
  //     children: [
  //       const CircleAvatar(
  //         radius: 18,
  //         backgroundImage: NetworkImage(
  //           'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=60',
  //         ),
  //       ),
  //       const SizedBox(width: 12),
  //       Container(
  //         height: 36,
  //         width: 36,
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           shape: BoxShape.circle,
  //           border: Border.all(color: AppColors.stroke),
  //         ),
  //         child: const Icon(
  //           Icons.notifications_outlined,
  //           size: 20,
  //           color: Color(0xFF606F81),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildTitleSection() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How would you like to plan?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
          ),
          SizedBox(height: 6),
          Text(
            'Choose an option to begin. You can switch methods anytime.',
            style: TextStyle(color: AppColors.subtext, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, color: AppColors.primary, size: 40),
          const SizedBox(height: 12),
          Text(
            'Sign in to start planning',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create an account or sign in to access all planning features.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to sign in screen
              // You can implement this based on your auth flow
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to sign in screen')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Sign In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToAIPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlanWithAIScreen()),
    );
  }
}
