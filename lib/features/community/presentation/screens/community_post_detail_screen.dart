import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/community/logic/community_provider.dart';
import '../../data/models/community_post.dart';


class CommunityPostDetailScreen extends StatelessWidget {
  final CommunityPost post;

  const CommunityPostDetailScreen({super.key, required this.post});

  // ✅ Cleaned up: Using the helper from our Model instead of a local function
  String _formatDate(String? dateStr) => post.formattedDate.isNotEmpty 
      ? post.formattedDate 
      : "Recently";

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true, 
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.3),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.7),
                child: const BackButton(color: Colors.black),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: post.media.isNotEmpty ? post.media.length : 1,
                    itemBuilder: (context, index) {
                      // ✅ Dynamically picking media or falling back to cover image
                      final url = post.media.isNotEmpty
                          ? post.media[index].mediaUrl
                          : post.coverImageUrl;
                      
                      return GestureDetector(
                        onTap: () => _showFullScreenImage(context, url),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                        ),
                      );
                    },
                  ),
                  // Simple Page Indicator (Optional)
                  if (post.media.length > 1)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(post.media.length, (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8, height: 8,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white70),
                        )),
                      ),
                    ),
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
                  // --- Author Section ---
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: post.authorAvatar != null 
                            ? CachedNetworkImageProvider(post.authorAvatar!) 
                            : null,
                        child: post.authorAvatar == null ? const Icon(Icons.person) : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            _formatDate(post.createdAt),
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Like Logic
                      Consumer<CommunityProvider>(
                        builder: (context, provider, child) {
                          return IconButton(
                            icon: Icon(
                              post.isLiked ? Icons.favorite : Icons.favorite_border,
                              color: post.isLiked ? Colors.red : Colors.black,
                            ),
                            onPressed: () => provider.toggleLike(post.id!),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Content Section ---
                  Text(
                    post.title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.content,
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                  ),

                  const SizedBox(height: 20),
                  // Tags
                  if (post.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: post.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text("#$tag", style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),

                  const SizedBox(height: 30),
                  
                  // --- Summary Card (No more hardcoded "Switzerland"!) ---
                  _buildTripSummaryCard(),
                  
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            Icons.location_on_rounded,
            "Destination",
            post.destination ?? "Not specified",
            Colors.redAccent,
          ),
          const Divider(height: 30),
          _buildSummaryRow(
            Icons.calendar_today_rounded,
            "Duration",
            "${post.tripDurationDays} Days",
            Colors.blueAccent,
          ),
          const Divider(height: 30),
          _buildSummaryRow(
            Icons.payments_outlined,
            "Estimated Cost",
            "Rs. ${post.estimatedCost.toStringAsFixed(0)}",
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
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
}