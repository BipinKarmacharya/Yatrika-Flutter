import 'package:flutter/material.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';
import 'timeline_activity_card.dart';

class StandardTimeline extends StatelessWidget {
  final List<ItineraryItem> dailyItems;
  final bool isOwner;
  final bool isEditing;
  final Function(int, bool) onToggleVisited;

  const StandardTimeline({
    super.key,
    required this.dailyItems,
    required this.isOwner,
    required this.isEditing,
    required this.onToggleVisited,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = dailyItems[index];
            return TimelineActivityCard(
              item: item,
              order: index + 1,
              canEdit: isOwner,
              isEditing: isEditing,
              onToggleVisited: () => onToggleVisited(item.id!, item.isVisited),
              onEditNotes: () {}, // Not available in standard mode
              onDeleteActivity: () {}, // Not available in standard mode
              onChangeTime: () {}, // Not available in standard mode
              onReorder: () {}, // Not available in standard mode
            );
          },
          childCount: dailyItems.length,
        ),
      ),
    );
  }
}