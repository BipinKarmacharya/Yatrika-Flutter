import 'package:flutter/material.dart';
import 'package:tour_guide/features/destination/data/models/destination.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/destination_detail_screen.dart';

class DestinationCard extends StatelessWidget {
  const DestinationCard({
    super.key,
    required this.destination,
    this.isGrid = false,
  });

  // final Destination destination;
  final Destination destination;
  final bool isGrid;

  // Fix: Fixed the Google Maps URL template string
  Future<void> _openMap() async {
    if (destination.lat != null && destination.lng != null) {
      final Uri url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=${destination.lat},${destination.lng}",
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    // Access via destination.images (object property, not map key)
    final String? imageUrl = destination.images.isNotEmpty
        ? destination.images[0]
        : null;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DestinationDetailScreen(destination: destination),
        ),
      ),
      onLongPress: _openMap,
      child: Container(
        margin: isGrid
            ? EdgeInsets.zero
            : EdgeInsets.symmetric(
                vertical: isMobile ? 8 : 10,
                horizontal: isMobile ? 12 : 16,
              ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: isMobile ? 6 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // IMAGE SECTION - Make responsive
            AspectRatio(
              aspectRatio: isGrid
                  ? (isMobile ? 1.3 : 1.4)
                  : (isMobile ? 1.8 : 2.0),
              child: Stack(
                children: [
                  Hero(
                    // Use destination.id (object property)
                    tag: 'dest_image_${destination.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: imageUrl == null
                          ? _buildPlaceholder()
                          : Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholder(),
                            ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: isMobile ? 6 : 8,
                    right: isMobile ? 6 : 8,
                    child: _buildActionButton(Icons.bookmark_border),
                  ),
                  Positioned(
                    bottom: isMobile ? 8 : 10,
                    left: isMobile ? 8 : 10,
                    right: isMobile ? 8 : 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Use destination.name (object property)
                        Text(
                          destination.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 12 : (isGrid ? 14 : 16),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Use destination.district (object property)
                        Text(
                          destination.district ?? "Location",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isMobile ? 9 : 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // DETAILS SECTION
            Padding(
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isGrid) ...[
                    // Use destination.shortDescription (object property)
                    Text(
                      destination.shortDescription,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isMobile ? 10 : 12,
                      ),
                      maxLines: isMobile ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: isMobile ? 12 : 14,
                          ),
                          SizedBox(width: isMobile ? 2 : 4),
                          // Use destination.averageRating (object property)
                          Text(
                            destination.averageRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 10 : 12,
                            ),
                          ),
                        ],
                      ),
                      // Use destination.cost (object property)
                      Text(
                        "\$${destination.cost.toInt()}/day",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF009688),
                          fontSize: isMobile ? 10 : 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  // TAGS SECTION - Use destination.tags (object property)
                  _buildTagsRow(isMobile: isMobile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update _buildTagsRow to accept isMobile parameter
  Widget _buildTagsRow({bool isMobile = false}) {
    const int maxVisible = 2;
    // Use destination.tags (object property)
    final tags = destination.tags;
    final visibleTags = tags.take(maxVisible).toList();
    final remaining = tags.length - maxVisible;

    return Wrap(
      spacing: isMobile ? 2 : 4,
      runSpacing: isMobile ? 2 : 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...visibleTags.map((tag) => _buildTagBadge(tag, isMobile: isMobile)),
        if (remaining > 0)
          Text(
            "+$remaining",
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: isMobile ? 8 : 10,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  // Update _buildTagBadge to accept isMobile parameter
  Widget _buildTagBadge(String text, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 4 : 6,
        vertical: isMobile ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF009688).withOpacity(0.08),
        borderRadius: BorderRadius.circular(isMobile ? 4 : 6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF009688),
          fontWeight: FontWeight.w600,
          fontSize: isMobile ? 8 : 9,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: Colors.black),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 30),
    );
  }
}

// --- FEATURED LIST ---

class FeaturedList extends StatefulWidget {
  final List<Destination> destinations;

  const FeaturedList({super.key, required this.destinations});

  @override
  State<FeaturedList> createState() => _FeaturedListState();
}

class _FeaturedListState extends State<FeaturedList> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.destinations.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 340, // Reduced height to fit comfortably
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.destinations.length,
            itemBuilder: (context, index) {
              return AnimatedScale(
                scale: _currentPage == index ? 1.0 : 0.9,
                duration: const Duration(milliseconds: 300),
                child: DestinationCard(destination: widget.destinations[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.destinations.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentPage == index ? 18 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFF009688)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
