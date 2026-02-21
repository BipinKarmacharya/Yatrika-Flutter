import 'package:flutter/material.dart';
import 'package:tour_guide/core/theme/app_colors.dart';

class FinishTripButton extends StatelessWidget {
  final VoidCallback onPressed;

  const FinishTripButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            "Reached the end of your adventure?",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text(
              "MARK TRIP AS FINISHED",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}