import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/community/logic/community_provider.dart';
import '../../../../core/api/api_client.dart';
import '../../data/models/community_post.dart';
import '../screens/community_post_detail_screen.dart';
import 'package:intl/intl.dart';

class CommunityPostFeedCard extends StatefulWidget {
  final CommunityPost post;
  const CommunityPostFeedCard({super.key, required this.post});

  @override
  State<CommunityPostFeedCard> createState() => _CommunityPostFeedCardState();
}

class _CommunityPostFeedCardState extends State<CommunityPostFeedCard> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return "https://via.placeholder.com/400x300";
    }
    if (path.startsWith('http')) return path;
    return '${ApiClient.baseUrl}$path';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";

    try {
      // 1. Parse the string (e.g., "2026-01-25") into a DateTime object
      DateTime dateTime = DateTime.parse(dateStr);

      // 2. Format it to "MMM d" (e.g., Jan 25)
      return DateFormat('MMM d').format(dateTime);
    } catch (e) {
      return ""; // Return empty or a default value if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayList = widget.post.media.isNotEmpty
        ? widget.post.media.map((m) => m.mediaUrl).toList()
        : [widget.post.coverImageUrl];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityPostDetailScreen(post: widget.post),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          // Partitioning: Subtle border to define the card shape against white images
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Section ---
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: 260,
                    width: double.infinity,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: displayList.length,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemBuilder: (ctx, i) => CachedNetworkImage(
                        imageUrl: _getImageUrl(displayList[i]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                // Price Tag (Top Right)
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "\$ ${widget.post.estimatedCost.toStringAsFixed(0)} USD",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
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
                  // Author Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: CachedNetworkImageProvider(
                          _getImageUrl(widget.post.user?.profileImage),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    widget.post.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Location & Duration
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.post.destination ?? "Unknown",
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${widget.post.tripDurationDays} days",
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Snippet
                  Text(
                    widget.post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      height: 1.4,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tags (Chips)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...widget.post.tags.take(3).map((tag) => _buildTag(tag)),
                      if (widget.post.tags.length > 3)
                        _buildTag("+${widget.post.tags.length - 3}"),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Action Bar
                  Row(
                    children: [
                      _buildActionItem(
                        icon: widget.post.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: "${widget.post.totalLikes}",
                        color: widget.post.isLiked
                            ? Colors.red
                            : Colors.black87,
                        onTap: () => context
                            .read<CommunityProvider>()
                            .toggleLike(widget.post.id!),
                      ),
                      const SizedBox(width: 20),
                      const Icon(
                        Icons.bookmark_border,
                        size: 22,
                        color: Colors.black87,
                      ),
                      const Spacer(),

                      // DYNAMIC DATE
                      Text(
                        _formatDate(widget.post.createdAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9F6), // Very light green/teal
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF047857),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
