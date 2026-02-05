import 'package:flutter/material.dart';
import 'package:tour_guide/features/destination/data/models/destination.dart';
import 'package:tour_guide/features/destination/data/services/destination_service.dart';
import 'package:tour_guide/features/explore/presentation/widgets/destination_card.dart';

class RecommendationsSection extends StatelessWidget {
  const RecommendationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Destination>>(
      // This calls the new endpoint we set up
      future: DestinationService.getRecommendations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // If no recommendations found (or guest with no popular items), hide section
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recommended for You",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to a full list if needed
                    },
                    child: const Text(
                      "See All",
                      style: TextStyle(color: Color(0xFF009688)),
                    ),
                  ),
                ],
              ),
            ),
            // Reusing your existing horizontal list widget!
            FeaturedList(destinations: snapshot.data!),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
