import 'package:flutter/material.dart';

class ParallaxHeader extends StatelessWidget {
  final String title;
  final bool isOwner;
  final bool isEditing;
  final VoidCallback onEditPressed;
  final VoidCallback onSettingsPressed;

  const ParallaxHeader({
    super.key,
    required this.title,
    required this.isOwner,
    required this.isEditing,
    required this.onEditPressed,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF009688),
      actions: [
        if (isOwner && !isEditing)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: onEditPressed,
          ),
        if (isOwner && !isEditing)
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: onSettingsPressed,
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        background: Image.network(
          "https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=800",
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}