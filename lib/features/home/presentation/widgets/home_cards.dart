import 'package:flutter/material.dart';
import 'package:tour_guide/features/destination/data/models/destination.dart' as MD;
import 'package:tour_guide/features/community/data/models/community_post.dart' as CP;

class RecommendationCard extends StatelessWidget {
  final MD.Destination destination;
  const RecommendationCard({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    final imageUrl = destination.images.isNotEmpty ? destination.images.first : null;
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (imageUrl != null)
                Image.network(imageUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover)
              else
                Container(color: Colors.grey[200], child: const Icon(Icons.photo_outlined, size: 40)),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(destination.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(destination.district ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommunityCard extends StatelessWidget {
  final CP.CommunityPost post;
  const CommunityCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.image)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text("by ${post.authorName}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}