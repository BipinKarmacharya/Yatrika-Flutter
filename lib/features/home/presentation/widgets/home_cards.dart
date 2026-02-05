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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: post.coverImageUrl.isNotEmpty
                ? Image.network(post.coverImageUrl, width: 85, height: 85, fit: BoxFit.cover)
                : Container(width: 85, height: 85, color: Colors.grey[200], child: const Icon(Icons.image)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    CircleAvatar(radius: 10, backgroundImage: NetworkImage(post.authorAvatar ?? 'https://via.placeholder.com/20')),
                    const SizedBox(width: 6),
                    Text("by ${post.authorName}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.favorite_border, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("${post.totalLikes}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}