import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/day_selector.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/finish_trip_button.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/completed_section.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/incomplete_hint.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/progress_stats.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/quick_stats.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/trip_description_card.dart';

class ItineraryDetailContent extends StatelessWidget {
  final bool isOwner;
  final bool isEditing;
  final bool isCompleted;
  final String? currentDescription;
  final List<ItineraryItem> tempItems;
  final Itinerary itinerary;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;
  final VoidCallback onFinishTrip;
  final VoidCallback onShare;
  final VoidCallback onUnshare;
  final Itinerary currentTrip;
  final VoidCallback? onAddDay;
  final VoidCallback? onRemoveDay;

  const ItineraryDetailContent({
    super.key,
    required this.isOwner,
    required this.isEditing,
    required this.isCompleted,
    required this.currentDescription,
    required this.tempItems,
    required this.itinerary,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onFinishTrip,
    required this.onShare,
    required this.onUnshare,
    required this.currentTrip,
    this.onAddDay,
    this.onRemoveDay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ownership & Completion Controls
          if (isOwner) ...[
            if (isCompleted)
              CompletedSection(
                currentTrip: currentTrip,
                onShare: onShare,
                onUnshare: onUnshare,
              )
            else if (_meetsCompletionThreshold(tempItems))
              FinishTripButton(onPressed: onFinishTrip)
            else
              IncompleteHint(items: tempItems),
            const SizedBox(height: 16),
          ],

          // Description
          if (currentDescription != null && currentDescription!.isNotEmpty) ...[
            TripDescriptionCard(description: currentDescription!),
            const SizedBox(height: 20),
          ],

          // Stats (Progress & Quick Stats)
          Consumer<ItineraryProvider>(
            builder: (context, provider, child) {
              final updatedItinerary = provider.myPlans.firstWhere(
                (p) => p.id == itinerary.id,
                orElse: () => itinerary,
              );
              final items = updatedItinerary.items ?? tempItems;
              return ProgressStats.forDetailScreen(
                items: items,
                title: "Trip Progress",
              );
            },
          ),
          QuickStats(itinerary: itinerary),
          const SizedBox(height: 24),

          // Day Selection Area
          Row(
            children: [
              Expanded(
                child: DaySelector(
                  totalDays: itinerary.totalDays ?? 1,
                  selectedDay: selectedDay,
                  startDate: itinerary.startDate,
                  onDaySelected: onDaySelected,
                ),
              ),
              if (isEditing) ...[
                // Minus Button
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: (itinerary.totalDays ?? 1) > 1
                      ? onRemoveDay
                      : null,
                  tooltip: "Remove Last Day",
                ),
                // Plus Button
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF009688),
                  ),
                  onPressed: onAddDay,
                  tooltip: "Add Day",
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // ADDED: DATE HEADER (The link between selector and timeline)
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF009688),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatFullDate(selectedDay, itinerary.startDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (itinerary.startDate != null)
            Text(
              "Day $selectedDay",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
        ],
      ),
    );
  }

  bool _meetsCompletionThreshold(List<ItineraryItem> items) {
    if (items.isEmpty) return false;
    final visitedCount = items.where((i) => i.isVisited == true).length;
    return (visitedCount / items.length) >= 0.8;
  }

  String _formatFullDate(int dayNumber, DateTime? startDate) {
    if (startDate == null) return "Day $dayNumber Activities";

    final actualDate = startDate.add(Duration(days: dayNumber - 1));
    final weekdays = [
      "",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    final months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return "${weekdays[actualDate.weekday]}, ${months[actualDate.month]} ${actualDate.day}";
  }
}
