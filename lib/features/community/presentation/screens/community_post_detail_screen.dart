import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/community/logic/community_provider.dart';
import '../../data/models/community_post.dart';

class CommunityPostDetailScreen extends StatefulWidget {
  final CommunityPost post;

  const CommunityPostDetailScreen({super.key, required this.post});

  @override
  State<CommunityPostDetailScreen> createState() => _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateStr) => widget.post.formattedDate.isNotEmpty 
      ? widget.post.formattedDate 
      : "Recently";

  // ✅ Updated: Full Screen Swipeable Gallery
  void _showFullScreenGallery(BuildContext context, int initialIndex) {
    final mediaList = widget.post.media.isNotEmpty 
        ? widget.post.media.map((m) => m.mediaUrl).toList() 
        : [widget.post.coverImageUrl];

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: mediaList.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: mediaList[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaList = widget.post.media;
    final hasMultiple = mediaList.length > 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.8),
                child: const BackButton(color: Colors.black),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Image Slider
                  PageView.builder(
                    controller: _pageController,
                    itemCount: mediaList.isNotEmpty ? mediaList.length : 1,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final url = mediaList.isNotEmpty
                          ? mediaList[index].mediaUrl
                          : widget.post.coverImageUrl;
                      
                      return GestureDetector(
                        onTap: () => _showFullScreenGallery(context, index),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                        ),
                      );
                    },
                  ),

                  // 2. Top Shadow (Ensures buttons are visible)
                  const Positioned(
                    top: 0, left: 0, right: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black38, Colors.transparent],
                        ),
                      ),
                      child: SizedBox(height: 100),
                    ),
                  ),

                  // 3. Modern Animated Dots
                  if (hasMultiple)
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(mediaList.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentPage == index ? Colors.white : Colors.white54,
                            ),
                          );
                        }),
                      ),
                    ),

                  // 4. Glass-morphism Counter
                  if (hasMultiple)
                    Positioned(
                      bottom: 25,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          "${_currentPage + 1}/${mediaList.length}",
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAuthorHeader(),
                  const SizedBox(height: 24),
                  Text(
                    widget.post.title,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.post.content,
                    style: const TextStyle(fontSize: 16, height: 1.7, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  if (widget.post.tags.isNotEmpty) _buildTags(),
                  const SizedBox(height: 32),
                  _buildTripSummaryCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[200],
          backgroundImage: widget.post.authorAvatar != null 
              ? CachedNetworkImageProvider(widget.post.authorAvatar!) 
              : null,
          child: widget.post.authorAvatar == null ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.post.authorName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              _formatDate(widget.post.createdAt),
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
        const Spacer(),
        Consumer<CommunityProvider>(
          builder: (context, provider, _) => IconButton(
            onPressed: () => provider.toggleLike(widget.post.id!),
            icon: Icon(
              widget.post.isLiked ? Icons.favorite : Icons.favorite_border,
              color: widget.post.isLiked ? Colors.red : Colors.black,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.post.tags.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "#$tag",
          style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      )).toList(),
    );
  }

  Widget _buildTripSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildSummaryRow(Icons.location_on_rounded, "Destination", widget.post.destination ?? "Global", AppColors.primary),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
          _buildSummaryRow(Icons.calendar_today_rounded, "Duration", "${widget.post.tripDurationDays} Days", AppColors.primary),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
          _buildSummaryRow(Icons.payments_outlined, "Estimated Budget", "\$${widget.post.estimatedCost.toStringAsFixed(0)}.00", AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ],
    );
  }
}
