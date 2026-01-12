// // lib/components/destination_card.dart
// import 'package:flutter/material.dart';
// import '../../../../core/theme/app_colors.dart';

// class DestinationCardData {
//   const DestinationCardData({
//     required this.title,
//     required this.subtitle,
//     required this.tag,
//     required this.tagColor,
//     required this.imageUrl,
//     required this.metaIcon,
//   });

//   final String title;
//   final String subtitle;
//   final String tag;
//   final Color tagColor;
//   final String imageUrl;
//   final IconData metaIcon;
// }

// class FeaturedList extends StatelessWidget {
//   const FeaturedList({super.key, required this.destinations});

//   final List<DestinationCardData> destinations;

//   @override
//   Widget build(BuildContext context) {
//     return _FeaturedListView(destinations: destinations);
//   }
// }

// class _FeaturedListView extends StatefulWidget {
//   const _FeaturedListView({required this.destinations});

//   final List<DestinationCardData> destinations;

//   @override
//   State<_FeaturedListView> createState() => _FeaturedListViewState();
// }

// class _FeaturedListViewState extends State<_FeaturedListView> {
//   late final PageController _pageController;
//   double _page = 0;

//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController(viewportFraction: 0.75)
//       ..addListener(_handleScroll);
//   }

//   void _handleScroll() {
//     if (!_pageController.hasClients) return;
//     final next = _pageController.page ?? 0;
//     if (next == _page) return;
//     setState(() {
//       _page = next;
//     });
//   }

//   @override
//   void dispose() {
//     _pageController
//       ..removeListener(_handleScroll)
//       ..dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         SizedBox(
//           height: 220,
//           child: PageView.builder(
//             controller: _pageController,
//             padEnds: false,
//             scrollDirection: Axis.horizontal,
//             physics: const BouncingScrollPhysics(),
//             itemCount: widget.destinations.length,
//             itemBuilder: (context, index) => Padding(
//               padding: EdgeInsets.only(
//                 // ✅ Using the public DestinationCard name here
//                 right: index == widget.destinations.length - 1 ? 0 : 12,
//               ),
//               child: DestinationCard(data: widget.destinations[index]),
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//         Center(
//           child: SizedBox(
//             width: 110,
//             child: _PagerIndicator(
//               progress: widget.destinations.length > 1
//                   ? (_page / (widget.destinations.length - 1)).clamp(0, 1)
//                   : 0,
//               itemCount: widget.destinations.length,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ✅ Corrected: Removed underscore from class and constructor
// class DestinationCard extends StatelessWidget {
//   const DestinationCard({super.key, required this.data});

//   final DestinationCardData data;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 220,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           ClipRRect(
//             borderRadius: const BorderRadius.only(
//               topLeft: Radius.circular(14),
//               topRight: Radius.circular(14),
//             ),
//             child:
//                 data
//                     .imageUrl
//                     .isEmpty // ✅ Added safety check
//                 ? Container(
//                     height: 130,
//                     width: double.infinity,
//                     color: Colors.grey[200],
//                     child: const Icon(
//                       Icons.image_not_supported,
//                       color: Colors.grey,
//                       size: 40,
//                     ),
//                   )
//                 : Image.network(
//                     data.imageUrl,
//                     height: 130,
//                     width: double.infinity,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) => Container(
//                       height: 130,
//                       color: Colors.grey[200],
//                       child: const Icon(
//                         Icons.broken_image,
//                         color: Colors.grey,
//                         size: 40,
//                       ),
//                     ),
//                   ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   data.title,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w700,
//                     fontSize: 16,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Row(
//                   children: [
//                     Icon(data.metaIcon, size: 16, color: AppColors.subtext),
//                     const SizedBox(width: 6),
//                     Expanded(
//                       child: Text(
//                         data.subtitle,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                           color: AppColors.subtext,
//                           fontSize: 13,
//                         ),
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: data.tagColor.withOpacity(0.14),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         data.tag,
//                         style: TextStyle(
//                           color: data.tagColor,
//                           fontWeight: FontWeight.w700,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PagerIndicator extends StatelessWidget {
//   const _PagerIndicator({required this.progress, required this.itemCount});

//   final double progress;
//   final int itemCount;

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final trackWidth = constraints.maxWidth;
//         final handleWidth =
//             (itemCount > 0 ? trackWidth / itemCount : trackWidth).clamp(
//               28.0,
//               trackWidth,
//             );
//         final maxOffset = (trackWidth - handleWidth).clamp(0.0, trackWidth);
//         final left = maxOffset * progress.clamp(0.0, 1.0);

//         return Container(
//           height: 10,
//           decoration: BoxDecoration(
//             color: const Color(0xFFDADFE4),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Stack(
//             children: [
//               Positioned(
//                 left: left,
//                 top: 2,
//                 bottom: 2,
//                 child: Container(
//                   width: handleWidth,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF888B8F),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }


// lib/features/destination/presentation/widgets/destination_card.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DestinationCardData {
  const DestinationCardData({
    required this.title,
    required this.location,
    required this.tag,
    required this.tagColor,
    required this.imageUrl,
    required this.metaIcon,
  });

  final String title;
  final String location;
  final String tag;
  final Color tagColor;
  final String imageUrl;
  final IconData metaIcon;
}

class DestinationCard extends StatelessWidget {
  const DestinationCard({super.key, required this.data});

  final DestinationCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with location overlay
          Stack(
            children: [
              // Main image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: data.imageUrl.isEmpty
                    ? Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 40,
                        ),
                      )
                    : Image.network(
                        data.imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      ),
              ),
              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        data.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            data.metaIcon,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              data.location,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Content section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description (mock - you'll need to add this to DestinationCardData)
                Text(
                  'Colorful cliffside villages, Mediterranean cuisine, and stunning coastal drives.',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Price and best time row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '\$',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '~170/day',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'May - September',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Tag badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: data.tagColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data.tag,
                        style: TextStyle(
                          color: data.tagColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Multiple tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag('Beach'),
                    _buildTag('Romantic'),
                    _buildTag('Food'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8ECF1),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF4A5568),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Keep FeaturedList for home screen carousel
class FeaturedList extends StatelessWidget {
  const FeaturedList({super.key, required this.destinations});

  final List<DestinationCardData> destinations;

  @override
  Widget build(BuildContext context) {
    return _FeaturedListView(destinations: destinations);
  }
}

class _FeaturedListView extends StatefulWidget {
  const _FeaturedListView({required this.destinations});

  final List<DestinationCardData> destinations;

  @override
  State<_FeaturedListView> createState() => _FeaturedListViewState();
}

class _FeaturedListViewState extends State<_FeaturedListView> {
  late final PageController _pageController;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.75)
      ..addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_pageController.hasClients) return;
    final next = _pageController.page ?? 0;
    if (next == _page) return;
    setState(() {
      _page = next;
    });
  }

  @override
  void dispose() {
    _pageController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 320, // Increased height for new card design
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.destinations.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(
                right: index == widget.destinations.length - 1 ? 0 : 12,
              ),
              child: DestinationCard(data: widget.destinations[index]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: SizedBox(
            width: 110,
            child: _PagerIndicator(
              progress: widget.destinations.length > 1
                  ? (_page / (widget.destinations.length - 1)).clamp(0, 1)
                  : 0,
              itemCount: widget.destinations.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _PagerIndicator extends StatelessWidget {
  const _PagerIndicator({required this.progress, required this.itemCount});

  final double progress;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final handleWidth =
            (itemCount > 0 ? trackWidth / itemCount : trackWidth).clamp(
              28.0,
              trackWidth,
            );
        final maxOffset = (trackWidth - handleWidth).clamp(0.0, trackWidth);
        final left = maxOffset * progress.clamp(0.0, 1.0);

        return Container(
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFFDADFE4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              Positioned(
                left: left,
                top: 2,
                bottom: 2,
                child: Container(
                  width: handleWidth,
                  decoration: BoxDecoration(
                    color: const Color(0xFF888B8F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}