import 'package:flutter/material.dart';
import 'package:tour_guide/core/api/api_client.dart';
import 'package:tour_guide/features/auth/data/models/user_model.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/data/services/itinerary_service.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_detail_screen.dart';

class PublicTripCard extends StatelessWidget {
  final Itinerary itinerary;

  const PublicTripCard({super.key, required this.itinerary});

  // Method to check if current user owns the trip
  bool _isOwnTrip(BuildContext context) {
    try {
      final currentUserId = ApiClient.currentUserId;
      if (currentUserId == null) return false;
      return itinerary.userId == currentUserId;
    } catch (e) {
      return false;
    }
  }

  // This check for expert templates
  bool _isExpertTemplate() {
    return itinerary.user == null; // Expert templates have null user
  }

  void _copyTrip(BuildContext context) async {
    final provider = context.read<ItineraryProvider>();
    try {
      final copiedTrip = await provider.copyTrip(itinerary.id);
      if (copiedTrip != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip copied to your plans!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to copy trip: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _editOwnTrip(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItineraryDetailScreen(
          itinerary: itinerary,
          isReadOnly: false, // Allow editing for own trips
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top section with budget
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF009688).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatBudget(itinerary.estimatedBudget),
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                // Action buttons
                // In PublicTripCard, update the action buttons section:
                // Update the action buttons section in PublicTripCard:
                Row(
                  children: [
                    // Copy button - only for public trips and expert plans
                    if (!_isOwnTrip(context) &&
                        (_isExpertTemplate() || (itinerary.isPublic ?? false)))
                      IconButton(
                        onPressed: () => _copyTrip(context),
                        icon: Icon(
                          Icons.copy,
                          color: Colors.grey.shade600,
                          size: isMobile ? 18 : 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),

                    // Add spacing only if copy button exists
                    if (!_isOwnTrip(context) &&
                        (_isExpertTemplate() || (itinerary.isPublic ?? false)))
                      const SizedBox(width: 4),

                    // Save button - only for non-own trips
                    if (!_isOwnTrip(context) &&
                        ItineraryService.canSaveItinerary(itinerary))
                      IconButton(
                        onPressed: () => _toggleSave(context),
                        icon: Icon(
                          (itinerary.isSavedByCurrentUser ?? false)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: (itinerary.isSavedByCurrentUser ?? false)
                              ? const Color(0xFF009688)
                              : Colors.grey.shade600,
                          size: isMobile ? 18 : 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),

                    // Like button - only for non-own trips
                    if (!_isOwnTrip(context) &&
                        ItineraryService.canLikeItinerary(itinerary))
                      IconButton(
                        onPressed: () => _toggleLike(context),
                        icon: Icon(
                          (itinerary.isLikedByCurrentUser ?? false)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: (itinerary.isLikedByCurrentUser ?? false)
                              ? Colors.red
                              : Colors.grey.shade600,
                          size: isMobile ? 18 : 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),

                    // For own trips, show edit button
                    if (_isOwnTrip(context))
                      IconButton(
                        onPressed: () => _editOwnTrip(context),
                        icon: Icon(
                          Icons.edit,
                          color: const Color(0xFF009688),
                          size: isMobile ? 18 : 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Content section
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: itinerary.user?.profileImage != null
                          ? NetworkImage(itinerary.user!.profileImage!)
                          : null,
                      child: itinerary.user?.profileImage == null
                          ? Text(
                              _getUserInitials(itinerary.user),
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getUserName(itinerary.user),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // Show copy count if available
                    if (itinerary.copyCount != null && itinerary.copyCount! > 0)
                      Row(
                        children: [
                          Icon(
                            Icons.copy,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${itinerary.copyCount}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  itinerary.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Location, country, and duration
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Location icon and text
                    if (itinerary.theme != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getLocationFromTheme(itinerary.theme!),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                    // Country flag
                    if (itinerary.country != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getCountryFlag(itinerary.country!),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            itinerary.country!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                    // Duration
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${itinerary.totalDays ?? 1} days',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  itinerary.description?.isNotEmpty == true
                      ? itinerary.description!
                      : 'No description provided',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Tags - Use from itinerary or theme
                if ((itinerary.tags?.isNotEmpty == true) ||
                    itinerary.theme != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _getTags(
                      itinerary,
                    ).map((tag) => _buildTag(tag)).toList(),
                  ),

                const SizedBox(height: 12),

                // Date, likes, and views
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date - Use createdAt
                    Text(
                      _formatDate(itinerary.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),

                    // Likes - FIXED: Use isLikedByCurrentUser
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _toggleLike(context),
                          icon: Icon(
                            (itinerary.isLikedByCurrentUser ?? false)
                                ? Icons
                                      .favorite // Filled heart when liked
                                : Icons
                                      .favorite_border, // Outline when not liked
                            size: 16,
                            color: (itinerary.isLikedByCurrentUser ?? false)
                                ? Colors
                                      .red // Red when liked
                                : Colors.grey.shade500, // Grey when not liked
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${itinerary.likeCount ?? 0}',
                          style: TextStyle(
                            color: (itinerary.isLikedByCurrentUser ?? false)
                                ? Colors
                                      .red // Red text when liked
                                : Colors
                                      .grey
                                      .shade500, // Grey text when not liked
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatBudget(double? budget) {
    if (budget == null || budget == 0) return '\$0 USD';
    return '\$${budget.toStringAsFixed(0)} USD';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    }

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  String _getUserName(UserModel? user) {
    if (user == null) {
      // For expert templates (user is null), show "Expert Plan"
      return 'Expert Plan';
    }

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

    if (user.firstName != null) {
      return user.firstName![0];
    }

    if (user.username.isNotEmpty) {
      return user.username[0].toUpperCase();
    }

    return 'U';
  }

  String _getLocationFromTheme(String theme) {
    // Extract location from theme string
    if (theme.contains('Kathmandu')) return 'Kathmandu';
    if (theme.contains('Pokhara')) return 'Pokhara';
    if (theme.contains('Everest')) return 'Everest Region';
    if (theme.contains('Lumbini')) return 'Lumbini';
    if (theme.contains('Chitwan')) return 'Chitwan';

    return theme;
  }

  String _getCountryFlag(String countryCode) {
    // Map country codes to emoji flags
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
      // Add more as needed
    };

    return flags[countryCode.toUpperCase()] ?? '🌍';
  }

  List<String> _getTags(Itinerary itinerary) {
    // Use tags from API if available
    if (itinerary.tags?.isNotEmpty == true) {
      return itinerary.tags!;
    }

    // Fallback: extract tags from theme
    if (itinerary.theme != null) {
      final theme = itinerary.theme!.toLowerCase();

      if (theme.contains('adventure') || theme.contains('trekking')) {
        return ['Adventure', 'Hiking', 'Mountains'];
      }
      if (theme.contains('nature') || theme.contains('relaxation')) {
        return ['Nature', 'Relaxation', 'Lakes'];
      }
      if (theme.contains('culture') || theme.contains('history')) {
        return ['Culture', 'History', 'Heritage'];
      }
      if (theme.contains('spiritual') || theme.contains('peace')) {
        return ['Spiritual', 'Peaceful', 'Meditation'];
      }
      if (theme.contains('wildlife') || theme.contains('nature')) {
        return ['Wildlife', 'Nature', 'Safari'];
      }
    }

    // Default tags
    return ['Travel', 'Explore'];
  }

  void _toggleSave(BuildContext context) async {
    final provider = context.read<ItineraryProvider>();
    final isCurrentlySaved = itinerary.isSavedByCurrentUser ?? false;

    print('🎯 Toggle save called for itinerary ${itinerary.id}');
    print('   Title: ${itinerary.title}');
    print('   Type: ${_getItineraryType(itinerary)}');
    print('   Currently saved: $isCurrentlySaved');

    try {
      if (isCurrentlySaved) {
        print('   Action: UNSAVE');
        await provider.unsaveItinerary(itinerary.id, context: context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip unsaved'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        print('   Action: SAVE');
        await provider.saveItinerary(itinerary.id, context: context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip saved'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }

      print('✅ Toggle save completed for ${itinerary.id}');
    } catch (e) {
      print('❌ Error in _toggleSave: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${isCurrentlySaved ? 'unsave' : 'save'} trip',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // In the _toggleLike method of PublicTripCard, pass the context:

  void _toggleLike(BuildContext context) async {
    final provider = context.read<ItineraryProvider>();
    final isCurrentlyLiked = itinerary.isLikedByCurrentUser ?? false;

    print('🎯 Toggle like called for itinerary ${itinerary.id}');
    print('   Title: ${itinerary.title}');
    print('   Type: ${_getItineraryType(itinerary)}');
    print('   Currently liked: $isCurrentlyLiked');

    try {
      // Pass context to the provider so it can handle Expert Plans
      await provider.toggleLike(itinerary.id, context: context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCurrentlyLiked ? 'Unliked' : 'Liked'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
      print('✅ Toggle like completed for ${itinerary.id}');
    } catch (e) {
      print('❌ Error in _toggleLike: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update like'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _getItineraryType(Itinerary itinerary) {
    if (itinerary.isAdminCreated) return 'Expert Plan';
    if (itinerary.isPublic) return 'Public Trip';
    return 'Personal Plan';
  }
}
