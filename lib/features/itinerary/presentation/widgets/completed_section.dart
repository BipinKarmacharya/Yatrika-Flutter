import 'package:flutter/material.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';

class CompletedSection extends StatelessWidget {
  final Itinerary currentTrip;
  final VoidCallback onShare;
  final VoidCallback onUnshare;

  const CompletedSection({
    super.key,
    required this.currentTrip,
    required this.onShare,
    required this.onUnshare,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPublic = currentTrip.isPublic;
    final bool isCopied = currentTrip.isCopied;

    return Column(
      children: [
        // Completion Badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                "JOURNEY COMPLETED",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Information card
        if (isCopied)
          _buildCopiedInfoCard()
        else if (isPublic)
          _buildPublicTripCard()
        else
          _buildShareableTripCard(),
      ],
    );
  }

  Widget _buildCopiedInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[800]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Copied Plan",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "This is a copy of another user's trip. Only original trips can be shared with the community.",
            style: TextStyle(fontSize: 14, color: Colors.orange[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicTripCard() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.public, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Public Trip",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "This trip is visible to other travelers on the Explore tab.",
                style: TextStyle(fontSize: 14, color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onUnshare,
          icon: const Icon(Icons.lock_outline, color: Colors.white),
          label: const Text(
            "MAKE PRIVATE",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareableTripCard() {
    return ElevatedButton.icon(
      onPressed: onShare,
      icon: const Icon(Icons.share, color: Colors.white),
      label: const Text(
        "SHARE TO COMMUNITY",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}