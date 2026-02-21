import 'package:flutter/material.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
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
    super.key,
    required this.visitedCount,
    required this.totalCount,
    this.title,
    this.color = AppColors.primary,
    this.height = 8.0,
    this.showTitle = false,
    this.showPercentage = true,
    this.showCountText = true,
    this.borderRadius,
  });

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
      color: AppColors.primary,
      height: 8.0,
      showTitle: true,
      showPercentage: true,
      showCountText: true,
      borderRadius: BorderRadius.circular(10), // Added a slight radius for better looks
    );
  }

  factory ProgressStats.forTripCard({required Itinerary itinerary}) {
    return ProgressStats(
      visitedCount: itinerary.summary?.completedActivities ?? 0,
      totalCount: itinerary.summary?.activityCount ?? 0,
      title: null,
      color: AppColors.primary,
      height: 6.0,
      showTitle: false,
      showPercentage: false,
      showCountText: true,
      borderRadius: BorderRadius.circular(10),
    );
  }

  double get targetProgress => totalCount > 0 ? visitedCount / totalCount : 0.0;

  @override
  Widget build(BuildContext context) {
    final bool isFinished = targetProgress == 1.0 && totalCount > 0;

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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                // Celebration Icon if finished
                if (isFinished)
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              ],
            ),
          ),
          
        // The Animated Progress Bar
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: targetProgress),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: borderRadius ?? BorderRadius.zero,
                  child: LinearProgressIndicator(
                    value: animatedValue, // Use the animated value here!
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFinished ? AppColors.primary : color,
                    ),
                    minHeight: height,
                  ),
                ),
                if (showPercentage || showCountText) const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (showCountText)
                      Text(
                        "$visitedCount of $totalCount activities visited",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    if (showPercentage)
                      Text(
                        "${(animatedValue * 100).toInt()}%",
                        style: TextStyle(
                          color: isFinished ? AppColors.primary : color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}