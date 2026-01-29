import 'package:flutter/material.dart';

class EditTripDialog extends StatefulWidget {
  final String initialTitle;
  final String? initialDescription;
  final Function(String, String) onSave;

  const EditTripDialog({
    super.key,
    required this.initialTitle,
    required this.initialDescription,
    required this.onSave,
  });

  @override
  State<EditTripDialog> createState() => _EditTripDialogState();
}

class _EditTripDialogState extends State<EditTripDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descController = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Trip Details"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Trip Title"),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: "Description"),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_titleController.text, _descController.text);
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}