import 'package:flutter/material.dart';
import 'package:tour_guide/features/plan/data/service/ml_service.dart';
import '../../../../core/theme/app_colors.dart';

class ItineraryScreen extends StatefulWidget {
  final Map<String, List<String>> itineraryData;
  final String city;
  final int days;
  final String budget;
  final List<String> interests;

  const ItineraryScreen({
    super.key,
    required this.itineraryData,
    required this.city,
    required this.days,
    required this.budget,
    required this.interests,
  });

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  bool _isSaving = false;

  Future<void> _savePlan() async {
    setState(() => _isSaving = true);
    try {
      await MLService.savePlan(
        city: widget.city,
        budget: widget.budget,
        interests: widget.interests,
        days: widget.days,
        itineraryData: widget.itineraryData,
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip saved to My Plans!'), backgroundColor: AppColors.primary),
      );
      
      // Optionally navigate to the main Itinerary list or home
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort keys to ensure Day 1 comes before Day 2
    final sortedDays = widget.itineraryData.keys.toList()
      ..sort((a, b) {
        int numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        int numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return numA.compareTo(numB);
      });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Trip to ${widget.city}'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoChip(Icons.calendar_today, '${widget.days} Days'),
                _infoChip(Icons.payments_outlined, widget.budget),
                _infoChip(Icons.auto_awesome, 'AI Generated'),
              ],
            ),
          ),
          const Divider(height: 1),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedDays.length,
              itemBuilder: (context, index) {
                final dayKey = sortedDays[index];
                final places = widget.itineraryData[dayKey] ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    initiallyExpanded: index == 0,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text('${index + 1}', style: const TextStyle(color: AppColors.primary)),
                    ),
                    title: Text(dayKey, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${places.length} activities'),
                    children: places.map((place) => ListTile(
                      leading: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.subtext),
                      title: Text(place),
                      dense: true,
                    )).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _savePlan,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Save to My Trips', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}


// // Tulsa --  Hard coded
// // 









// import 'package:flutter/material.dart';

// import '../../../../core/theme/app_colors.dart';

// class ItineraryActivity {
//   const ItineraryActivity({
//     required this.time,
//     required this.title,
//     required this.description,
//     required this.imageUrl,
//     required this.tags,
//   });

//   final String time;
//   final String title;
//   final String description;
//   final String imageUrl;
//   final List<String> tags;
// }

// class ItineraryDay {
//   const ItineraryDay({
//     required this.dayNumber,
//     required this.title,
//     required this.badge,
//     required this.activities,
//   });

//   final int dayNumber;
//   final String title;
//   final String badge;
//   final List<ItineraryActivity> activities;
// }

// class ItineraryScreen extends StatelessWidget {
//   const ItineraryScreen({super.key});

//   List<ItineraryDay> get _itinerary => const [
//     ItineraryDay(
//       dayNumber: 1,
//       title: 'Arrival & Kathmandu',
//       badge: 'Walkable',
//       activities: [
//         ItineraryActivity(
//           time: '09:00',
//           title: 'Breakfast at Thamel',
//           description: 'Traditional Nepali breakfast to start your day',
//           imageUrl: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=400&q=80',
//           tags: ['Cafe', '₨'],
//         ),
//         ItineraryActivity(
//           time: '11:00',
//           title: 'Swayambhunath Stupa',
//           description: 'Iconic monkey temple with panoramic valley views',
//           imageUrl: 'https://images.unsplash.com/photo-1609766857041-ed402ea8069a?auto=format&fit=crop&w=400&q=80',
//           tags: ['Landmark', 'Photo spot'],
//         ),
//         ItineraryActivity(
//           time: '13:00',
//           title: 'Dal Bhat Lunch',
//           description: 'Authentic Nepali thali experience',
//           imageUrl: 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?auto=format&fit=crop&w=400&q=80',
//           tags: ['Food', 'Local'],
//         ),
//         ItineraryActivity(
//           time: '15:30',
//           title: 'Pashupatinath Temple',
//           description: 'Sacred Hindu temple along Bagmati River',
//           imageUrl: 'https://images.unsplash.com/photo-1582654454409-778c243beef3?auto=format&fit=crop&w=400&q=80',
//           tags: ['Culture', 'Sacred'],
//         ),
//       ],
//     ),
//     ItineraryDay(
//       dayNumber: 2,
//       title: 'Patan & Bhaktapur',
//       badge: 'Transit + Walk',
//       activities: [
//         ItineraryActivity(
//           time: '09:30',
//           title: 'Patan Durbar Square',
//           description: 'Ancient royal palace and Newari architecture',
//           imageUrl: 'https://images.unsplash.com/photo-1558799401-1dcba79f7173?auto=format&fit=crop&w=400&q=80',
//           tags: ['Culture', 'Heritage'],
//         ),
//         ItineraryActivity(
//           time: '12:00',
//           title: 'Newari Lunch',
//           description: 'Traditional feast in Patan',
//           imageUrl: 'https://images.unsplash.com/photo-1567337710282-00832b415979?auto=format&fit=crop&w=400&q=80',
//           tags: ['Food'],
//         ),
//         ItineraryActivity(
//           time: '15:00',
//           title: 'Bhaktapur Durbar Square',
//           description: 'Medieval city with pottery squares',
//           imageUrl: 'https://images.unsplash.com/photo-1605640840605-14ac1855827b?auto=format&fit=crop&w=400&q=80',
//           tags: ['Explore', 'History'],
//         ),
//       ],
//     ),
//     ItineraryDay(
//       dayNumber: 3,
//       title: 'Pokhara Adventure',
//       badge: 'Adventure Day',
//       activities: [
//         ItineraryActivity(
//           time: '06:00',
//           title: 'Flight to Pokhara',
//           description: 'Scenic mountain flight with Himalayan views',
//           imageUrl: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=400&q=80',
//           tags: ['Transit', 'Views'],
//         ),
//         ItineraryActivity(
//           time: '10:00',
//           title: 'Phewa Lake Boating',
//           description: 'Peaceful rowing with Annapurna reflection',
//           imageUrl: 'https://images.unsplash.com/photo-1558799401-1dcba79f7173?auto=format&fit=crop&w=400&q=80',
//           tags: ['Nature', 'Relax'],
//         ),
//         ItineraryActivity(
//           time: '13:30',
//           title: 'Lakeside Lunch',
//           description: 'Fresh fish and mountain views',
//           imageUrl: 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=400&q=80',
//           tags: ['Food', 'Scenic'],
//         ),
//         ItineraryActivity(
//           time: '16:00',
//           title: 'World Peace Pagoda',
//           description: 'Sunset hike to the white stupa',
//           imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
//           tags: ['Hike', 'Sunset'],
//         ),
//       ],
//     ),
//     ItineraryDay(
//       dayNumber: 4,
//       title: 'Sarangkot & Departure',
//       badge: 'Easy Pace',
//       activities: [
//         ItineraryActivity(
//           time: '05:00',
//           title: 'Sarangkot Sunrise',
//           description: 'Panoramic Himalayan sunrise view',
//           imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=400&q=80',
//           tags: ['Nature', 'Must-see'],
//         ),
//         ItineraryActivity(
//           time: '09:00',
//           title: 'Paragliding',
//           description: 'Tandem flight over Pokhara valley',
//           imageUrl: 'https://images.unsplash.com/photo-1503220317375-aaad61436b1b?auto=format&fit=crop&w=400&q=80',
//           tags: ['Adventure', 'Thrill'],
//         ),
//         ItineraryActivity(
//           time: '13:00',
//           title: 'Farewell Momo',
//           description: 'Last taste of Nepali dumplings',
//           imageUrl: 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?auto=format&fit=crop&w=400&q=80',
//           tags: ['Food'],
//         ),
//         ItineraryActivity(
//           time: '16:00',
//           title: 'Departure Window',
//           description: 'Buffer for return flight to Kathmandu',
//           imageUrl: 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?auto=format&fit=crop&w=400&q=80',
//           tags: ['Logistics'],
//         ),
//       ],
//     ),
//   ];

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
//                   GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: const Row(
//                       children: [
//                         Icon(Icons.chevron_left, color: AppColors.text, size: 24),
//                         Text(
//                           'Back',
//                           style: TextStyle(
//                             color: AppColors.text,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   const Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Itinerary',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w700,
//                           fontSize: 18,
//                         ),
//                       ),
//                       Text(
//                         'AI plan preview • Edit before saving',
//                         style: TextStyle(
//                           color: AppColors.subtext,
//                           fontSize: 13,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const Spacer(),
//                   const CircleAvatar(
//                     radius: 18,
//                     backgroundImage: NetworkImage(
//                       'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=60',
//                     ),
//                   ),
//                   const SizedBox(width: 12),
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

//             // Scrollable content
//             Expanded(
//               child: SingleChildScrollView(
//                 physics: const BouncingScrollPhysics(),
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Destination dropdown
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: AppColors.stroke),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.location_on_outlined, color: AppColors.subtext, size: 20),
//                           const SizedBox(width: 10),
//                           const Text(
//                             'Destination: Kathmandu, Nepal',
//                             style: TextStyle(
//                               fontSize: 15,
//                               color: AppColors.text,
//                             ),
//                           ),
//                           const Spacer(),
//                           Icon(Icons.keyboard_arrow_down, color: AppColors.subtext),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 14),

//                     // Trip info chips
//                     Wrap(
//                       spacing: 10,
//                       runSpacing: 10,
//                       children: [
//                         _InfoChip(icon: Icons.calendar_today_outlined, label: '4 days'),
//                         _InfoChip(icon: Icons.people_outline, label: '2 travelers'),
//                         _InfoChip(icon: Icons.account_balance_wallet_outlined, label: 'Mid budget'),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     Wrap(
//                       spacing: 10,
//                       children: [
//                         _InfoChip(
//                           icon: Icons.auto_awesome,
//                           label: 'Culture • Adventure',
//                           highlight: true,
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 20),

//                     // Days
//                     ..._itinerary.map((day) => _DayCard(day: day)),

//                     const SizedBox(height: 20),

//                     // Action buttons
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton.icon(
//                         onPressed: () {},
//                         icon: const Icon(Icons.save_outlined, size: 20),
//                         label: const Text(
//                           'Save this plan',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w600,
//                             fontSize: 16,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.primary,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 12),

//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton.icon(
//                         onPressed: () {},
//                         icon: const Icon(Icons.auto_fix_high, size: 20, color: AppColors.primary),
//                         label: const Text(
//                           'Regenerate',
//                           style: TextStyle(
//                             color: AppColors.primary,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 16,
//                           ),
//                         ),
//                         style: OutlinedButton.styleFrom(
//                           side: const BorderSide(color: AppColors.stroke),
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 100),
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

// class _InfoChip extends StatelessWidget {
//   const _InfoChip({
//     required this.icon,
//     required this.label,
//     this.highlight = false,
//   });

//   final IconData icon;
//   final String label;
//   final bool highlight;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//       decoration: BoxDecoration(
//         color: highlight ? const Color(0xFFE6F6EE) : Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: highlight ? AppColors.primary : AppColors.stroke,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             icon,
//             size: 16,
//             color: highlight ? AppColors.primary : AppColors.subtext,
//           ),
//           const SizedBox(width: 6),
//           Text(
//             label,
//             style: TextStyle(
//               color: highlight ? AppColors.primary : AppColors.text,
//               fontWeight: FontWeight.w500,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DayCard extends StatelessWidget {
//   const _DayCard({required this.day});

//   final ItineraryDay day;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(16),
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
//           // Day header
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   'Day ${day.dayNumber} • ${day.title}',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w700,
//                     fontSize: 17,
//                   ),
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFE6F6EE),
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: Text(
//                   day.badge,
//                   style: const TextStyle(
//                     color: AppColors.primary,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 16),

//           // Activities
//           ...day.activities.map((activity) => _ActivityItem(activity: activity)),
//         ],
//       ),
//     );
//   }
// }

// class _ActivityItem extends StatelessWidget {
//   const _ActivityItem({required this.activity});

//   final ItineraryActivity activity;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Time
//           SizedBox(
//             width: 50,
//             child: Text(
//               activity.time,
//               style: const TextStyle(
//                 color: AppColors.subtext,
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),

//           // Image
//           ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child: Image.network(
//               activity.imageUrl,
//               width: 64,
//               height: 64,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) => Container(
//                 width: 64,
//                 height: 64,
//                 decoration: BoxDecoration(
//                   color: AppColors.stroke,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Icon(Icons.image, color: AppColors.subtext),
//               ),
//             ),
//           ),

//           const SizedBox(width: 12),

//           // Content
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   activity.title,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w700,
//                     fontSize: 15,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   activity.description,
//                   style: const TextStyle(
//                     color: AppColors.subtext,
//                     fontSize: 13,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Wrap(
//                   spacing: 6,
//                   runSpacing: 6,
//                   children: activity.tags.map((tag) => Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: AppColors.stroke),
//                     ),
//                     child: Text(
//                       tag,
//                       style: const TextStyle(
//                         color: AppColors.subtext,
//                         fontSize: 12,
//                       ),
//                     ),
//                   )).toList(),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
