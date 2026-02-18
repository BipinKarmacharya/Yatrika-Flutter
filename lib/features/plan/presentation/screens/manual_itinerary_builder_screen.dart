import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/plan/logic/trip_creator_provider.dart';
import '../../../itinerary/data/models/itinerary_item.dart';
import '../../../itinerary/data/services/itinerary_service.dart';
import '../../../itinerary/presentation/widgets/day_selector.dart';
import '../../../itinerary/presentation/widgets/dialogs/add_activity_dialog.dart';
import '../../../itinerary/presentation/widgets/edit_mode_timeline.dart';

class ManualItineraryBuilderScreen extends StatefulWidget {
  const ManualItineraryBuilderScreen({super.key});

  @override
  State<ManualItineraryBuilderScreen> createState() =>
      _ManualItineraryBuilderScreenState();
}

class _ManualItineraryBuilderScreenState
    extends State<ManualItineraryBuilderScreen> {
  int _selectedDay = 1;

  void _showAddActivity() async {
    final provider = context.read<TripCreatorProvider>();
    try {
      final allDestinations = await ItineraryService.getAllDestinations();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AddActivityDialog(
          availableDestinations: allDestinations,
          onDestinationSelected: (data) {
            final dest = data['destination'];

            final newItem = ItineraryItem(
              title: dest['name'] ?? 'New Stop',
              destinationId: dest['id'],
              dayNumber: _selectedDay,
              // Calculate order based on items already in the draft for this day
              orderInDay:
                  (provider.draftItinerary?.items
                          ?.where((i) => i.dayNumber == _selectedDay)
                          .length ??
                      0) +
                  1,
              startTime: data['startTime'], // From Dialog
              notes: data['notes'] ?? "", // From Dialog
              activityType: data['activityType'] ?? "VISIT", // For Backend
              destination: dest,
            );
            provider.addActivity(newItem);
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading destinations: $e")));
    }
  }

  void _handleTimeChange(ItineraryItem item) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(item.startTime.split(":")[0]),
        minute: int.parse(item.startTime.split(":")[1]),
      ),
    );

    if (picked != null) {
      final formattedTime =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";

      // This now matches the method in your Provider
      final updatedItem = item.copyWith(startTime: formattedTime);
      context.read<TripCreatorProvider>().updateActivity(updatedItem);
    }
  }

  void _handleSave() async {
    final provider = context.read<TripCreatorProvider>();

    if (provider.draftItinerary?.items == null ||
        provider.draftItinerary!.items!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least one activity before saving."),
        ),
      );
      return;
    }

    final result = await provider.saveTripToBackend();

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Trip created successfully! Check 'My Plans'"),
        ),
      );
      // Navigate back to the main screen / profile
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save trip. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripCreatorProvider>();
    final draft = provider.draftItinerary;

    if (draft == null) {
      return const Scaffold(body: Center(child: Text("No draft found")));
    }

    // Filter items for the currently selected day
    final dailyItems =
        draft.items?.where((i) => i.dayNumber == _selectedDay).toList() ?? [];
    dailyItems.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      appBar: AppBar(
        title: Text("Building: ${draft.title}"),
        actions: [
          if (provider.isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _handleSave,
              child: const Text(
                "FINISH",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. Day Selection Area
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                DaySelector(
                  totalDays: draft.totalDays ?? 1,
                  selectedDay: _selectedDay,
                  startDate: draft.startDate,
                  onDaySelected: (day) => setState(() => _selectedDay = day),
                ),
                const SizedBox(height: 8),
                // 2. THE NEW DATE LABEL
                Text(
                  _getDateLabel(_selectedDay, draft.startDate),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 3. Timeline Area
          Expanded(
            child: dailyItems.isEmpty
                ? _buildEmptyState()
                : CustomScrollView(
                    slivers: [
                      EditModeTimeline(
                        dailyItems: dailyItems,
                        onReorder: (oldIdx, newIdx) =>
                            provider.reorderActivities(oldIdx, newIdx),
                        onToggleVisited: (_, __) {},
                        onEditNotes: (item) {
                          /* Show NoteEditorDialog */
                        },
                        onDeleteActivity: (item) {
                          final idx = draft.items!.indexOf(item);
                          provider.removeActivity(idx);
                        },
                        onChangeTime: (item) => _handleTimeChange(item),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddActivity,
        backgroundColor: const Color(0xFF009688),
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text("Add Stop", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No activities planned for Day $_selectedDay",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const Text("Tap 'Add Stop' to begin."),
        ],
      ),
    );
  }

  String _getDateLabel(int dayNumber, DateTime? startDate) {
    if (startDate == null) return "Plan your activities";

    final targetDate = startDate.add(Duration(days: dayNumber - 1));
    final weekdays = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
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

    return "${weekdays[targetDate.weekday]}, ${months[targetDate.month]} ${targetDate.day}";
  }
}
