import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tour_guide/core/api/api_client.dart';
import 'package:tour_guide/features/auth/data/models/user_model.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/data/services/itinerary_service.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_detail_screen.dart';

class PublicTripCard extends StatefulWidget {
  final Itinerary itinerary;
  final bool compactMode; // Optional: for grid vs list views

  const PublicTripCard({
    super.key,
    required this.itinerary,
    this.compactMode = false,
  });

  @override
  State<PublicTripCard> createState() => _PublicTripCardState();
}

class _PublicTripCardState extends State<PublicTripCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final String _placeholderImg =
      "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?q=80&w=1000&auto=format&fit=crop";

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- Helper Methods ---

  bool _isOwnTrip() {
    final currentUserId = ApiClient.currentUserId;
    return currentUserId != null && widget.itinerary.userId == currentUserId;
  }

  bool _isExpertTemplate() => widget.itinerary.user == null;

  String _getItineraryType() {
    if (widget.itinerary.isAdminCreated) return 'Expert Plan';
    if (widget.itinerary.isPublic) return 'Public Trip';
    return 'Personal Plan';
  }

  String _getUserName(UserModel? user) {
    if (user == null) return 'Expert Plan';
    if (user.fullName.isNotEmpty && user.fullName != ' ') {
      return user.fullName;
    }
    return user.username;
  }

  String _getUserInitials(UserModel? user) {
    if (user == null) return 'E'; // E for Expert
    if (user.firstName != null && user.lastName != null) {
      return '${user.firstName![0]}${user.lastName![0]}';
    }
    if (user.firstName != null) return user.firstName![0];
    if (user.username.isNotEmpty) return user.username[0].toUpperCase();
    return 'U';
  }

  String _getCountryFlag(String countryCode) {
    final flags = {
      'NE': '🇳🇵', // Nepal
      'CH': '🇨🇭', // Switzerland
      'DE': '🇩🇪', // Germany
      'FR': '🇫🇷', // France
      'IT': '🇮🇹', // Italy
      'JP': '🇯🇵', // Japan
      'US': '🇺🇸', // USA
      'UK': '🇬🇧', // United Kingdom
      'ES': '🇪🇸', // Spain
    };
    return flags[countryCode.toUpperCase()] ?? '🌍';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30)
      return '${(difference.inDays / 7).floor()}w ago';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  List<String> _getTags() {
    if (widget.itinerary.tags?.isNotEmpty == true)
      return widget.itinerary.tags!;
    if (widget.itinerary.theme != null) {
      final theme = widget.itinerary.theme!.toLowerCase();
      if (theme.contains('adventure') || theme.contains('trekking')) {
        return ['Adventure', 'Hiking', 'Mountains'];
      }
      if (theme.contains('nature') || theme.contains('relaxation')) {
        return ['Nature', 'Relaxation', 'Lakes'];
      }
      if (theme.contains('culture') || theme.contains('history')) {
        return ['Culture', 'History', 'Heritage'];
      }
    }
    return ['Travel', 'Explore'];
  }

  // --- Action Methods ---

  void _copyTrip(BuildContext context) async {
    final provider = context.read<ItineraryProvider>();
    try {
      await provider.copyTrip(widget.itinerary.id);
      _showSnackBar(context, 'Trip copied to your plans!', Colors.green);
    } catch (e) {
      _showSnackBar(context, 'Failed to copy trip: $e', Colors.red);
    }
  }

  void _toggleSave(BuildContext context) async {
    final provider = context.read<ItineraryProvider>();
    final isSaved = widget.itinerary.isSavedByCurrentUser ?? false;
    try {
      if (isSaved) {
        await provider.unsaveItinerary(widget.itinerary.id, context: context);
      } else {
        await provider.saveItinerary(widget.itinerary.id, context: context);
      }
      _showSnackBar(
        context,
        isSaved ? 'Trip unsaved' : 'Trip saved',
        Colors.green,
      );
    } catch (e) {
      _showSnackBar(context, 'Action failed', Colors.red);
    }
  }

  void _toggleLike(BuildContext context) async {
    final provider = context.read<ItineraryProvider>();
    try {
      await provider.toggleLike(widget.itinerary.id, context: context);
    } catch (e) {
      _showSnackBar(context, 'Like failed', Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToDetail(BuildContext context, {bool editMode = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItineraryDetailScreen(
          itinerary: widget.itinerary,
          isReadOnly: !editMode,
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildImageSlider(BuildContext context, List<String> images) {
    return Stack(
      children: [
        // Main Image Slider
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: SizedBox(
            height: widget.compactMode ? 180 : 220,
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, i) => CachedNetworkImage(
                imageUrl: images[i],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) =>
                    Image.network(_placeholderImg, fit: BoxFit.cover),
              ),
            ),
          ),
        ),

        // Dot Indicator
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 4,
                  width: _currentPage == i ? 16 : 4,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Budget Overlay
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '\$${(widget.itinerary.estimatedBudget ?? 0).toStringAsFixed(0)} USD',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Type Badge
        if (widget.itinerary.isAdminCreated)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Expert',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: widget.itinerary.user?.profileImage != null
                ? CachedNetworkImage(
                    imageUrl: widget.itinerary.user!.profileImage!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Center(
                      child: Text(
                        _getUserInitials(widget.itinerary.user),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      _getUserInitials(widget.itinerary.user),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),

        // User Name & Type
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getUserName(widget.itinerary.user),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _getItineraryType(),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // Copy Count
        if (widget.itinerary.copyCount != null &&
            widget.itinerary.copyCount! > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.copy, size: 12, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text(
                  '${widget.itinerary.copyCount}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Duration
        if (widget.itinerary.totalDays != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${widget.itinerary.totalDays} days',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

        // Country Flag
        if (widget.itinerary.country != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getCountryFlag(widget.itinerary.country!),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 4),
              Text(
                widget.itinerary.country!,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

        // Location from Theme
        if (widget.itinerary.theme != null &&
            widget.itinerary.theme!.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.itinerary.theme!.length > 20
                      ? '${widget.itinerary.theme!.substring(0, 20)}...'
                      : widget.itinerary.theme!,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTags() {
    final tags = _getTags();
    if (tags.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags.map((tag) {
          return Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            child: Text(
              '#$tag',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blueGrey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isLiked = widget.itinerary.isLikedByCurrentUser ?? false;
    final isSaved = widget.itinerary.isSavedByCurrentUser ?? false;
    final likeCount = widget.itinerary.likeCount ?? 0;
    final isOwn = _isOwnTrip();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side: Like action
        Row(
          children: [
            _buildIconButton(
              icon: isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : Colors.grey.shade600,
              onTap: () => _toggleLike(context),
              showCount: true,
              count: likeCount,
              countColor: isLiked ? Colors.red : Colors.grey.shade600,
            ),
          ],
        ),

        // Center: Date
        Text(
          _formatDate(widget.itinerary.createdAt),
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),

        // Right side: Save/Copy/Edit actions
        Row(
          children: [
            if (!isOwn)
              _buildIconButton(
                icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? const Color(0xFF009688) : Colors.grey.shade600,
                onTap: () => _toggleSave(context),
              ),

            const SizedBox(width: 8),

            if (!isOwn && (_isExpertTemplate() || widget.itinerary.isPublic))
              _buildIconButton(
                icon: Icons.copy,
                color: Colors.grey.shade600,
                onTap: () => _copyTrip(context),
                tooltip: 'Copy to my plans',
              ),

            if (isOwn)
              _buildIconButton(
                icon: Icons.edit,
                color: const Color(0xFF009688),
                onTap: () => _navigateToDetail(context, editMode: true),
                tooltip: 'Edit trip',
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool showCount = false,
    int count = 0,
    Color? countColor,
    String? tooltip,
  }) {
    final content = Row(
      children: [
        if (showCount && count > 0) ...[
          Text(
            '$count',
            style: TextStyle(
              color: countColor ?? color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
        ],
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade100,
          ),
          child: IconButton(
            icon: Icon(icon, size: 18),
            color: color,
            onPressed: onTap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ),
      ],
    );

    // Only wrap with Tooltip if we have a tooltip message
    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(message: tooltip, child: content);
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final List<String> images =
        (widget.itinerary.images != null && widget.itinerary.images!.isNotEmpty)
        ? widget.itinerary.images!
        : [_placeholderImg];

    return GestureDetector(
      onTap: () => _navigateToDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Image Slider Section
            _buildImageSlider(context, images),

            // 2. Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Row
                  _buildUserInfo(),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    widget.itinerary.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  if (widget.itinerary.description?.isNotEmpty == true)
                    Column(
                      children: [
                        Text(
                          widget.itinerary.description!,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            height: 1.4,
                          ),
                          maxLines: widget.compactMode ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),

                  // Location & Duration Info
                  _buildLocationInfo(),
                  const SizedBox(height: 12),

                  // Tags
                  _buildTags(),
                  const SizedBox(height: 12),

                  // Action Buttons
                  _buildActionButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:tour_guide/core/api/api_client.dart';
// import 'package:tour_guide/features/auth/data/models/user_model.dart';
// import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
// import 'package:tour_guide/features/itinerary/data/services/itinerary_service.dart';
// import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_detail_screen.dart';

// class PublicTripCard extends StatelessWidget {
//   final Itinerary itinerary;

//   const PublicTripCard({super.key, required this.itinerary});

//   // Method to check if current user owns the trip
//   bool _isOwnTrip(BuildContext context) {
//     try {
//       final currentUserId = ApiClient.currentUserId;
//       if (currentUserId == null) return false;
//       return itinerary.userId == currentUserId;
//     } catch (e) {
//       return false;
//     }
//   }

//   // This check for expert templates
//   bool _isExpertTemplate() {
//     return itinerary.user == null; // Expert templates have null user
//   }

//   void _copyTrip(BuildContext context) async {
//     final provider = context.read<ItineraryProvider>();
//     try {
//       final copiedTrip = await provider.copyTrip(itinerary.id);
//       if (copiedTrip != null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Trip copied to your plans!'),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to copy trip: $e'),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   }

//   void _editOwnTrip(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ItineraryDetailScreen(
//           itinerary: itinerary,
//           isReadOnly: false, // Allow editing for own trips
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isMobile = MediaQuery.of(context).size.width < 600;

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             spreadRadius: 2,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Top section with budget
//           Container(
//             padding: EdgeInsets.symmetric(
//               horizontal: isMobile ? 12 : 16,
//               vertical: isMobile ? 10 : 12,
//             ),
//             decoration: BoxDecoration(
//               color: const Color(0xFF009688).withOpacity(0.05),
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(16),
//                 topRight: Radius.circular(16),
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   _formatBudget(itinerary.estimatedBudget),
//                   style: TextStyle(
//                     fontSize: isMobile ? 16 : 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     // Copy button - only for public trips and expert plans
//                     if (!_isOwnTrip(context) &&
//                         (_isExpertTemplate() || (itinerary.isPublic)))
//                       IconButton(
//                         onPressed: () => _copyTrip(context),
//                         icon: Icon(
//                           Icons.copy,
//                           color: Colors.grey.shade600,
//                           size: isMobile ? 18 : 20,
//                         ),
//                         padding: EdgeInsets.zero,
//                         constraints: const BoxConstraints(),
//                       ),

//                     // Add spacing only if copy button exists
//                     if (!_isOwnTrip(context) &&
//                         (_isExpertTemplate() || (itinerary.isPublic)))
//                       const SizedBox(width: 4),

//                     // Save button - only for non-own trips
//                     if (!_isOwnTrip(context) &&
//                         ItineraryService.canSaveItinerary(itinerary))
//                       IconButton(
//                         onPressed: () => _toggleSave(context),
//                         icon: Icon(
//                           (itinerary.isSavedByCurrentUser ?? false)
//                               ? Icons.bookmark
//                               : Icons.bookmark_border,
//                           color: (itinerary.isSavedByCurrentUser ?? false)
//                               ? const Color(0xFF009688)
//                               : Colors.grey.shade600,
//                           size: isMobile ? 18 : 20,
//                         ),
//                         padding: EdgeInsets.zero,
//                         constraints: const BoxConstraints(),
//                       ),

//                     // Like button - only for non-own trips
//                     if (!_isOwnTrip(context) &&
//                         ItineraryService.canLikeItinerary(itinerary))
//                       IconButton(
//                         onPressed: () => _toggleLike(context),
//                         icon: Icon(
//                           (itinerary.isLikedByCurrentUser ?? false)
//                               ? Icons.favorite
//                               : Icons.favorite_border,
//                           color: (itinerary.isLikedByCurrentUser ?? false)
//                               ? Colors.red
//                               : Colors.grey.shade600,
//                           size: isMobile ? 18 : 20,
//                         ),
//                         padding: EdgeInsets.zero,
//                         constraints: const BoxConstraints(),
//                       ),

//                     // For own trips, show edit button
//                     if (_isOwnTrip(context))
//                       IconButton(
//                         onPressed: () => _editOwnTrip(context),
//                         icon: Icon(
//                           Icons.edit,
//                           color: const Color(0xFF009688),
//                           size: isMobile ? 18 : 20,
//                         ),
//                         padding: EdgeInsets.zero,
//                         constraints: const BoxConstraints(),
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Content section
//           Padding(
//             padding: EdgeInsets.all(isMobile ? 12 : 16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // User info
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 16,
//                       backgroundColor: Colors.grey.shade200,
//                       backgroundImage: itinerary.user?.profileImage != null
//                           ? NetworkImage(itinerary.user!.profileImage!)
//                           : null,
//                       child: itinerary.user?.profileImage == null
//                           ? Text(
//                               _getUserInitials(itinerary.user),
//                               style: const TextStyle(
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             )
//                           : null,
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         _getUserName(itinerary.user),
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                     // Show copy count if available
//                     if (itinerary.copyCount != null && itinerary.copyCount! > 0)
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.copy,
//                             size: 14,
//                             color: Colors.grey.shade500,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${itinerary.copyCount}',
//                             style: TextStyle(
//                               color: Colors.grey.shade500,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),

//                 const SizedBox(height: 12),

//                 // Title
//                 Text(
//                   itinerary.title,
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),

//                 const SizedBox(height: 8),

//                 // Location, country, and duration
//                 Wrap(
//                   spacing: 12,
//                   runSpacing: 8,
//                   crossAxisAlignment: WrapCrossAlignment.center,
//                   children: [
//                     // Location icon and text
//                     if (itinerary.theme != null)
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Icon(
//                             Icons.location_on,
//                             size: 16,
//                             color: Colors.grey,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             _getLocationFromTheme(itinerary.theme!),
//                             style: TextStyle(
//                               color: Colors.grey.shade600,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),

//                     // Country flag
//                     if (itinerary.country != null)
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             _getCountryFlag(itinerary.country!),
//                             style: const TextStyle(fontSize: 16),
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             itinerary.country!,
//                             style: TextStyle(
//                               color: Colors.grey.shade600,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),

//                     // Duration
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(
//                           Icons.calendar_today,
//                           size: 16,
//                           color: Colors.grey,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           '${itinerary.totalDays ?? 1} days',
//                           style: TextStyle(
//                             color: Colors.grey.shade600,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 12),

//                 // Description
//                 Text(
//                   itinerary.description?.isNotEmpty == true
//                       ? itinerary.description!
//                       : 'No description provided',
//                   style: TextStyle(
//                     color: Colors.grey.shade700,
//                     fontSize: 14,
//                     height: 1.4,
//                   ),
//                   maxLines: 3,
//                   overflow: TextOverflow.ellipsis,
//                 ),

//                 const SizedBox(height: 12),

//                 // Tags - Use from itinerary or theme
//                 if ((itinerary.tags?.isNotEmpty == true) ||
//                     itinerary.theme != null)
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 4,
//                     children: _getTags(
//                       itinerary,
//                     ).map((tag) => _buildTag(tag)).toList(),
//                   ),

//                 const SizedBox(height: 12),

//                 // Date, likes, and views
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // Date - Use createdAt
//                     Text(
//                       _formatDate(itinerary.createdAt),
//                       style: TextStyle(
//                         color: Colors.grey.shade500,
//                         fontSize: 12,
//                       ),
//                     ),

//                     // Likes - FIXED: Use isLikedByCurrentUser
//                     Row(
//                       children: [
//                         IconButton(
//                           onPressed: () => _toggleLike(context),
//                           icon: Icon(
//                             (itinerary.isLikedByCurrentUser ?? false)
//                                 ? Icons
//                                       .favorite // Filled heart when liked
//                                 : Icons
//                                       .favorite_border, // Outline when not liked
//                             size: 16,
//                             color: (itinerary.isLikedByCurrentUser ?? false)
//                                 ? Colors
//                                       .red // Red when liked
//                                 : Colors.grey.shade500, // Grey when not liked
//                           ),
//                           padding: EdgeInsets.zero,
//                           constraints: const BoxConstraints(),
//                         ),
//                         const SizedBox(width: 2),
//                         Text(
//                           '${itinerary.likeCount ?? 0}',
//                           style: TextStyle(
//                             color: (itinerary.isLikedByCurrentUser ?? false)
//                                 ? Colors
//                                       .red // Red text when liked
//                                 : Colors
//                                       .grey
//                                       .shade500, // Grey text when not liked
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
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

//   Widget _buildTag(String tag) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         tag,
//         style: TextStyle(
//           color: Colors.grey.shade700,
//           fontSize: 12,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     );
//   }

//   String _formatBudget(double? budget) {
//     if (budget == null || budget == 0) return '\$0 USD';
//     return '\$${budget.toStringAsFixed(0)} USD';
//   }

//   String _formatDate(DateTime? date) {
//     if (date == null) return 'Unknown date';

//     final now = DateTime.now();
//     final difference = now.difference(date);

//     if (difference.inDays == 0) return 'Today';
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return '${difference.inDays}d ago';
//     if (difference.inDays < 30) {
//       return '${(difference.inDays / 7).floor()}w ago';
//     }

//     final month = date.month.toString().padLeft(2, '0');
//     final day = date.day.toString().padLeft(2, '0');
//     return '$month/$day/${date.year}';
//   }

//   String _getUserName(UserModel? user) {
//     if (user == null) {
//       // For expert templates (user is null), show "Expert Plan"
//       return 'Expert Plan';
//     }

//     if (user.fullName.isNotEmpty && user.fullName != ' ') {
//       return user.fullName;
//     }

//     return user.username;
//   }

//   String _getUserInitials(UserModel? user) {
//     if (user == null) return 'E'; // E for Expert

//     if (user.firstName != null && user.lastName != null) {
//       return '${user.firstName![0]}${user.lastName![0]}';
//     }

//     if (user.firstName != null) {
//       return user.firstName![0];
//     }

//     if (user.username.isNotEmpty) {
//       return user.username[0].toUpperCase();
//     }

//     return 'U';
//   }

//   String _getLocationFromTheme(String theme) {
//     // Extract location from theme string
//     if (theme.contains('Kathmandu')) return 'Kathmandu';
//     if (theme.contains('Pokhara')) return 'Pokhara';
//     if (theme.contains('Everest')) return 'Everest Region';
//     if (theme.contains('Lumbini')) return 'Lumbini';
//     if (theme.contains('Chitwan')) return 'Chitwan';

//     return theme;
//   }

//   String _getCountryFlag(String countryCode) {
//     // Map country codes to emoji flags
//     final flags = {
//       'NE': '🇳🇵', // Nepal
//       'CH': '🇨🇭', // Switzerland
//       'DE': '🇩🇪', // Germany
//       'FR': '🇫🇷', // France
//       'IT': '🇮🇹', // Italy
//       'JP': '🇯🇵', // Japan
//       'US': '🇺🇸', // USA
//       'UK': '🇬🇧', // United Kingdom
//       'ES': '🇪🇸', // Spain
//       // Add more as needed
//     };

//     return flags[countryCode.toUpperCase()] ?? '🌍';
//   }

//   List<String> _getTags(Itinerary itinerary) {
//     // Use tags from API if available
//     if (itinerary.tags?.isNotEmpty == true) {
//       return itinerary.tags!;
//     }

//     // Fallback: extract tags from theme
//     if (itinerary.theme != null) {
//       final theme = itinerary.theme!.toLowerCase();

//       if (theme.contains('adventure') || theme.contains('trekking')) {
//         return ['Adventure', 'Hiking', 'Mountains'];
//       }
//       if (theme.contains('nature') || theme.contains('relaxation')) {
//         return ['Nature', 'Relaxation', 'Lakes'];
//       }
//       if (theme.contains('culture') || theme.contains('history')) {
//         return ['Culture', 'History', 'Heritage'];
//       }
//       if (theme.contains('spiritual') || theme.contains('peace')) {
//         return ['Spiritual', 'Peaceful', 'Meditation'];
//       }
//       if (theme.contains('wildlife') || theme.contains('nature')) {
//         return ['Wildlife', 'Nature', 'Safari'];
//       }
//     }

//     // Default tags
//     return ['Travel', 'Explore'];
//   }

//   void _toggleSave(BuildContext context) async {
//     final provider = context.read<ItineraryProvider>();
//     final isCurrentlySaved = itinerary.isSavedByCurrentUser ?? false;

//     print('🎯 Toggle save called for itinerary ${itinerary.id}');
//     print('   Title: ${itinerary.title}');
//     print('   Type: ${_getItineraryType(itinerary)}');
//     print('   Currently saved: $isCurrentlySaved');

//     try {
//       if (isCurrentlySaved) {
//         print('   Action: UNSAVE');
//         await provider.unsaveItinerary(itinerary.id, context: context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Trip unsaved'),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 1),
//           ),
//         );
//       } else {
//         print('   Action: SAVE');
//         await provider.saveItinerary(itinerary.id, context: context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Trip saved'),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 1),
//           ),
//         );
//       }

//       print('✅ Toggle save completed for ${itinerary.id}');
//     } catch (e) {
//       print('❌ Error in _toggleSave: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Failed to ${isCurrentlySaved ? 'unsave' : 'save'} trip',
//           ),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   }

//   // In the _toggleLike method of PublicTripCard, pass the context:

//   void _toggleLike(BuildContext context) async {
//     final provider = context.read<ItineraryProvider>();
//     final isCurrentlyLiked = itinerary.isLikedByCurrentUser ?? false;

//     print('🎯 Toggle like called for itinerary ${itinerary.id}');
//     print('   Title: ${itinerary.title}');
//     print('   Type: ${_getItineraryType(itinerary)}');
//     print('   Currently liked: $isCurrentlyLiked');

//     try {
//       // Pass context to the provider so it can handle Expert Plans
//       await provider.toggleLike(itinerary.id, context: context);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(isCurrentlyLiked ? 'Unliked' : 'Liked'),
//           backgroundColor: Colors.green,
//           duration: const Duration(seconds: 1),
//         ),
//       );
//       print('✅ Toggle like completed for ${itinerary.id}');
//     } catch (e) {
//       print('❌ Error in _toggleLike: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to update like'),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   }

//   String _getItineraryType(Itinerary itinerary) {
//     if (itinerary.isAdminCreated) return 'Expert Plan';
//     if (itinerary.isPublic) return 'Public Trip';
//     return 'Personal Plan';
//   }
// }
