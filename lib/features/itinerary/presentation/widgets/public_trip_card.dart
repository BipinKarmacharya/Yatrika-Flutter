import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/auth/logic/auth_provider.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/data/services/itinerary_service.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
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
        _buildPriceInfo(), // This is the method we are defining below
        Consumer<ItineraryProvider>(
          builder: (context, itineraryProvider, child) {
            final bool isAlreadyCopied = itineraryProvider.myPlans.any(
              (p) => p.sourceId == itinerary.id,
            );

            return ElevatedButton(
              onPressed: isAlreadyCopied
                  ? () => _navigateToExistingCopy(
                      context,
                      itineraryProvider,
                      itinerary.id,
                    )
                  : () => _handleCopy(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAlreadyCopied
                    ? Colors.grey.shade200
                    : const Color(0xFF009688),
                foregroundColor: isAlreadyCopied
                    ? Colors.grey.shade700
                    : Colors.white,
                elevation: isAlreadyCopied ? 0 : 2,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isAlreadyCopied ? "View Plan" : "Copy",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Extracted Price Info Widget
  Widget _buildPriceInfo() {
    return Column(
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
    );
  }

  void _handleCopy(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final itineraryProvider = Provider.of<ItineraryProvider>(
      context,
      listen: false,
    );

    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please sign in to save trips"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Use the provider instead of the service directly
      // This assumes you add a 'copyTrip' method to your provider
      final newCopy = await itineraryProvider.copyTrip(itinerary.id);

      if (context.mounted && newCopy != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Trip saved! You can now customize it."),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItineraryDetailScreen(itinerary: newCopy),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToExistingCopy(
    BuildContext context,
    ItineraryProvider provider,
    int originalId,
  ) {
    final existingItinerary = provider.myPlans.firstWhere(
      (p) => p.sourceId == originalId,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ItineraryDetailScreen(itinerary: existingItinerary),
      ),
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
