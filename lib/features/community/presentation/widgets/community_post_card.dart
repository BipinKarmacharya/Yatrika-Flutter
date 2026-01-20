import 'package:flutter/material.dart';

class CommunityPostData {
  const CommunityPostData({
    required this.title,
    required this.author,
    required this.authorImageUrl,
    required this.likes,
    required this.location,
    required this.duration,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.date,
    required this.tags,
  });

  final String title;
  final String author;
  final String authorImageUrl;
  final int likes;
  final String location;
  final String duration;
  final String description;
  final String price;
  final String imageUrl;
  final String date;
  final List<String> tags;
}

class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({super.key, required this.post});

  final CommunityPostData post;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top Image Section ---
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  post.imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // Price Tag Overlay
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    post.price,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              // Pagination Dots (Visual only)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == 0 ? 8 : 6,
                    height: index == 0 ? 8 : 6,
                    decoration: BoxDecoration(
                      color: index == 0 ? Colors.white : Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  )),
                ),
              ),
            ],
          ),

          // --- Content Section ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author Row
                Row(
                  children: [
                    CircleAvatar(radius: 14, backgroundImage: NetworkImage(post.authorImageUrl)),
                    const SizedBox(width: 8),
                    Text(
                      post.author,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  post.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 8),
                // Location & Duration Row
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(post.location, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(post.duration, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),
                // Description
                Text(
                  post.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 16),
                // Tags Row
                Row(
                  children: [
                    ...post.tags.take(3).map((tag) => _buildTag(tag)),
                    _buildTag("+1", isCounter: true),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // Footer Row (Likes, Bookmark, Date)
                Row(
                  children: [
                    const Icon(Icons.favorite_border, size: 20, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text('${post.likes}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 20),
                    const Icon(Icons.bookmark, size: 20, color: Color(0xFF10B981)), // Teal color
                    const Spacer(),
                    Text(post.date, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, {bool isCounter = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCounter ? Colors.white : const Color(0xFFF3F4F6),
        border: isCounter ? Border.all(color: const Color(0xFFF3F4F6)) : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
      ),
    );
  }
}