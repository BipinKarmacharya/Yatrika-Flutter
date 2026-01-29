import 'package:flutter/material.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';
import 'timeline_activity_card.dart';

class EditModeTimeline extends StatelessWidget {
  final List<ItineraryItem> dailyItems;
  final Function(int, int) onReorder;
  final Function(int, bool) onToggleVisited;
  final Function(ItineraryItem) onEditNotes;
  final Function(ItineraryItem) onDeleteActivity;
  final Function(ItineraryItem) onChangeTime;

  const EditModeTimeline({
    super.key,
    required this.dailyItems,
    required this.onReorder,
    required this.onToggleVisited,
    required this.onEditNotes,
    required this.onDeleteActivity,
    required this.onChangeTime,
  });

  @override
  Widget build(BuildContext context) {
    return SliverReorderableList(
      itemCount: dailyItems.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final item = dailyItems[index];
        return ReorderableDelayedDragStartListener(
          index: index,
          key: ValueKey(item.id ?? 'temp_$index'),
          child: TimelineActivityCard(
            item: item,
            order: index + 1,
            canEdit: true,
            isEditing: true,
            onToggleVisited: () => onToggleVisited(item.id!, item.isVisited),
            onEditNotes: () => onEditNotes(item),
            onDeleteActivity: () => onDeleteActivity(item),
            onChangeTime: () => onChangeTime(item),
            onReorder: () {}, // Not needed here as SliverReorderableList handles it
          ),
        );
      },
    );
  }
}