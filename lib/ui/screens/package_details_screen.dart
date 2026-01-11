// import 'package:flutter/material.dart';

// import '../../core/theme/app_colors.dart';
// import '../components/login_required_dialog.dart';
// import '../../features/itinerary/data/itinerary_service.dart';

// class PackageDetailData {
//   const PackageDetailData({
//     required this.title,
//     required this.subtitle,
//     required this.imageUrl,
//     required this.rating,
//     required this.reviewCount,
//     required this.destinations,
//     required this.duration,
//     required this.inclusions,
//     required this.itinerary,
//     required this.stayIncluded,
//     required this.stayUpgrade,
//     required this.upgradePrice,
//     required this.notIncluded,
//     required this.partnerName,
//     required this.partnerBookings,
//     required this.reviews,
//     required this.price,
//     required this.tags,
//   });

//   final String title;
//   final String subtitle;
//   final String imageUrl;
//   final double rating;
//   final String reviewCount;
//   final String destinations;
//   final String duration;
//   final List<String> inclusions;
//   final List<ItineraryHighlight> itinerary;
//   final String stayIncluded;
//   final String stayUpgrade;
//   final int upgradePrice;
//   final List<String> notIncluded;
//   final String partnerName;
//   final String partnerBookings;
//   final List<Review> reviews;
//   final int price;
//   final List<String> tags;
// }

// class ItineraryHighlight {
//   const ItineraryHighlight({
//     required this.day,
//     required this.title,
//     required this.description,
//   });

//   final int day;
//   final String title;
//   final String description;
// }

// class Review {
//   const Review({
//     required this.avatarUrl,
//     required this.rating,
//     required this.comment,
//     required this.date,
//     required this.travelerType,
//   });

//   final String avatarUrl;
//   final double rating;
//   final String comment;
//   final String date;
//   final String travelerType;
// }

// class PackageDetailsScreen extends StatefulWidget {
//   const PackageDetailsScreen({
//     super.key,
//     required this.packageTitle,
//     required this.packagePrice,
//     this.isLoggedIn = false,
//     this.itineraryId,
//   });

//   final String packageTitle;
//   final int packagePrice;
//   final bool isLoggedIn;
//   final String? itineraryId;

//   @override
//   State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
// }

// class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
//   bool _loading = false;
//   String? _error;
//   PackageDetailData? _fetched;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.itineraryId != null) _fetchItinerary(widget.itineraryId!);
//   }

//   Future<void> _fetchItinerary(String id) async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });
//     try {
//       final it = await ItineraryService.getById(id);
//       final items = (it.items ?? <Map<String, dynamic>>[]);
//       final highlights = items
//           .take(6)
//           .map(
//             (e) => ItineraryHighlight(
//               day: (e['dayNumber'] is int) ? e['dayNumber'] as int : 1,
//               title: (e['title'] ?? '').toString(),
//               description: (e['description'] ?? '').toString(),
//             ),
//           )
//           .toList();

//       final data = PackageDetailData(
//         title: it.title ?? widget.packageTitle,
//         subtitle: it.totalDays != null
//             ? '${it.totalDays} days'
//             : _getSubtitle(widget.packageTitle),
//         imageUrl: it.coverImageUrl ?? _getImageUrl(widget.packageTitle),
//         rating: 4.6,
//         reviewCount: it.totalViews?.toString() ?? '—',
//         destinations: items.isNotEmpty
//             ? items
//                   .map((e) => (e['locationName'] ?? e['title'] ?? ''))
//                   .join(' • ')
//             : _getDestinations(widget.packageTitle),
//         duration: it.totalDays != null
//             ? '${it.totalDays} days'
//             : _getDuration(widget.packageTitle),
//         inclusions: const [],
//         itinerary: highlights,
//         stayIncluded: _getStayIncluded(widget.packageTitle),
//         stayUpgrade: _getStayUpgrade(widget.packageTitle),
//         upgradePrice: 320,
//         notIncluded: const [
//           'Lunch & dinners (unless stated)',
//           'Travel insurance',
//           'Personal expenses',
//         ],
//         partnerName: 'Partner',
//         partnerBookings: '—',
//         reviews: const [],
//         price: widget.packagePrice,
//         tags: _getTags(widget.packageTitle),
//       );

//       setState(() => _fetched = data);
//     } catch (e) {
//       setState(() => _error = e.toString());
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   // Helpers
//   String _getSubtitle(String title) => '7D/6N';

//   String _getImageUrl(String title) {
//     if (title.contains('Everest')) {
//       return 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=800&q=80';
//     }
//     if (title.contains('Pokhara')) {
//       return 'https://images.unsplash.com/photo-1558799401-1dcba79f7173?auto=format&fit=crop&w=800&q=80';
//     }
//     return 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=800&q=80';
//   }

//   String _getDestinations(String title) => 'Kathmandu • Pokhara • Chitwan';
//   String _getDuration(String title) => '7 days / 6 nights';
//   List<String> _getInclusions(String title) => const [
//     'Round-trip flights',
//     'Airport transfers',
//     'Daily breakfast',
//   ];
//   String _getStayIncluded(String title) => 'Standard hotel stay included';
//   String _getStayUpgrade(String title) => 'Upgrade to 5★ available';
//   List<String> _getTags(String title) => ['All inclusive', '4★ Hotels'];

//   PackageDetailData get _packageData {
//     if (_fetched != null) return _fetched!;
//     return PackageDetailData(
//       title: widget.packageTitle,
//       subtitle: _getSubtitle(widget.packageTitle),
//       imageUrl: _getImageUrl(widget.packageTitle),
//       rating: 4.7,
//       reviewCount: '1.3k',
//       destinations: _getDestinations(widget.packageTitle),
//       duration: _getDuration(widget.packageTitle),
//       inclusions: _getInclusions(widget.packageTitle),
//       itinerary: _getItinerary(widget.packageTitle),
//       stayIncluded: _getStayIncluded(widget.packageTitle),
//       stayUpgrade: _getStayUpgrade(widget.packageTitle),
//       upgradePrice: 320,
//       notIncluded: const [
//         'Lunch & dinners (unless stated)',
//         'Travel insurance',
//         'Personal expenses',
//       ],
//       partnerName: 'Himalayan Trails Nepal',
//       partnerBookings: '2.1k',
//       reviews: const [],
//       price: widget.packagePrice,
//       tags: _getTags(widget.packageTitle),
//     );
//   }

//   List<ItineraryHighlight> _getItinerary(String title) {
//     return const [
//       ItineraryHighlight(
//         day: 1,
//         title: 'Arrival & welcome',
//         description: 'Meet & greet, local orientation.',
//       ),
//       ItineraryHighlight(
//         day: 2,
//         title: 'Main activities',
//         description: 'Explore highlights with guide.',
//       ),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     if (_error != null) {
//       return Scaffold(body: Center(child: Text('Error: $_error')));
//     }

//     final data = _packageData;

//     return Scaffold(
//       appBar: AppBar(title: const Text('Package details')),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Image.network(
//               data.imageUrl,
//               width: double.infinity,
//               height: 220,
//               fit: BoxFit.cover,
//             ),
//             const SizedBox(height: 12),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     data.title,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     data.subtitle,
//                     style: const TextStyle(color: AppColors.subtext),
//                   ),
//                   const SizedBox(height: 12),
//                   Wrap(
//                     spacing: 8,
//                     children: data.tags
//                         .map((t) => Chip(label: Text(t)))
//                         .toList(),
//                   ),
//                   const SizedBox(height: 12),
//                 ],
//               ),
//             ),

//             // Inclusions
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Inclusions',
//                     style: TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   const SizedBox(height: 8),
//                   Wrap(
//                     spacing: 8,
//                     children: data.inclusions
//                         .map((i) => Chip(label: Text(i)))
//                         .toList(),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Itinerary
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Itinerary highlights',
//                     style: TextStyle(fontWeight: FontWeight.w700),
//                   ),
//                   const SizedBox(height: 8),
//                   ...data.itinerary
//                       .map((h) => _PkgItineraryCard(item: h))
//                       ,
//                 ],
//               ),
//             ),

//             const SizedBox(height: 120),
//           ],
//         ),
//       ),
//       bottomNavigationBar: Container(
//         padding: const EdgeInsets.all(12),
//         color: Colors.white,
//         child: Row(
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   '\$${data.price}',
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const Text(
//                   'per person',
//                   style: TextStyle(color: AppColors.subtext),
//                 ),
//               ],
//             ),
//             const Spacer(),
//             ElevatedButton(
//               onPressed: () {
//                 if (!widget.isLoggedIn) {
//                   LoginRequiredDialog.show(
//                     context,
//                     title: 'Sign in to book',
//                     message:
//                         'Create an account or sign in to book this tour package.',
//                   );
//                   return;
//                 }
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Booking flow coming soon!')),
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//               ),
//               child: const Text('Select dates'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _PkgItineraryCard extends StatelessWidget {
//   const _PkgItineraryCard({required this.item});
//   final ItineraryHighlight item;

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Row(
//           children: [
//             CircleAvatar(radius: 18, child: Text(item.day.toString())),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     item.title,
//                     style: const TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     item.description,
//                     style: const TextStyle(color: AppColors.subtext),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _PkgReviewCard extends StatelessWidget {
//   const _PkgReviewCard({required this.review});
//   final Review review;

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       leading: CircleAvatar(backgroundImage: NetworkImage(review.avatarUrl)),
//       title: Text(review.comment),
//       subtitle: Text('${review.travelerType} • ${review.date}'),
//       trailing: Text(review.rating.toString()),
//     );
//   }
// }
