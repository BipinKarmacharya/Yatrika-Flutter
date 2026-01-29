import 'package:flutter/material.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';

class QuickStats extends StatelessWidget {
  final Itinerary itinerary;

  const QuickStats({super.key, required this.itinerary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statTile(
            Icons.payments_outlined,
            "\$${itinerary.estimatedBudget?.toInt() ?? 0}",
            "Budget",
          ),
          _divider(),
          _statTile(
            Icons.star_rounded,
            "${itinerary.averageRating ?? 'N/A'}",
            "Rating",
          ),
          _divider(),
          _statTile(
            Icons.access_time,
            "${itinerary.totalDays ?? 1} Days",
            "Duration",
          ),
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF009688)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _divider() => Container(height: 30, width: 1, color: Colors.grey[300]);
}