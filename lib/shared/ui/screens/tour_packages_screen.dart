// import 'package:flutter/material.dart';

// import '../../core/theme/app_colors.dart';
// import 'package_details_screen.dart';
// import '../../features/itinerary/data/itinerary_service.dart';

// class TourPackage {
//   const TourPackage({
//     this.id,
//     required this.title,
//     required this.imageUrl,
//     required this.rating,
//     required this.cities,
//     required this.badge,
//     required this.badgeColor,
//     required this.features,
//     required this.price,
//     this.hasFreeCancellation = true,
//   });

//   final String? id;
//   final String title;
//   final String imageUrl;
//   final double rating;
//   final int cities;
//   final String badge;
//   final Color badgeColor;
//   final List<String> features;
//   final int price;
//   final bool hasFreeCancellation;
// }

// class TourPackagesScreen extends StatefulWidget {
//   const TourPackagesScreen({
//     super.key,
//     this.showBackButton = true,
//     this.isLoggedIn = false,
//   });

//   final bool showBackButton;
//   final bool isLoggedIn;

//   @override
//   State<TourPackagesScreen> createState() => _TourPackagesScreenState();
// }

// class _TourPackagesScreenState extends State<TourPackagesScreen> {
//   String? _selectedFilter;

//   final List<String> _filters = [
//     'All inclusive',
//     'Family',
//     'Adventure',
//     'Romantic',
//     'Budget',
//     'Luxury',
//   ];

//   List<TourPackage> _packages = [];
//   bool _loading = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _loadPackages();
//   }

//   Future<void> _loadPackages() async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });
//     try {
//       final list = await ItineraryService.publicList();
//       setState(() {
//         _packages = list.map((it) {
//           return TourPackage(
//             id: it.id,
//             title: it.title,
//             imageUrl:
//                 it.coverImageUrl ??
//                 (it.items.isNotEmpty && it.items.first['imageUrl'] != null
//                     ? it.items.first['imageUrl'].toString()
//                     : ''),
//             rating:
//                 (it.totalLikes != null &&
//                     it.totalViews != null &&
//                     it.totalViews! > 0)
//                 ? (it.totalLikes! / it.totalViews!) * 5
//                 : 4.5,
//             cities: it.totalDays ?? 1,
//             badge: it.status ?? 'Popular',
//             badgeColor: const Color(0xFF3B82F6),
//             features: [],
//             price: it.estimatedTotalCost != null
//                 ? it.estimatedTotalCost!.round()
//                 : 0,
//             hasFreeCancellation: true,
//           );
//         }).toList();
//       });
//     } catch (e) {
//       setState(() => _error = e.toString());
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
//               child: Row(
//                 children: [
//                   if (widget.showBackButton) ...[
//                     GestureDetector(
//                       onTap: () => Navigator.pop(context),
//                       child: const Icon(
//                         Icons.chevron_left,
//                         color: AppColors.text,
//                         size: 28,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                   ],
//                   const Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Tour packages',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w700,
//                           fontSize: 18,
//                         ),
//                       ),
//                       Text(
//                         'Browse curated trips',
//                         style: TextStyle(
//                           color: AppColors.subtext,
//                           fontSize: 13,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const Spacer(),
//                   Container(
//                     height: 36,
//                     width: 36,
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       shape: BoxShape.circle,
//                       border: Border.all(color: AppColors.stroke),
//                     ),
//                     child: const Icon(
//                       Icons.notifications_outlined,
//                       size: 20,
//                       color: Color(0xFF606F81),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Search bar
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Container(
//                       height: 48,
//                       padding: const EdgeInsets.symmetric(horizontal: 14),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: AppColors.stroke),
//                       ),
//                       child: const Row(
//                         children: [
//                           Icon(
//                             Icons.search,
//                             color: AppColors.subtext,
//                             size: 20,
//                           ),
//                           SizedBox(width: 10),
//                           Expanded(
//                             child: Text(
//                               'Search destination or theme',
//                               style: TextStyle(
//                                 color: AppColors.subtext,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Container(
//                     height: 48,
//                     padding: const EdgeInsets.symmetric(horizontal: 14),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(color: AppColors.stroke),
//                     ),
//                     child: const Row(
//                       children: [
//                         Icon(Icons.tune, color: AppColors.subtext, size: 20),
//                         SizedBox(width: 6),
//                         Text(
//                           'Filters',
//                           style: TextStyle(color: AppColors.text, fontSize: 14),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 14),

//             // Filter chips
//             SizedBox(
//               height: 40,
//               child: ListView.separated(
//                 scrollDirection: Axis.horizontal,
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: _filters.length,
//                 separatorBuilder: (_, __) => const SizedBox(width: 10),
//                 itemBuilder: (context, index) {
//                   final filter = _filters[index];
//                   final isSelected = _selectedFilter == filter;
//                   return GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         _selectedFilter = isSelected ? null : filter;
//                       });
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 10,
//                       ),
//                       decoration: BoxDecoration(
//                         color: isSelected
//                             ? const Color(0xFFE6F6EE)
//                             : Colors.white,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: isSelected
//                               ? AppColors.primary
//                               : AppColors.stroke,
//                         ),
//                       ),
//                       child: Text(
//                         filter,
//                         style: TextStyle(
//                           color: isSelected
//                               ? AppColors.primary
//                               : AppColors.text,
//                           fontWeight: FontWeight.w500,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Recommended section
//             Expanded(
//               child: SingleChildScrollView(
//                 physics: const BouncingScrollPhysics(),
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'Recommended',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w700,
//                             fontSize: 18,
//                           ),
//                         ),
//                         Text(
//                           'Top picks for you',
//                           style: TextStyle(
//                             color: AppColors.subtext,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),

//                     // Package cards
//                     if (_loading) ...[
//                       const SizedBox(height: 120),
//                       const Center(child: CircularProgressIndicator()),
//                       const SizedBox(height: 12),
//                     ] else if (_error != null) ...[
//                       SizedBox(
//                         height: 120,
//                         child: Center(
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 'Failed to load packages: $_error',
//                                 textAlign: TextAlign.center,
//                               ),
//                               const SizedBox(height: 8),
//                               ElevatedButton(
//                                 onPressed: _loadPackages,
//                                 child: const Text('Retry'),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ] else ...[
//                       ..._packages.map(
//                         (package) => _PackageCard(
//                           package: package,
//                           isLoggedIn: widget.isLoggedIn,
//                         ),
//                       ),
//                     ],

//                     const SizedBox(height: 80),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _PackageCard extends StatelessWidget {
//   const _PackageCard({required this.package, this.isLoggedIn = false});

//   final TourPackage package;
//   final bool isLoggedIn;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.04),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Image
//           ClipRRect(
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
//             child: Image.network(
//               package.imageUrl,
//               height: 180,
//               width: double.infinity,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) => Container(
//                 height: 180,
//                 color: AppColors.stroke,
//                 child: const Center(
//                   child: Icon(Icons.image, size: 40, color: AppColors.subtext),
//                 ),
//               ),
//             ),
//           ),

//           Padding(
//             padding: const EdgeInsets.all(14),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Title and badge
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: Text(
//                         package.title,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w700,
//                           fontSize: 17,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 5,
//                       ),
//                       decoration: BoxDecoration(
//                         color: package.badgeColor,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         package.badge,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 8),

//                 // Rating and info
//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.star_outline,
//                       size: 16,
//                       color: Color(0xFFFBBF24),
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       '${package.rating}',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       '•  ${package.cities} ${package.cities == 1 ? 'city' : 'cities'}',
//                       style: const TextStyle(
//                         color: AppColors.subtext,
//                         fontSize: 14,
//                       ),
//                     ),
//                     if (package.hasFreeCancellation) ...[
//                       const SizedBox(width: 8),
//                       const Text(
//                         '•  Free cancellation',
//                         style: TextStyle(
//                           color: AppColors.subtext,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),

//                 const SizedBox(height: 12),

//                 // Features
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: package.features
//                       .map(
//                         (feature) => Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 6,
//                           ),
//                           decoration: BoxDecoration(
//                             color: AppColors.background,
//                             borderRadius: BorderRadius.circular(14),
//                             border: Border.all(color: AppColors.stroke),
//                           ),
//                           child: Text(
//                             feature,
//                             style: const TextStyle(
//                               color: AppColors.text,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ),
//                       )
//                       .toList(),
//                 ),

//                 const SizedBox(height: 14),

//                 // Price and button
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.baseline,
//                       textBaseline: TextBaseline.alphabetic,
//                       children: [
//                         Text(
//                           '\$${package.price}',
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w700,
//                             fontSize: 22,
//                           ),
//                         ),
//                         const SizedBox(width: 4),
//                         const Text(
//                           'per person',
//                           style: TextStyle(
//                             color: AppColors.subtext,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => PackageDetailsScreen(
//                               packageTitle: package.title,
//                               packagePrice: package.price,
//                               isLoggedIn: isLoggedIn,
//                               itineraryId: package.id,
//                             ),
//                           ),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF3B82F6),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 12,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: const Text(
//                         'View details',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 14,
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
