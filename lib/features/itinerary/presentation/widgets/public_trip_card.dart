// public_trip_card.dart
import 'package:flutter/material.dart';
import 'package:tour_guide/features/auth/data/models/user_model.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:provider/provider.dart';

class PublicTripCard extends StatelessWidget {
  final Itinerary itinerary;

  const PublicTripCard({super.key, required this.itinerary});

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
                Row(
                  children: [
                    // Copy button
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
                    const SizedBox(width: 4),
                    // Save button
                    IconButton(
                      onPressed: () => _saveTrip(context),
                      icon: Icon(
                        Icons.bookmark_border,
                        color: Colors.grey.shade600,
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

                    // Likes
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _toggleLike(context),
                          icon: Icon(
                            itinerary.likeCount! > 0
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: itinerary.likeCount! > 0
                                ? Colors.red
                                : Colors.grey.shade500,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${itinerary.likeCount ?? 0}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
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

  void _saveTrip(BuildContext context) async {
    final provider = context.read<ItineraryProvider>();
    try {
      await provider.savePublicPlan(itinerary.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip saved to your plans!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save trip: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleLike(BuildContext context) async {
    final provider = context.read<ItineraryProvider>();
    try {
      await provider.toggleLike(itinerary.id);
      // Provider should update the itinerary with new like count
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update like: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// // public_trip_card.dart
// import 'package:flutter/material.dart';
// import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
// import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
// import 'package:provider/provider.dart';

// class PublicTripCard extends StatelessWidget {
//   final Itinerary itinerary;

//   const PublicTripCard({super.key, required this.itinerary});

//   @override
//   Widget build(BuildContext context) {
//     // For responsive design
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
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
//                   _formatBudget(itinerary.budget),
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                 ),
//                 // Save button
//                 IconButton(
//                   onPressed: () => _saveTrip(context),
//                   icon: Icon(
//                     Icons.bookmark_border,
//                     color: Colors.grey.shade600,
//                   ),
//                   iconSize: 24,
//                 ),
//               ],
//             ),
//           ),
          
//           // Content section
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // User info
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 16,
//                       backgroundColor: Colors.grey.shade200,
//                       child: Text(
//                         itinerary.user?.name.substring(0, 1) ?? 'U',
//                         style: const TextStyle(
//                           color: Colors.black,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         itinerary.user?.name ?? 'Unknown User',
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
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
                
//                 // Location and duration
//                 Row(
//                   children: [
//                     const Icon(Icons.location_on, size: 16, color: Colors.grey),
//                     const SizedBox(width: 4),
//                     Text(
//                       itinerary.destination?.name ?? 'Unknown Destination',
//                       style: TextStyle(
//                         color: Colors.grey.shade600,
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     const Icon(Icons.flag, size: 16, color: Colors.grey),
//                     const SizedBox(width: 4),
//                     Text(
//                       itinerary.countryCode ?? 'Unknown',
//                       style: TextStyle(
//                         color: Colors.grey.shade600,
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
//                     const SizedBox(width: 4),
//                     Text(
//                       '${itinerary.duration ?? 1} days',
//                       style: TextStyle(
//                         color: Colors.grey.shade600,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
                
//                 const SizedBox(height: 12),
                
//                 // Description
//                 Text(
//                   itinerary.description ?? '',
//                   style: TextStyle(
//                     color: Colors.grey.shade700,
//                     fontSize: 14,
//                     height: 1.4,
//                   ),
//                   maxLines: 3,
//                   overflow: TextOverflow.ellipsis,
//                 ),
                
//                 const SizedBox(height: 12),
                
//                 // Tags
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 4,
//                   children: itinerary.tags?.map((tag) => _buildTag(tag)).toList() ?? [],
//                 ),
                
//                 const SizedBox(height: 12),
                
//                 // Date and likes
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // Date
//                     Text(
//                       _formatDate(itinerary.createdAt),
//                       style: TextStyle(
//                         color: Colors.grey.shade500,
//                         fontSize: 12,
//                       ),
//                     ),
                    
//                     // Likes/Views
//                     Row(
//                       children: [
//                         Icon(Icons.favorite_border, size: 16, color: Colors.grey.shade500),
//                         const SizedBox(width: 4),
//                         Text(
//                           '${itinerary.likesCount ?? 0}',
//                           style: TextStyle(
//                             color: Colors.grey.shade500,
//                             fontSize: 12,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Icon(Icons.visibility, size: 16, color: Colors.grey.shade500),
//                         const SizedBox(width: 4),
//                         Text(
//                           '${itinerary.viewsCount ?? 0}',
//                           style: TextStyle(
//                             color: Colors.grey.shade500,
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
//     if (budget == null) return '\$0 USD';
//     return '\$${budget.toStringAsFixed(0)} USD';
//   }

//   String _formatDate(DateTime? date) {
//     if (date == null) return 'Unknown date';
//     final now = DateTime.now();
//     final difference = now.difference(date);
    
//     if (difference.inDays == 0) return 'Today';
//     if (difference.inDays == 1) return 'Yesterday';
//     if (difference.inDays < 7) return '${difference.inDays} days ago';
//     if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
    
//     return '${date.day}/${date.month}/${date.year}';
//   }

//   void _saveTrip(BuildContext context) async {
//     final provider = context.read<ItineraryProvider>();
//     try {
//       await provider.savePublicPlan(itinerary.id!);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Trip saved to your plans!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to save trip: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:tour_guide/features/auth/logic/auth_provider.dart';
// import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
// import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
// import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_detail_screen.dart';

// class PublicTripCard extends StatelessWidget {
//   final Itinerary itinerary;

//   const PublicTripCard({super.key, required this.itinerary});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ItineraryDetailScreen(itinerary: itinerary),
//           ),
//         );
//       },
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
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildImageStack(),
//               Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildHeader(),
//                     const SizedBox(height: 8),
//                     _buildStatsRow(),
//                     const SizedBox(height: 12),
//                     _buildFooter(context),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildImageStack() {
//     return Stack(
//       children: [
//         // Placeholder for a trip cover image
//         Container(
//           height: 140,
//           width: double.infinity,
//           color: Colors.grey.shade200,
//           child: const Icon(Icons.map_outlined, size: 40, color: Colors.grey),
//         ),
//         if (itinerary.isAdminCreated)
//           Positioned(
//             top: 12,
//             left: 12,
//             child: _buildBadge("EXPERT", const Color(0xFF009688)),
//           ),
//         Positioned(
//           top: 12,
//           right: 12,
//           child: Container(
//             padding: const EdgeInsets.all(6),
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.favorite_border, size: 18),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHeader() {
//     return Text(
//       itinerary.title,
//       maxLines: 1,
//       overflow: TextOverflow.ellipsis,
//       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//     );
//   }

//   Widget _buildStatsRow() {
//     return Row(
//       children: [
//         const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
//         const SizedBox(width: 4),
//         Text(
//           "${itinerary.totalDays ?? 0} Days",
//           style: const TextStyle(color: Colors.grey, fontSize: 12),
//         ),
//         const SizedBox(width: 12),
//         const Icon(Icons.star, size: 14, color: Colors.amber),
//         const SizedBox(width: 4),
//         Text(
//           itinerary.averageRating?.toStringAsFixed(1) ?? "0.0",
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//         ),
//       ],
//     );
//   }

//   Widget _buildFooter(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         _buildPriceInfo(), // This is the method we are defining below
//         Consumer<ItineraryProvider>(
//           builder: (context, itineraryProvider, child) {
//             final bool isAlreadyCopied = itineraryProvider.myPlans.any(
//               (p) => p.sourceId == itinerary.id,
//             );

//             return ElevatedButton(
//               onPressed: isAlreadyCopied
//                   ? () => _navigateToExistingCopy(
//                       context,
//                       itineraryProvider,
//                       itinerary.id,
//                     )
//                   : () => _handleCopy(context),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: isAlreadyCopied
//                     ? Colors.grey.shade200
//                     : const Color(0xFF009688),
//                 foregroundColor: isAlreadyCopied
//                     ? Colors.grey.shade700
//                     : Colors.white,
//                 elevation: isAlreadyCopied ? 0 : 2,
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: Text(
//                 isAlreadyCopied ? "View Plan" : "Copy",
//                 style: const TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }

//   // Extracted Price Info Widget
//   Widget _buildPriceInfo() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "Estimated",
//           style: TextStyle(color: Colors.grey, fontSize: 10),
//         ),
//         Text(
//           "\$${itinerary.summary?.totalEstimatedBudget.toStringAsFixed(0) ?? '0'}",
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF009688),
//             fontSize: 16,
//           ),
//         ),
//       ],
//     );
//   }

//   void _handleCopy(BuildContext context) async {
//     final auth = Provider.of<AuthProvider>(context, listen: false);
//     final itineraryProvider = Provider.of<ItineraryProvider>(
//       context,
//       listen: false,
//     );

//     if (!auth.isLoggedIn) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Please sign in to save trips"),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     try {
//       final newCopy = await itineraryProvider.copyTrip(itinerary.id);

//       if (context.mounted && newCopy != null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Trip saved! You can now customize it."),
//           ),
//         );

//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ItineraryDetailScreen(itinerary: newCopy),
//           ),
//         );
//       }
//     } catch (e) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }

//   void _navigateToExistingCopy(
//     BuildContext context,
//     ItineraryProvider provider,
//     int originalId,
//   ) {
//     final existingItinerary = provider.myPlans.firstWhere(
//       (p) => p.sourceId == originalId,
//     );
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) =>
//             ItineraryDetailScreen(itinerary: existingItinerary),
//       ),
//     );
//   }

//   Widget _buildBadge(String text, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Text(
//         text,
//         style: const TextStyle(
//           color: Colors.white,
//           fontSize: 10,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }
// }
