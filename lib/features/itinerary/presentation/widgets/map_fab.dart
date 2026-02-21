import 'package:flutter/material.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_map_screen.dart';

class MapFAB extends StatelessWidget {
  final List<ItineraryItem> dailyItems;

  const MapFAB({super.key, required this.dailyItems});

  @override
  Widget build(BuildContext context) {
    final validActivities = dailyItems
        .where(
          (item) =>
              item.destination != null &&
              item.destination!['latitude'] != null &&
              item.destination!['longitude'] != null,
        )
        .map((item) => item.toJson())
        .toList();

    return FloatingActionButton.extended(
      heroTag: 'view_map_fab',
      onPressed: validActivities.isEmpty
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No GPS coordinates found for today."),
                ),
              );
            }
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItineraryMapScreen(activities: validActivities),
              ),
            ),
      backgroundColor: validActivities.isEmpty
          ? Colors.grey
          : AppColors.primary,
      label: const Text("Show Route", style: TextStyle(color: Colors.white)),
      icon: const Icon(Icons.directions_outlined, color: Colors.white),
    );
  }
}