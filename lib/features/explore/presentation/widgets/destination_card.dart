import 'package:flutter/material.dart';
import 'package:tour_guide/features/destination/data/models/destination.dart';
// import 'package:url_launcher/url_launcher.dart';
import '../screens/destination_detail_screen.dart';


class DestinationCard extends StatelessWidget {
  final Destination destination;
  final bool isGrid;

  const DestinationCard({
    super.key,
    required this.destination,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final String? imageUrl = destination.images.isNotEmpty ? destination.images[0] : null;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DestinationDetailScreen(destination: destination),
        ),
      ),
      child: Container(
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
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: imageUrl == null
                    ? Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey, size: 40),
                      )
                    : Image.network(imageUrl, fit: BoxFit.cover),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          destination.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF009688).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '\$${destination.cost.toInt()}/day',
                          style: const TextStyle(
                            color: Color(0xFF009688),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          destination.district ?? 'Location unavailable',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        destination.averageRating.toStringAsFixed(1) ?? '0.0',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
}




// class DestinationCard extends StatelessWidget {
//   const DestinationCard({
//     super.key,
//     required this.destination,
//     this.isGrid = false,
//   });

//   // final Destination destination;
//   final Destination destination;
//   final bool isGrid;

//   @override
//   Widget build(BuildContext context) {
//     final isMobile = MediaQuery.of(context).size.width < 600;
//     final String? imageUrl = destination.images.isNotEmpty ? destination.images[0] : null;

//     return InkWell(
//       onTap: () => Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => DestinationDetailScreen(destination: destination)),
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min, // Ensures card only takes needed space
//           children: [
//             // --- IMAGE SECTION ---
//             Expanded(
//               flex: 3,
//               child: Stack(
//                 children: [
//                   Positioned.fill(
//                     child: ClipRRect(
//                       borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
//                       child: Hero(
//                         tag: 'dest_image_${destination.id}',
//                         child: imageUrl == null 
//                           ? _buildPlaceholder() 
//                           : Image.network(imageUrl, fit: BoxFit.cover),
//                       ),
//                     ),
//                   ),
//                   // Price Badge on Image
//                   Positioned(
//                     top: 10,
//                     left: 10,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF009688),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Text(
//                         "\$${destination.cost.toInt()}/day",
//                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // --- INFO SECTION ---
//             Expanded(
//               flex: 2,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     Text(
//                       destination.name,
//                       style: TextStyle(
//                         fontSize: isMobile ? 15 : 17,
//                         fontWeight: FontWeight.w800, // Thicker font for premium feel
//                         color: Colors.black87,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     Row(
//                       children: [
//                         const Icon(Icons.location_on, size: 12, color: Colors.grey),
//                         const SizedBox(width: 4),
//                         Text(
//                           destination.district ?? "Location",
//                           style: const TextStyle(color: Colors.grey, fontSize: 11),
//                         ),
//                         const Spacer(),
//                         Icon(Icons.star, color: Colors.amber.shade700, size: 14),
//                         const SizedBox(width: 2),
//                         Text(
//                           destination.averageRating.toStringAsFixed(1),
//                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     _buildTagsRow(isMobile: isMobile),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Update _buildTagsRow to accept isMobile parameter
//   Widget _buildTagsRow({bool isMobile = false}) {
//     const int maxVisible = 2;
//     // Use destination.tags (object property)
//     final tags = destination.tags;
//     final visibleTags = tags.take(maxVisible).toList();
//     final remaining = tags.length - maxVisible;

//     return Wrap(
//       spacing: isMobile ? 2 : 4,
//       runSpacing: isMobile ? 2 : 4,
//       crossAxisAlignment: WrapCrossAlignment.center,
//       children: [
//         ...visibleTags.map((tag) => _buildTagBadge(tag, isMobile: isMobile)),
//         if (remaining > 0)
//           Text(
//             "+$remaining",
//             style: TextStyle(
//               color: Colors.grey[500],
//               fontSize: isMobile ? 8 : 10,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//       ],
//     );
//   }

//   // Update _buildTagBadge to accept isMobile parameter
//   Widget _buildTagBadge(String text, {bool isMobile = false}) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: isMobile ? 4 : 6,
//         vertical: isMobile ? 1 : 2,
//       ),
//       decoration: BoxDecoration(
//         color: const Color(0xFF009688).withOpacity(0.08),
//         borderRadius: BorderRadius.circular(isMobile ? 4 : 6),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           color: const Color(0xFF009688),
//           fontWeight: FontWeight.w600,
//           fontSize: isMobile ? 8 : 9,
//         ),
//       ),
//     );
//   }

//   // Widget _buildActionButton(IconData icon) {
//   //   return Container(
//   //     padding: const EdgeInsets.all(5),
//   //     decoration: BoxDecoration(
//   //       color: Colors.white.withOpacity(0.9),
//   //       shape: BoxShape.circle,
//   //     ),
//   //     child: Icon(icon, size: 16, color: Colors.black),
//   //   );
//   // }

//   Widget _buildPlaceholder() {
//     return Container(
//       color: Colors.grey[100],
//       child: const Icon(Icons.image_outlined, color: Colors.grey, size: 30),
//     );
//   }
// }

// // --- FEATURED LIST ---

// class FeaturedList extends StatefulWidget {
//   final List<Destination> destinations;

//   const FeaturedList({super.key, required this.destinations});

//   @override
//   State<FeaturedList> createState() => _FeaturedListState();
// }

// class _FeaturedListState extends State<FeaturedList> {
//   late PageController _pageController;
//   int _currentPage = 0;

//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController(viewportFraction: 0.85);
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.destinations.isEmpty) return const SizedBox.shrink();

//     return Column(
//       children: [
//         SizedBox(
//           height: 340, // Reduced height to fit comfortably
//           child: PageView.builder(
//             controller: _pageController,
//             onPageChanged: (index) => setState(() => _currentPage = index),
//             itemCount: widget.destinations.length,
//             itemBuilder: (context, index) {
//               return AnimatedScale(
//                 scale: _currentPage == index ? 1.0 : 0.9,
//                 duration: const Duration(milliseconds: 300),
//                 child: DestinationCard(destination: widget.destinations[index]),
//               );
//             },
//           ),
//         ),
//         const SizedBox(height: 12),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: List.generate(
//             widget.destinations.length,
//             (index) => AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               margin: const EdgeInsets.symmetric(horizontal: 4),
//               height: 6,
//               width: _currentPage == index ? 18 : 6,
//               decoration: BoxDecoration(
//                 color: _currentPage == index
//                     ? const Color(0xFF009688)
//                     : Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(3),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
