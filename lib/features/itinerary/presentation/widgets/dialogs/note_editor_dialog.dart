import 'package:flutter/material.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';

class NoteEditorDialog extends StatefulWidget {
  final ItineraryItem item;
  final Function(String) onUpdate;

  const NoteEditorDialog({
    super.key,
    required this.item,
    required this.onUpdate,
  });

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.item.notes);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Notes for ${widget.item.destination?['name'] ?? widget.item.title}"),
      content: TextField(
        controller: _noteController,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: "What are the plans here?",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onUpdate(_noteController.text);
            Navigator.pop(context);
          },
          child: const Text("Update"),
        ),
      ],
    );
  }
}