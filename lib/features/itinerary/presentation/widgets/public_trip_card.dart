import 'package:flutter/material.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_detail_screen.dart';

class PublicTripCard extends StatelessWidget {
  final Itinerary itinerary;

  const PublicTripCard({super.key, required this.itinerary});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItineraryDetailScreen(itinerary: itinerary),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageStack(),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 8),
                    _buildStatsRow(),
                    const SizedBox(height: 12),
                    _buildFooter(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageStack() {
    return Stack(
      children: [
        // Placeholder for a trip cover image
        Container(
          height: 140,
          width: double.infinity,
          color: Colors.grey.shade200,
          child: const Icon(Icons.map_outlined, size: 40, color: Colors.grey),
        ),
        if (itinerary.isAdminCreated)
          Positioned(
            top: 12,
            left: 12,
            child: _buildBadge("EXPERT", const Color(0xFF009688)),
          ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Text(
      itinerary.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          "${itinerary.totalDays ?? 0} Days",
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.star, size: 14, color: Colors.amber),
        const SizedBox(width: 4),
        Text(
          itinerary.averageRating?.toStringAsFixed(1) ?? "0.0",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Estimated",
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
            Text(
              "\$${itinerary.summary?.totalEstimatedBudget.toStringAsFixed(0) ?? '0'}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF009688),
                fontSize: 16,
              ),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () {
            // We will implement the Copy logic here later
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF009688),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text("Copy", style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
