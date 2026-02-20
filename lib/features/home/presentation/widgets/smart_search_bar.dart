import 'package:flutter/material.dart';
import 'package:tour_guide/core/theme/app_colors.dart';

class SmartSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isProcessing;
  final Function(String) onSubmitted;

  const SmartSearchBar({
    super.key,
    required this.controller,
    required this.isProcessing,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: "Try 'Plan a 2 day trek in Mustang'",
          hintStyle: const TextStyle(color: AppColors.subtext, fontSize: 14),
          prefixIcon: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
          suffixIcon: isProcessing
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: () => onSubmitted(controller.text),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}