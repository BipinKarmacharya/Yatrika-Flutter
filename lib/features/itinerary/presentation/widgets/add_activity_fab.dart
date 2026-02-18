import 'package:flutter/material.dart';

class AddActivityFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const AddActivityFAB({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: const Color(0xFF009688),
      icon: const Icon(Icons.add_location_alt, color: Colors.white),
      label: const Text("Add Activity", style: TextStyle(color: Colors.white)),
    );
  }
}