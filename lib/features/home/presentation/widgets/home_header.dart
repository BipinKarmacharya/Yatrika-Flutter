import 'package:flutter/material.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'top_bar.dart'; // Ensure your TopBar file is in the same folder

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // This calls your existing notification logic widget
          const TopBar(),
          
          const SizedBox(height: 24),
          
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