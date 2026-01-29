import 'package:flutter/material.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';

class ProgressStats extends StatelessWidget {
  final int visitedCount;
  final int totalCount;
  final String? title;
  final Color color;
  final double height;
  final bool showTitle;
  final bool showPercentage;
  final bool showCountText;
  final BorderRadiusGeometry? borderRadius;

  const ProgressStats({
    Key? key,
    required this.visitedCount,
    required this.totalCount,
    this.title,
    this.color = const Color(0xFF009688),
    this.height = 8.0,
    this.showTitle = false,
    this.showPercentage = true,
    this.showCountText = true,
    this.borderRadius,
  }) : super(key: key);

  factory ProgressStats.forDetailScreen({
    required List<ItineraryItem> items,
    String title = "Trip Progress",
  }) {
    final visitedCount = items.where((item) => item.isVisited).length;
    final totalCount = items.length;

    return ProgressStats(
      visitedCount: visitedCount,
      totalCount: totalCount,
      title: title,
      color: const Color(0xFF009688),
      height: 8.0,
      showTitle: true,
      showPercentage: true,
      showCountText: true,
      borderRadius: null,
    );
  }

  factory ProgressStats.forTripCard({required Itinerary itinerary}) {
    return ProgressStats(
      visitedCount: itinerary.summary?.completedActivities ?? 0,
      totalCount: itinerary.summary?.activityCount ?? 0,
      title: null,
      color: const Color(0xFF10B981),
      height: 6.0,
      showTitle: false,
      showPercentage: false,
      showCountText: true,
      borderRadius: BorderRadius.circular(10),
    );
  }

  double get progress => totalCount > 0 ? visitedCount / totalCount : 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle && title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (showPercentage)
                  Text(
                    "${(progress * 100).toInt()}%",
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: height,
          ),
        ),
        if (showCountText) ...[
          const SizedBox(height: 4),
          Text(
            "$visitedCount of $totalCount activities visited",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}
