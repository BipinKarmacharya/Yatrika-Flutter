import 'package:flutter/material.dart';

class EditAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onClose;
  final VoidCallback onAddPhotos;
  final VoidCallback onSave;

  const EditAppBar({
    super.key,
    required this.onClose,
    required this.onAddPhotos,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Edit Schedule"),
      backgroundColor: const Color(0xFF009688),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onClose,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_a_photo_outlined),
          onPressed: onAddPhotos,
          tooltip: "Add Photos",
        ),
        TextButton(
          onPressed: onSave,
          child: const Text("DONE", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}