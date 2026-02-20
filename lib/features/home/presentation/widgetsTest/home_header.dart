import 'package:flutter/material.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import '../widgets/top_bar.dart'; // Import your notification-aware TopBar

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. The Notification & Location Row (Your TopBar)
          const TopBar(),
          
          const SizedBox(height: 20),

          // 2. The Personalized Greeting
          Text(
            _getGreeting(),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.subtext,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          
          const SizedBox(height: 4),

          // 3. The Catchy Title
          const Text(
            "Where do you want\nto go today?",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}