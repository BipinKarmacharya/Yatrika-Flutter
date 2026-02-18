import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tour_guide/core/api/api_client.dart';

class ParallaxHeader extends StatefulWidget {
  final String title;
  final List<String>? images; // Added images list
  final bool isOwner;
  final bool isEditing;
  final bool isCompleted;
  final VoidCallback onEditPressed;
  final VoidCallback onSettingsPressed;

  const ParallaxHeader({
    super.key,
    required this.title,
    this.images,
    required this.isOwner,
    required this.isEditing,
    required this.isCompleted,
    required this.onEditPressed,
    required this.onSettingsPressed,
  });

  @override
  State<ParallaxHeader> createState() => _ParallaxHeaderState();
}

class _ParallaxHeaderState extends State<ParallaxHeader> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final String _placeholderImg =
      "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?q=80&w=1000&auto=format&fit=crop";

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> displayImages = (widget.images != null && widget.images!.isNotEmpty)
      ? widget.images!.map((path) => ApiClient.getFullImageUrl(path)).toList()
      : [_placeholderImg];

    return SliverAppBar(
      expandedHeight: 280, // Increased slightly for better slider proportions
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: const Color(0xFF009688),
      actions: [
        if (widget.isOwner && !widget.isEditing && !widget.isCompleted)
          _buildCircleAction(Icons.edit, widget.onEditPressed),
        if (widget.isOwner && !widget.isEditing)
          _buildCircleAction(Icons.settings, widget.onSettingsPressed),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Image Slider
            PageView.builder(
              controller: _pageController,
              itemCount: displayImages.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: displayImages[index],
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Image.network(
                    "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?q=80&w=1000&auto=format&fit=crop",
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),

            // 2. Gradient Overlay for readability
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black38,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black54,
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),

            // 3. Dot Indicators
            if (displayImages.length > 1)
              Positioned(
                bottom: 60, // Positioned above the title area
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(displayImages.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: _currentPage == index ? 16 : 6,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white54,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleAction(IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: CircleAvatar(
        backgroundColor: Colors.black26,
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';

// class ParallaxHeader extends StatelessWidget {
//   final String title;
//   final bool isOwner;
//   final bool isEditing;
//   final bool isCompleted; 
//   final VoidCallback onEditPressed; 
//   final VoidCallback onSettingsPressed;

//   const ParallaxHeader({
//     super.key,
//     required this.title,
//     required this.isOwner,
//     required this.isEditing,
//     required this.isCompleted,
//     required this.onEditPressed,
//     required this.onSettingsPressed,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SliverAppBar(
//       expandedHeight: 250,
//       pinned: true,
//       stretch: true,
//       backgroundColor: const Color(0xFF009688),
//       actions: [
//         // Pencil icon only shows if trip is NOT completed
//         if (isOwner && !isEditing && !isCompleted)
//           IconButton(
//             icon: const Icon(Icons.edit, color: Colors.white),
//             onPressed: onEditPressed,
//           ),
//         // Settings icon always shows for owner
//         if (isOwner && !isEditing)
//           IconButton(
//             icon: const Icon(Icons.settings, color: Colors.white),
//             onPressed: onSettingsPressed,
//           ),
//       ],
//       flexibleSpace: FlexibleSpaceBar(
//         title: Text(
//           title,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//         background: Image.network(
//           "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?q=80&w=1000&auto=format&fit=crop",
//           fit: BoxFit.cover,
//         ),
//       ),
//     );
//   }
// }

// // import 'package:flutter/material.dart';

// // class ParallaxHeader extends StatelessWidget {
// //   final String title;
// //   final bool isOwner;
// //   final bool isEditing;
// //   final VoidCallback onEditPressed;
// //   final VoidCallback onSettingsPressed;
// //   final bool isCompleted;

// //   const ParallaxHeader({
// //     super.key,
// //     required this.title,
// //     required this.isOwner,
// //     required this.isEditing,
// //     required this.onEditPressed,
// //     required this.onSettingsPressed,
// //     required this.isCompleted,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     return SliverAppBar(
// //       expandedHeight: 250,
// //       pinned: true,
// //       stretch: true,
// //       backgroundColor: const Color(0xFF009688),
// //       actions: [
// //         if (isOwner && !isEditing && !isCompleted)
// //           IconButton(
// //             icon: const Icon(Icons.edit, color: Colors.white),
// //             onPressed: onEditPressed,
// //           ),
// //         if (isOwner && !isEditing)
// //           IconButton(
// //             icon: const Icon(Icons.settings, color: Colors.white),
// //             onPressed: onSettingsPressed,
// //           ),
// //       ],
// //       flexibleSpace: FlexibleSpaceBar(
// //         title: Text(
// //           title,
// //           style: const TextStyle(
// //             color: Colors.white,
// //             fontWeight: FontWeight.bold,
// //             fontSize: 16,
// //           ),
// //         ),
// //         background: Image.network(
// //           "https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=800",
// //           fit: BoxFit.cover,
// //         ),
// //       ),
// //     );
// //   }
// // }
