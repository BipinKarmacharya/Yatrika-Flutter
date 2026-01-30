import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/auth/logic/auth_provider.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/plan_screen/plan_screen_controller.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/plan_screen/widgets/manual_trip_bottom_sheet.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/plan_screen/widgets/plan_options_grid.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/plan_screen/widgets/quick_start_section.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/plan_with_ai_screen.dart';

class PlanScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToDiscover;

  const PlanScreen({super.key, this.onBack, this.onNavigateToDiscover});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  late PlanScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PlanScreenController(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recreate controller with new context
    _controller = PlanScreenController(context);
  }

  void _showManualCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManualTripBottomSheet(
        controller: _controller,
        onTripCreated: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip created successfully!')),
          );
        },
      ),
    );
  }

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
              // Header
              _buildHeader(),
              const SizedBox(height: 24),

              // Title Section
              _buildTitleSection(),
              const SizedBox(height: 20),

              // Plan Options (only for logged-in users)
              if (isLoggedIn) ...[
                _buildPlanOptions(),
                const SizedBox(height: 24),

                // Quick Start Section
                QuickStartSection(
                  destinationController: _controller.destinationController,
                  onUseAI: () => _navigateToAIPlan(),
                  onStartTrip: () => _onQuickStart(),
                  onPickDestination: () => _onPickDestination(),
                ),
                const SizedBox(height: 16),
              ],

              // Guest Message (for non-logged-in users)
              if (!isLoggedIn) ...[
                _buildGuestMessage(),
                const SizedBox(height: 20),
              ],

              // Tip text
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Tip: You can add flights, stays, and activities after creating your trip.',
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

  void _onPickDestination() {
    // Show destination picker dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Destination'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDestinationTile('Paris, France'),
              _buildDestinationTile('Tokyo, Japan'),
              _buildDestinationTile('Bali, Indonesia'),
              _buildDestinationTile('New York, USA'),
              _buildDestinationTile('Rome, Italy'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationTile(String destination) {
    return ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text(destination),
      onTap: () {
        Navigator.pop(context);
        _controller.destinationController.text = destination;
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          if (widget.onBack != null)
            GestureDetector(
              onTap: widget.onBack,
              child: const Row(
                children: [
                  Icon(Icons.chevron_left, color: AppColors.text, size: 24),
                  Text(
                    'Back',
                    style: TextStyle(color: AppColors.text, fontSize: 16),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 16),
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
          _buildUserSection(),
        ],
      ),
    );
  }

  Widget _buildUserSection() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundImage: NetworkImage(
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=60',
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.stroke),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            size: 20,
            color: Color(0xFF606F81),
          ),
        ),
      ],
    );
  }

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

  Widget _buildPlanOptions() {
    final options = [
      PlanOption(
        icon: Icons.calendar_today_outlined,
        iconBgColor: const Color(0xFFE6F6EE),
        iconColor: AppColors.primary,
        title: 'Create detailed trip',
        subtitle: 'Set destination, dates, travelers, and budget manually.',
        onTap: _showManualCreateSheet,
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
    ].where((option) => option != null).cast<PlanOption>().toList();

    return PlanOptionsGrid(options: options);
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

  Future<void> _onQuickStart() async {
    await _controller.createQuickTrip(
      destination: _controller.destinationController.text,
    );
    _controller.destinationController.clear();
  }
}