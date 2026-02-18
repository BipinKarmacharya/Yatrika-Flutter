import 'package:flutter/material.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';

class IncompleteHint extends StatelessWidget {
  final List<ItineraryItem> items;

  const IncompleteHint({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final totalNeeded = (items.length * 0.8).ceil();
    final visited = items.where((i) => i.isVisited == true).length;
    final remaining = totalNeeded - visited;

    if (remaining <= 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          "Almost there! Just click finish to complete your journey.",
          style: TextStyle(
            color: Color(0xFF009688),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        "Visit $remaining more stops to mark this trip as finished!",
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}