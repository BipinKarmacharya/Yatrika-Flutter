import 'package:flutter/material.dart';
import 'package:tour_guide/core/theme/app_colors.dart';

class AddActivityFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const AddActivityFAB({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add_location_alt, color: Colors.white),
      label: const Text("Add Activity", style: TextStyle(color: Colors.white)),
    );
  }
}