import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:tour_guide/features/plan/data/service/ml_service.dart';
import '../../../../core/theme/app_colors.dart';

class ItineraryScreen extends StatefulWidget {
  final Map<String, List<String>> itineraryData;
  final String city;
  final int days;
  final String budget;
  final List<String> interests;
  final DateTime startDate;

  const ItineraryScreen({
    super.key,
    required this.itineraryData,
    required this.city,
    required this.days,
    required this.budget,
    required this.interests,
    required this.startDate,
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
        startDate: widget.startDate,
        itineraryData: widget.itineraryData,
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip added to your library!'), 
          backgroundColor: Color(0xFF10B981)
        ),
      );
      
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedDays = widget.itineraryData.keys.toList()
      ..sort((a, b) {
        int numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        int numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return numA.compareTo(numB);
      });

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('AI Itinerary Preview', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeaderCard(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: sortedDays.length,
              itemBuilder: (context, index) {
                final dayKey = sortedDays[index];
                final places = widget.itineraryData[dayKey] ?? [];
                final dayDate = widget.startDate.add(Duration(days: index));

                return _buildDaySection(index + 1, dayDate, places);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Text(widget.city, 
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoChip(Icons.calendar_month, '${widget.days} Days'),
              const SizedBox(width: 12),
              _infoChip(Icons.savings_outlined, widget.budget),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: widget.interests.take(3).map((vibe) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text("#$vibe", style: const TextStyle(fontSize: 11, color: AppColors.primary)),
            )).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildDaySection(int dayNum, DateTime date, List<String> places) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Text("Day $dayNum", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(DateFormat('EEEE, MMM d').format(date), 
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ],
          ),
        ),
        ...places.asMap().entries.map((entry) => _buildTimelineItem(entry.value, entry.key == places.length - 1)),
      ],
    );
  }

  Widget _buildTimelineItem(String place, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              const Icon(Icons.radio_button_checked, size: 20, color: AppColors.primary),
              if (!isLast) Expanded(child: VerticalDivider(color: AppColors.primary.withOpacity(0.3), thickness: 2)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Text(place, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _savePlan,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSaving 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("USE THIS PLAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:tour_guide/features/plan/data/service/ml_service.dart';
// import '../../../../core/theme/app_colors.dart';

// class ItineraryScreen extends StatefulWidget {
//   final Map<String, List<String>> itineraryData;
//   final String city;
//   final int days;
//   final String budget;
//   final List<String> interests;
//   final DateTime startDate;

//   const ItineraryScreen({
//     super.key,
//     required this.itineraryData,
//     required this.city,
//     required this.days,
//     required this.budget,
//     required this.interests,
//     required this.startDate,
//   });

//   @override
//   State<ItineraryScreen> createState() => _ItineraryScreenState();
// }

// class _ItineraryScreenState extends State<ItineraryScreen> {
//   bool _isSaving = false;

//   Future<void> _savePlan() async {
//     setState(() => _isSaving = true);
//     try {
//       await MLService.savePlan(
//         city: widget.city,
//         budget: widget.budget,
//         interests: widget.interests,
//         days: widget.days,
//         startDate: widget.startDate,
//         itineraryData: widget.itineraryData,
//       );

//       if (!mounted) return;
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Trip saved to My Plans!'), backgroundColor: AppColors.primary),
//       );
      
//       // Optionally navigate to the main Itinerary list or home
//       Navigator.popUntil(context, (route) => route.isFirst);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.redAccent),
//       );
//     } finally {
//       if (mounted) setState(() => _isSaving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Sort keys to ensure Day 1 comes before Day 2
//     final sortedDays = widget.itineraryData.keys.toList()
//       ..sort((a, b) {
//         int numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
//         int numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
//         return numA.compareTo(numB);
//       });

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: Text('Trip to ${widget.city}'),
//         backgroundColor: Colors.white,
//         foregroundColor: AppColors.text,
//         elevation: 0,
//       ),
//       body: Column(
//         children: [
//           // Header info
//           Container(
//             padding: const EdgeInsets.all(16),
//             color: Colors.white,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _infoChip(Icons.calendar_today, '${widget.days} Days'),
//                 _infoChip(Icons.payments_outlined, widget.budget),
//                 _infoChip(Icons.auto_awesome, 'AI Generated'),
//               ],
//             ),
//           ),
//           const Divider(height: 1),
          
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: sortedDays.length,
//               itemBuilder: (context, index) {
//                 final dayKey = sortedDays[index];
//                 final places = widget.itineraryData[dayKey] ?? [];

//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 16),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   child: ExpansionTile(
//                     initiallyExpanded: index == 0,
//                     leading: CircleAvatar(
//                       backgroundColor: AppColors.primary.withOpacity(0.1),
//                       child: Text('${index + 1}', style: const TextStyle(color: AppColors.primary)),
//                     ),
//                     title: Text(dayKey, style: const TextStyle(fontWeight: FontWeight.bold)),
//                     subtitle: Text('${places.length} activities'),
//                     children: places.map((place) => ListTile(
//                       leading: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.subtext),
//                       title: Text(place),
//                       dense: true,
//                     )).toList(),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
//         ),
//         child: ElevatedButton(
//           onPressed: _isSaving ? null : _savePlan,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppColors.primary,
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           ),
//           child: _isSaving 
//             ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//             : const Text('Save to My Trips', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         ),
//       ),
//     );
//   }

//   Widget _infoChip(IconData icon, String label) {
//     return Row(
//       children: [
//         Icon(icon, size: 16, color: AppColors.primary),
//         const SizedBox(width: 4),
//         Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
//       ],
//     );
//   }
// }