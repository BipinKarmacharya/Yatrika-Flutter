import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add this package
import 'package:provider/provider.dart';
import 'package:tour_guide/features/community/logic/community_provider.dart';
import '../../../../core/api/api_client.dart';
import '../../data/models/community_post.dart';
import '../screens/community_post_detail_screen.dart';

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
      return "https://via.placeholder.com/400x200";
    }
    if (path.startsWith('http')) return path;
    return '${ApiClient.baseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we use the media list or just the cover image
    final hasMultipleImages = widget.post.media.length > 1;
    final displayList = widget.post.media.isNotEmpty
        ? widget.post.media.map((m) => m.mediaUrl).toList()
        : [widget.post.coverImageUrl];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityPostDetailScreen(post: widget.post),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            // --- Image Section ---
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SizedBox(
                    height: 240,
                    width: double.infinity,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: displayList.length,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemBuilder: (context, index) => CachedNetworkImage(
                        imageUrl: _getImageUrl(displayList[index]),
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),

                // Multi-image Indicator (e.g., 1/3)
                if (hasMultipleImages)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${_currentPage + 1}/${displayList.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Price Tag
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "\$${widget.post.estimatedCost.toStringAsFixed(0)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Bottom Dots for multiple images
                if (hasMultipleImages)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        displayList.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentPage == index ? 10 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // --- Text Content Section ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: CachedNetworkImageProvider(
                          _getImageUrl(
                            widget.post.user?.profileImage ??
                                widget.post.authorAvatar,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("${widget.post.tripDurationDays} days", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(width: 12),
                      const Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("${widget.post.totalViews} views", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.4, color: Colors.black87),
                  ),
                  
                  // --- ADDED ACTION BAR HERE ---
                  const Divider(height: 24),
                  Row(
                    children: [
                      // Like Button
                      GestureDetector(
                        onTap: () {
                          if (widget.post.id != null) {
                            context.read<CommunityProvider>().toggleLike(widget.post.id!);
                          }
                        },
                        child: Row(
                          children: [
                            Icon(
                              widget.post.isLiked ? Icons.favorite : Icons.favorite_border,
                              color: widget.post.isLiked ? Colors.red : Colors.grey,
                              size: 22,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${widget.post.totalLikes}",
                              style: TextStyle(
                                color: widget.post.isLiked ? Colors.red : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Share button (visual only for now)
                      const Icon(Icons.share_outlined, size: 20, color: Colors.grey),
                      const Spacer(),
                      // Bookmark button (visual only for now)
                      const Icon(Icons.bookmark_border, size: 22, color: Colors.grey),
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
}
