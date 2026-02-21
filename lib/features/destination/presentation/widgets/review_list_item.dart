import 'package:flutter/material.dart';
import 'package:tour_guide/features/destination/data/models/review_model.dart';

class ReviewListItem extends StatelessWidget {
  final Review review;

  const ReviewListItem({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage:
                    (review.user.profileImage != null &&
                        review.user.profileImage!.isNotEmpty)
                    ? NetworkImage(review.user.profileImage!)
                    : null,
                child:
                    (review.user.profileImage == null ||
                        review.user.profileImage!.isEmpty)
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.user.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "@${review.user.username}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
              ),
              _buildStarRating(review.rating),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: TextStyle(color: Colors.grey[800], height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            "Reviewed: ${review.visitedDate.toLocal().toString().split(' ')[0]}",
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 14,
        );
      }),
    );
  }
}
