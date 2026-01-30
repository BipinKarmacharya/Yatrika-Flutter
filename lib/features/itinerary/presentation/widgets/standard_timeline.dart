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
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = dailyItems[index]; // item is defined HERE

          return TimelineActivityCard(
            item: item,
            order: index + 1,
            canEdit: isOwner,
            isEditing: isEditing,
            // Logic must stay inside this block to access 'item'
            onToggleVisited: isOwner
                ? (bool? newValue) {
                    if (item.id != null && newValue != null) {
                      onToggleVisited(item.id!, newValue);
                    }
                  }
                : null,
            onEditNotes: () {},
            onDeleteActivity: () {},
            onChangeTime: () {},
            onReorder: () {},
          );
        }, childCount: dailyItems.length),
      ),
    );
  }
}
