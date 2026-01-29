import 'package:flutter/material.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';

class ProgressStats extends StatelessWidget {
  final List<ItineraryItem> items;
  final bool isOwner;

  const ProgressStats({
    super.key,
    required this.items,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty || !isOwner) return const SizedBox.shrink();
    
    int visited = items.where((i) => i.isVisited).length;
    double progress = visited / items.length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Trip Progress",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "${(progress * 100).toInt()}%",
              style: const TextStyle(
                color: Color(0xFF009688),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          color: const Color(0xFF009688),
          minHeight: 8,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}