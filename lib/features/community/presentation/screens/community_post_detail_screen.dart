import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/community_post.dart';

class CommunityPostDetailScreen extends StatelessWidget {
  final CommunityPost post;

  const CommunityPostDetailScreen({super.key, required this.post});

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "https://via.placeholder.com/600x400";
    return path.startsWith('http') ? path : '${ApiClient.baseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. Image Carousel Header
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            leading: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.5),
              child: const BackButton(color: Colors.black),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: post.media.isNotEmpty ? post.media.length : 1,
                    itemBuilder: (context, index) {
                      final url = post.media.isNotEmpty 
                          ? post.media[index].mediaUrl 
                          : post.coverImageUrl;
                      return CachedNetworkImage(
                        imageUrl: _getImageUrl(url),
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  // Pagination dots could be added here
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Author and Actions
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(_getImageUrl(post.user?.profileImage)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(post.createdAt?.substring(0, 10) ?? "Recently", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.favorite_border),
                      const SizedBox(width: 15),
                      const Icon(Icons.bookmark_border, color: Colors.green),
                      const SizedBox(width: 15),
                      const Icon(Icons.share_outlined),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Title and Content
                  Text(post.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(post.content, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
                  
                  const SizedBox(height: 20),
                  // Tags
                  Wrap(
                    spacing: 8,
                    children: post.tags.map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.grey[100],
                      side: BorderSide.none,
                    )).toList(),
                  ),

                  const SizedBox(height: 30),
                  const Text("Itinerary", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  // 4. Itinerary Days
                  ...post.days.map((day) => _buildDayCard(day)),

                  const SizedBox(height: 30),
                  // 5. Trip Summary Card
                  _buildTripSummaryCard(),

                  const SizedBox(height: 40),
                  // 6. ACTION BUTTON: "Use This Plan"
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => _handleUsePlan(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Use This Plan", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(PostDay day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.green,
                child: Text("${day.dayNumber}", style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Text(day.description.split(':').first, // Assuming "Arrival: text" format
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Text(day.description, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          // Activities as bullets
          ...day.activities.split(',').map((activity) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 6, color: Colors.green),
                const SizedBox(width: 8),
                Text(activity.trim()),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTripSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildSummaryRow(Icons.location_on_outlined, "Destination", post.destination ?? "Switzerland"),
          const Divider(height: 30),
          _buildSummaryRow(Icons.calendar_today, "Duration", "${post.tripDurationDays} days"),
          const Divider(height: 30),
          _buildSummaryRow(Icons.attach_money, "Total Budget", "${post.estimatedCost} USD"),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ],
    );
  }

  void _handleUsePlan(BuildContext context) {
    // This is where you would call your TripProvider to "Clone" this itinerary 
    // to the user's private trips.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Plan copied to your trips! You can now edit it.")),
    );
  }
}