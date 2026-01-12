import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'plan_with_ai_screen.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, this.onBack, this.onNavigateToDiscover});

  final VoidCallback? onBack;
  final VoidCallback? onNavigateToDiscover;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _datesController = TextEditingController();
  final TextEditingController _travelersController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  @override
  void dispose() {
    _destinationController.dispose();
    _datesController.dispose();
    _travelersController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onBack,
                      child: const Row(
                        children: [
                          Icon(Icons.chevron_left, color: AppColors.text, size: 24),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                            ),
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
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Start a new trip',
                          style: TextStyle(
                            color: AppColors.subtext,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
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
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How would you like to plan?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Choose an option to begin. You can switch methods anytime.',
                      style: TextStyle(
                        color: AppColors.subtext,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Option cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _PlanOptionCard(
                      icon: Icons.calendar_today_outlined,
                      iconBgColor: const Color(0xFFE6F6EE),
                      iconColor: AppColors.primary,
                      title: 'Create trip',
                      subtitle: 'Set destination, dates, travelers, and budget manually.',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _PlanOptionCard(
                      icon: Icons.auto_awesome,
                      iconBgColor: const Color(0xFFE6F6EE),
                      iconColor: AppColors.primary,
                      title: 'Plan with AI',
                      subtitle: 'Tell us your vibe and constraints; get a tailored itinerary.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PlanWithAIScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _PlanOptionCard(
                      icon: Icons.grid_view_rounded,
                      iconBgColor: const Color(0xFFE6F6EE),
                      iconColor: AppColors.primary,
                      title: 'View tour packages',
                      subtitle: 'Browse curated trips from trusted partners.',
                      onTap: () {
                        if (widget.onNavigateToDiscover != null) {
                          widget.onNavigateToDiscover!();
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick start section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick start',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Fill basics and jump right in. You can edit later.',
                      style: TextStyle(
                        color: AppColors.subtext,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Input fields grid
                    Row(
                      children: [
                        Expanded(
                          child: _QuickStartField(
                            controller: _destinationController,
                            hint: 'Destination',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickStartField(
                            controller: _datesController,
                            hint: 'Dates',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickStartField(
                            controller: _travelersController,
                            hint: 'Travelers',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickStartField(
                            controller: _budgetController,
                            hint: 'Budget',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PlanWithAIScreen(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Use AI instead',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Start trip',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tip text
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Tip: You can add flights, stays, and activities after creating your trip.',
                  style: TextStyle(
                    color: AppColors.subtext,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanOptionCard extends StatelessWidget {
  const _PlanOptionCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.subtext,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.subtext,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStartField extends StatelessWidget {
  const _QuickStartField({
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.subtext,
              fontSize: 14,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
