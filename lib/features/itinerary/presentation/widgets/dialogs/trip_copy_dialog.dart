import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';

class TripCopyDialog extends StatefulWidget {
  final String title;
  const TripCopyDialog({super.key, required this.title});

  @override
  State<TripCopyDialog> createState() => _TripCopyDialogState();
}

class _TripCopyDialogState extends State<TripCopyDialog> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Copy: ${widget.title}", style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Choose a start date to automatically schedule activities, or keep it flexible."),
          const SizedBox(height: 20),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.teal),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null 
                        ? "Pick a Start Date" 
                        : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                    style: TextStyle(
                      color: _selectedDate == null ? Colors.grey : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedDate != null)
            TextButton(
              onPressed: () => setState(() => _selectedDate = null),
              child: const Text("Clear date (Make it Flexible)"),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text("CANCEL")
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, _selectedDate ?? "flexible"),
          child: const Text("COPY PLAN"),
        ),
      ],
    );
  }
}

class TripCopyHelper {
  static Future<void> showCopyWorkflow(BuildContext context, Itinerary itinerary) async {
    final result = await showDialog(
      context: context,
      builder: (context) => TripCopyDialog(title: itinerary.title),
    );

    if (result == null) return; // User cancelled

    DateTime? startDate = result is DateTime ? result : null;
    
    final provider = context.read<ItineraryProvider>();
    final newTrip = await provider.copyTrip(itinerary.id, startDate: startDate);

    if (newTrip != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Successfully copied to My Plans!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}