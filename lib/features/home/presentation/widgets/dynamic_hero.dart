import 'package:flutter/material.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_detail_screen.dart';

class DynamicHero extends StatelessWidget {
  final List<Itinerary> trips;
  final VoidCallback onPlanTap;
  final Function(int) onDismiss;

  const DynamicHero({
    super.key,
    required this.trips,
    required this.onPlanTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return _buildPlannerHero();
    }

    // If multiple trips, show a swipeable carousel
    return SizedBox(
      height: 185, // Fixed height for hero area
      child: PageView.builder(
        itemCount: trips.length,
        controller: PageController(
          viewportFraction: 0.92,
        ), // Shows edge of next card
        itemBuilder: (context, index) {
          final trip = trips[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C1E),
                borderRadius: BorderRadius.circular(24),
              ),
              child: _buildTripContent(context, trip),
            ),
          );
        },
      ),
    );
  }

  // --- State A: No active trip ---
  Widget _buildPlannerHero() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Plan your next escape",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Discover destinations and build itineraries with AI",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onPlanTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Start Planning"),
          ),
        ],
      ),
    );
  }

  // --- State B: Trip Content (Unified for Ongoing & Upcoming) ---
  Widget _buildTripContent(BuildContext context, Itinerary trip) {
    final total = trip.summary?.activityCount ?? 0;
    final completed = trip.summary?.completedActivities ?? 0;
    final double progress = total > 0 ? completed / total : 0.0;
    final bool isOngoing = trip.status == 'ONGOING';

    // Countdown Logic
    final now = DateTime.now();
    final difference = trip.startDate?.difference(now).inDays ?? 0;
    String statusText;

    if (isOngoing) {
      statusText = "CURRENT TRIP";
    } else {
      statusText = difference <= 0 ? "STARTS TOMORROW" : "IN $difference DAYS";
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ItineraryDetailScreen(itinerary: trip),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              // The Dismiss Button
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => onDismiss(trip.id), // Pass ID to provider
                icon: const Icon(Icons.close, color: Colors.white38, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            trip.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Progress Bar (Always useful to see how ready the plan is)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              color: AppColors.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOngoing
                    ? "$completed/$total Activities done"
                    : "$total Activities planned",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (isOngoing)
                Text(
                  "${(progress * 100).toInt()}%",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
