import 'package:flutter/material.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';

class TimelineActivityCard extends StatelessWidget {
  final ItineraryItem item;
  final int order;
  final bool canEdit;
  final bool isEditing;
  final Function(bool)? onToggleVisited;
  final VoidCallback onEditNotes;
  final VoidCallback onDeleteActivity;
  final VoidCallback onChangeTime;
  final VoidCallback onReorder;

  const TimelineActivityCard({
    super.key,
    required this.item,
    required this.order,
    required this.canEdit,
    required this.isEditing,
    this.onToggleVisited,
    required this.onEditNotes,
    required this.onDeleteActivity,
    required this.onChangeTime,
    required this.onReorder,
  });

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'MEAL':
        return Icons.restaurant;
      case 'TRANSPORT':
        return Icons.directions_bus;
      case 'HOTEL':
        return Icons.hotel;
      case 'VISIT':
        return Icons.camera_alt;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Time and Dot
          _buildTimelineSide(),
          const SizedBox(width: 20),

          // Right Side: Content Card
          Expanded(child: _buildActivityCard()),
        ],
      ),
    );
  }

  Widget _buildTimelineSide() {
    return Column(
      children: [
        Text(
          item.startTime.substring(0, 5),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: item.isVisited ? Colors.grey : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          width: 12,
          decoration: BoxDecoration(
            color: item.isVisited ? Colors.grey : const Color(0xFF009688),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
        ),
        Container(width: 2, height: 100, color: Colors.grey[200]),
      ],
    );
  }

  Widget _buildActivityCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isVisited ? Colors.grey[200]! : Colors.teal[50]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderRow(),
          if (item.title != item.destination?['name']) _buildSubtitle(),
          _buildNotesSection(),
          if (isEditing) _buildEditActions(),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(
          _getIconForType(item.activityType),
          size: 18,
          color: item.isVisited ? Colors.grey : const Color(0xFF009688),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.destination?['name'] ?? item.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              decoration: item.isVisited ? TextDecoration.lineThrough : null,
              color: item.isVisited ? Colors.grey : Colors.black,
            ),
          ),
        ),
        if (canEdit && !isEditing)
          Transform.scale(
            scale: 0.8,
            child: onToggleVisited == null
                ? const Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: Colors.grey,
                  ) // Show lock when disabled
                : Checkbox(
                    activeColor: const Color(0xFF009688),
                    value: item.isVisited,
                    onChanged: (val) => onToggleVisited!(val ?? false),
                  ),
          ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Column(
      children: [
        const SizedBox(height: 2),
        Text(
          item.title,
          style: TextStyle(
            color: Colors.teal[700],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        item.notes ?? "Explore this location",
        style: TextStyle(
          color: Colors.grey,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildEditActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onChangeTime,
            icon: const Icon(Icons.access_time, size: 16),
            label: const Text("Change Time"),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF009688),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.edit_note, color: Colors.teal[300], size: 22),
            onPressed: onEditNotes,
            tooltip: "Edit Notes",
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 22,
            ),
            onPressed: onDeleteActivity,
            tooltip: "Delete Activity",
          ),
        ],
      ),
    );
  }
}
