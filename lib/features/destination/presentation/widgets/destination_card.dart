import 'package:flutter/material.dart';
import 'package:tour_guide/features/destination/data/models/destination.dart';
import 'package:url_launcher/url_launcher.dart';
// 1. Import your detail screen
import '../screens/destination_detail_screen.dart';

class DestinationCard extends StatelessWidget {
  const DestinationCard({super.key, required this.destination});

  final Destination destination;

  // Re-integrated: We will call this from a long press or a specific button
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
    final String? imageUrl = destination.images.isNotEmpty ? destination.images[0] : null;

    return InkWell(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => DestinationDetailScreen(destination: destination))
      ),
      // Added long press to trigger the map since the button is gone in this style
      onLongPress: _openMap, 
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'dest_image_${destination.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: imageUrl == null 
                      ? _buildPlaceholder(Icons.image) 
                      : Image.network(
                          imageUrl, 
                          height: 220, 
                          width: double.infinity, 
                          fit: BoxFit.cover, 
                          headers: const {"ngrok-skip-browser-warning": "true"}
                        ),
                  ),
                ),
                Positioned(
                  top: 15, 
                  right: 15, 
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.9), 
                    radius: 18, 
                    child: const Icon(Icons.bookmark_border, size: 20, color: Colors.black)
                  )
                ),
                Positioned(
                  bottom: 20, 
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.name, 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          // shadows: [Shadow(blurRadius: 10, color: Colors.black)]
                        )
                      ),
                      Text(
                        destination.district ?? "Location", 
                        style: const TextStyle(color: Colors.white70, fontSize: 16)
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.shortDescription, 
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.teal[700], size: 18),
                      // Fixed the string interpolation here (was a space between $ and {)
                      Text(" ~\$${destination.cost.toInt()}/day", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 15),
                      Icon(Icons.star, color: Colors.amber[700], size: 18),
                      Text(" ${destination.averageRating} Rating"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: destination.tags.take(3).map((tag) => _buildTagBadge(tag, Colors.teal)).toList(),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ONLY KEEP THE HELPERS YOU ACTUALLY USE
  Widget _buildPlaceholder(IconData icon) {
    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.grey[200],
      child: Icon(icon, color: Colors.grey, size: 40),
    );
  }

  Widget _buildTagBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}

// Keep FeaturedList for home screen carousel

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
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Increased height from 320 to 420 to prevent overflow
        SizedBox(
          height: 380,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.destinations.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: DestinationCard(destination: widget.destinations[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.destinations.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
