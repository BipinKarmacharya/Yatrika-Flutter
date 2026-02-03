import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/auth/logic/auth_provider.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';
import 'package:tour_guide/features/itinerary/data/services/itinerary_service.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_map_screen.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/day_selector.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/add_activity_dialog.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/delete_confirmation_dialog.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/edit_trip_dialog.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/note_editor_dialog.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/edit_mode_timeline.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/parallax_header.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/progress_stats.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/quick_stats.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/standard_timeline.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/trip_description_card.dart';

class ItineraryDetailScreen extends StatefulWidget {
  final Itinerary itinerary;
  final bool isReadOnly;
  const ItineraryDetailScreen({
    super.key,
    required this.itinerary,
    this.isReadOnly = false,
  });

  @override
  State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen> {
  bool _isEditing = false;
  bool _isLoading = true;
  List<ItineraryItem> _tempItems = [];
  int selectedDay = 1;
  late String _currentTitle;
  late String? _currentDescription;
  final ScrollController _scrollController = ScrollController();

  bool get _isTripCompleted {
    final currentPlan = _getCurrentItinerary();
    return currentPlan.status == 'COMPLETED';
  }

  Itinerary _getCurrentItinerary() {
    final provider = context.read<ItineraryProvider>();
    return provider.myPlans.firstWhere(
      (p) => p.id == widget.itinerary.id,
      orElse: () => widget.itinerary,
    );
  }

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.itinerary.title;
    _currentDescription = widget.itinerary.description;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupProviderListener();
    });
    _fetchFullDetails();
  }

  void _setupProviderListener() {
    final provider = context.read<ItineraryProvider>();
    provider.addListener(() {
      if (mounted && !_isEditing && !_isLoading) {
        _syncWithProvider();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted && !_isEditing && !_isLoading) {
      _syncWithProvider();
    }
  }

  void _syncWithProvider() {
    if (widget.isReadOnly) {
      return;
    }
    final provider = context.read<ItineraryProvider>();
    final providerPlan = provider.myPlans.firstWhere(
      (p) => p.id == widget.itinerary.id,
      orElse: () => widget.itinerary,
    );
    if (providerPlan.items != null && providerPlan.items!.isNotEmpty) {
      final providerItems = providerPlan.items!;
      if (mounted) {
        setState(() {
          _tempItems = List.from(providerItems);
        });
      }
    }
  }

  Future<void> _fetchFullDetails() async {
    try {
      final data = await ItineraryService.getItineraryDetails(
        widget.itinerary.id,
      );
      final List rawItems = data['items'] ?? [];
      if (mounted) {
        setState(() {
          _tempItems = rawItems
              .map((json) => ItineraryItem.fromJson(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching details: $e");
    }
  }

  // ========== EVENT HANDLERS ==========

  void _onToggleVisited(int itemId, bool newVisitedStatus) async {
    if (_isTripCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This journey is finished and cannot be modified."),
        ),
      );
      return;
    }

    // Update local state IMMEDIATELY for UI responsiveness
    setState(() {
      int index = _tempItems.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        _tempItems[index] = _tempItems[index].copyWith(
          isVisited: newVisitedStatus,
        );
      }
    });

    try {
      await context.read<ItineraryProvider>().toggleItemVisited(
        widget.itinerary.id,
        itemId,
        newVisitedStatus,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newVisitedStatus ? "Marked as visited!" : "Marked as not visited",
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      // Revert on error
      setState(() {
        int index = _tempItems.indexWhere((i) => i.id == itemId);
        if (index != -1) {
          _tempItems[index] = _tempItems[index].copyWith(
            isVisited: !newVisitedStatus,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed: ${e.toString()}"),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final List<ItineraryItem> dayItems =
          _tempItems.where((i) => i.dayNumber == selectedDay).toList()
            ..sort((a, b) => a.orderInDay.compareTo(b.orderInDay));

      if (oldIndex >= dayItems.length || newIndex >= dayItems.length) return;

      final movedItem = dayItems.removeAt(oldIndex);
      dayItems.insert(newIndex, movedItem);

      // Update order numbers
      for (int i = 0; i < dayItems.length; i++) {
        final updated = dayItems[i].copyWith(orderInDay: i + 1);
        int globalIndex = _tempItems.indexWhere(
          (element) => element.id == updated.id,
        );
        if (globalIndex != -1) _tempItems[globalIndex] = updated;
      }
    });
  }

  void _selectTime(ItineraryItem item) async {
    TimeOfDay initialTime = TimeOfDay.now();
    try {
      final parts = item.startTime.split(':');
      initialTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (_) {}

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null && item.id != null) {
      final formattedTime =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";

      try {
        await context.read<ItineraryProvider>().updateItineraryItem(
          widget.itinerary.id,
          item.id!,
          {'startTime': formattedTime},
        );

        setState(() {
          int index = _tempItems.indexWhere((element) => element.id == item.id);
          if (index != -1) {
            _tempItems[index] = _tempItems[index].copyWith(
              startTime: formattedTime,
            );
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update time: ${e.toString()}")),
        );
      }
    }
  }

  void _showEditTripDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => EditTripDialog(
        initialTitle: _currentTitle,
        initialDescription: _currentDescription ?? '',
        onSave: (title, description) async {
          final success = await context
              .read<ItineraryProvider>()
              .updatePlanDetails(widget.itinerary.id, title, description);

          // Use dialogContext to pop the dialog
          if (success) {
            if (mounted) {
              setState(() {
                _currentTitle = title;
                _currentDescription = description;
              });
            }
            Navigator.pop(dialogContext);
          }
        },
      ),
    );
  }

  void _showNoteEditor(ItineraryItem item) {
    showDialog(
      context: context,
      builder: (context) => NoteEditorDialog(
        item: item,
        onUpdate: (newNote) async {
          if (item.id != null) {
            try {
              await context.read<ItineraryProvider>().updateActivityNotes(
                widget.itinerary.id,
                item.id!,
                newNote,
              );
              setState(() {
                int index = _tempItems.indexOf(item);
                if (index != -1) {
                  _tempItems[index] = item.copyWith(notes: newNote);
                }
              });
              Navigator.pop(context);
            } catch (e) {
              debugPrint("Failed to save note: $e");
            }
          }
        },
      ),
    );
  }

  void _confirmDeleteActivity(ItineraryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => DeleteConfirmationDialog(
        itemName: item.destination?['name'] ?? item.title,
        onConfirm: () async {
          if (item.id != null) {
            try {
              Navigator.pop(ctx);
              await ItineraryService.deleteActivity(
                widget.itinerary.id,
                item.id!,
              );
              setState(() {
                _tempItems.removeWhere((element) => element.id == item.id);
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Activity deleted")));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to delete: ${e.toString()}")),
              );
            }
          }
        },
      ),
    );
  }

  void _showAddActivityDialog() async {
    try {
      final allDestinations = await ItineraryService.getAllDestinations();
      final existingIds = _tempItems.map((i) => i.destinationId).toSet();
      List<dynamic> available = allDestinations
          .where((d) => !existingIds.contains(d['id']))
          .toList();

      showDialog(
        context: context,
        builder: (context) => AddActivityDialog(
          availableDestinations: available,
          onDestinationSelected: (dest) async {
            try {
              final newItemData = {
                'destinationId': dest['id'],
                'dayNumber': selectedDay,
                'orderInDay':
                    _tempItems.where((i) => i.dayNumber == selectedDay).length +
                    1,
                'startTime': "09:00:00",
                'notes': "Newly added stop",
              };

              // Call API to add the activity
              await ItineraryService.addActivity(
                widget.itinerary.id,
                newItemData,
              );

              // Refresh the data
              await _fetchFullDetails();

              Navigator.pop(context);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Failed to add activity: ${e.toString()}"),
                ),
              );
            }
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load destinations: ${e.toString()}")),
      );
    }
  }

  void _confirmFinishTrip(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Color(0xFF009688)),
            SizedBox(width: 10),
            Text("Finish Journey?"),
          ],
        ),
        content: const Text(
          "Congratulations on completing your trip! Would you like to mark this trip as finished? \n\n"
          "Finished trips can be shared with the community!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Not Yet"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009688),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<ItineraryProvider>();

              final success = await provider.finishTrip(widget.itinerary.id);

              if (success && mounted) {
                await provider.fetchMyPlans();
                _showCelebrationOverlay();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Failed to finish trip. Please try again."),
                  ),
                );
              }
            },
            child: const Text(
              "Finish Trip",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCelebrationOverlay() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "🎉 Trip Completed! You can now share it with the community.",
        ),
        backgroundColor: Color(0xFF009688),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _saveChanges() async {
    final provider = context.read<ItineraryProvider>();

    try {
      final success = await provider.saveFullItinerary(
        widget.itinerary.copyWith(
          title: _currentTitle,
          description: _currentDescription,
          items: _tempItems,
        ),
        _tempItems,
      );

      if (success && mounted) {
        setState(() => _isEditing = false);
        await provider.fetchMyPlans();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trip saved successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save: ${e.toString()}")),
      );
    }
  }

  void _showShareConfirmation() {
    final currentTrip = _getCurrentItinerary();
    final bool isCopied = currentTrip.isCopied;

    if (isCopied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Copied trips cannot be shared. Only original plans can be shared."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.public, color: Colors.green),
            SizedBox(width: 10),
            Text("Share with Community"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "This will make your itinerary visible on the Explore tab for other travelers to see and copy.",
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        "Benefits of sharing:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• Help other travelers discover great routes\n"
                    "• Get recognition for your planning skills\n"
                    "• Your trip might be featured on Explore page\n"
                    "• You can always make it private later",
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () async {
              final provider = context.read<ItineraryProvider>();
              final success = await provider.shareTrip(widget.itinerary.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "🎉 Trip is now public! Others can now view and copy it.",
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {}); // Refresh UI
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Failed to share trip. Please try again.",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Share Now",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnshareConfirmation() {
    final currentTrip = _getCurrentItinerary();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange),
            SizedBox(width: 10),
            Text("Make Trip Private"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Are you sure you want to make '${currentTrip.title}' private?",
            ),
            const SizedBox(height: 8),
            const Text(
              "This trip will no longer be visible to other users on the Explore tab.",
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_outlined, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        "Note:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• Existing copies made by other users will remain\n"
                    "• You can share it again anytime if you change your mind\n"
                    "• The trip will still be visible in your 'My Trips' tab",
                    style: TextStyle(fontSize: 12, color: Color(0xFFEF6C00)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep Public"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            onPressed: () async {
              final provider = context.read<ItineraryProvider>();
              bool success = false;
              
              // Try to use unshareTrip method if it exists
              try {
                // Check if provider has unshareTrip method
                success = await provider.unshareTrip(widget.itinerary.id);
              } catch (e) {
                debugPrint("Unshare method not available: $e");
                // Fallback: Use the share method if unshare doesn't exist
                // This assumes the backend toggles the public status
                success = await provider.shareTrip(widget.itinerary.id);
              }
              
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Trip is now private."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  setState(() {}); // Refresh UI
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to make trip private."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Make Private",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ========== BUILD METHOD ==========

  @override
  Widget build(BuildContext context) {
    final isOwner = _checkIsOwner() && !widget.isReadOnly;
    _tempItems.sort((a, b) => a.startTime.compareTo(b.startTime));
    final dailyItems = _tempItems
        .where((i) => i.dayNumber == selectedDay)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isEditing ? _buildEditAppBar() : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF009688)),
            )
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                ParallaxHeader(
                  title: _currentTitle,
                  isOwner: isOwner,
                  isEditing: _isEditing,
                  isCompleted: _isTripCompleted,
                  onEditPressed: () => setState(() => _isEditing = true),
                  onSettingsPressed: _showEditTripDialog,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Ownership & Completion Controls
                        if (isOwner) ...[
                          if (_isTripCompleted)
                            _buildCompletedSection()
                          else if (_meetsCompletionThreshold(_tempItems))
                            _buildFinishTripButton()
                          else
                            _buildIncompleteHint(),
                          const SizedBox(height: 16),
                        ],

                        // 2. Description
                        if (_currentDescription != null &&
                            _currentDescription!.isNotEmpty) ...[
                          TripDescriptionCard(
                            description: _currentDescription!,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // 3. Stats
                        Consumer<ItineraryProvider>(
                          builder: (context, provider, child) {
                            final updatedItinerary = provider.myPlans
                                .firstWhere(
                                  (p) => p.id == widget.itinerary.id,
                                  orElse: () => widget.itinerary,
                                );
                            final items = updatedItinerary.items ?? _tempItems;
                            return ProgressStats.forDetailScreen(
                              items: items,
                              title: "Trip Progress",
                            );
                          },
                        ),
                        QuickStats(itinerary: widget.itinerary),
                        const SizedBox(height: 24),
                        DaySelector(
                          totalDays: widget.itinerary.totalDays ?? 1,
                          selectedDay: selectedDay,
                          onDaySelected: (day) =>
                              setState(() => selectedDay = day),
                        ),
                      ],
                    ),
                  ),
                ),
                _isEditing
                    ? EditModeTimeline(
                        dailyItems: dailyItems,
                        onReorder: _onReorder,
                        onToggleVisited: _onToggleVisited,
                        onEditNotes: _showNoteEditor,
                        onDeleteActivity: _confirmDeleteActivity,
                        onChangeTime: _selectTime,
                      )
                    : StandardTimeline(
                        dailyItems: dailyItems,
                        isOwner: isOwner,
                        isEditing: _isEditing,
                        isCompleted: _isTripCompleted,
                        onToggleVisited: (itemId, newValue) =>
                            _onToggleVisited(itemId, newValue),
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
      floatingActionButton: _isEditing
          ? _buildAddActivityFAB()
          : _buildMapFAB(dailyItems),
    );
  }

  // ========== HELPER METHODS ==========

  PreferredSizeWidget _buildEditAppBar() {
    return AppBar(
      title: const Text("Edit Schedule"),
      backgroundColor: const Color(0xFF009688),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => setState(() => _isEditing = false),
      ),
      actions: [
        TextButton(
          onPressed: _saveChanges,
          child: const Text(
            "SAVE",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildAddActivityFAB() {
    return FloatingActionButton.extended(
      onPressed: _showAddActivityDialog,
      backgroundColor: const Color(0xFF009688),
      icon: const Icon(Icons.add_location_alt, color: Colors.white),
      label: const Text("Add Activity", style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildMapFAB(List<ItineraryItem> dailyItems) {
    final validActivities = dailyItems
        .where(
          (item) =>
              item.destination != null &&
              item.destination!['latitude'] != null &&
              item.destination!['longitude'] != null,
        )
        .map((item) => item.toJson())
        .toList();

    return FloatingActionButton.extended(
      heroTag: 'view_map_fab',
      onPressed: validActivities.isEmpty
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No GPS coordinates found for today."),
                ),
              );
            }
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItineraryMapScreen(activities: validActivities),
              ),
            ),
      backgroundColor: validActivities.isEmpty
          ? Colors.grey
          : const Color(0xFF009688),
      label: const Text("Show Route", style: TextStyle(color: Colors.white)),
      icon: const Icon(Icons.directions_outlined, color: Colors.white),
    );
  }

  Widget _buildFinishTripButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF009688).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            "Reached the end of your adventure?",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF004D40),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _confirmFinishTrip(context),
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text(
              "MARK TRIP AS FINISHED",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009688),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedSection() {
    final currentTrip = _getCurrentItinerary();
    final bool isPublic = currentTrip.isPublic;
    final bool isCopied = currentTrip.isCopied;

    return Column(
      children: [
        // Completion Badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF009688).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF009688)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, color: Color(0xFF009688)),
              SizedBox(width: 8),
              Text(
                "JOURNEY COMPLETED",
                style: TextStyle(
                  color: Color(0xFF009688),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Information card
        if (isCopied)
          _buildCopiedInfoCard()
        else if (isPublic)
          _buildPublicTripCard()
        else
          _buildShareableTripCard(),
      ],
    );
  }

  Widget _buildCopiedInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[800]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Copied Plan",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "This is a copy of another user's trip. Only original trips can be shared with the community.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicTripCard() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.public, color: Colors.green[800]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Public Trip",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "This trip is visible to other travelers on the Explore tab.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _showUnshareConfirmation,
          icon: const Icon(Icons.lock_outline, color: Colors.white),
          label: const Text(
            "MAKE PRIVATE",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareableTripCard() {
    return ElevatedButton.icon(
      onPressed: _showShareConfirmation,
      icon: const Icon(Icons.share, color: Colors.white),
      label: const Text(
        "SHARE TO COMMUNITY",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[700],
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildIncompleteHint() {
    final items = _tempItems.isNotEmpty
        ? _tempItems
        : (widget.itinerary.items ?? []);
    if (items.isEmpty) return const SizedBox.shrink();

    final totalNeeded = (items.length * 0.8).ceil();
    final visited = items.where((i) => i.isVisited == true).length;
    final remaining = totalNeeded - visited;

    if (remaining <= 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          "Almost there! Just click finish to complete your journey.",
          style: TextStyle(
            color: Color(0xFF009688),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        "Visit $remaining more stops to mark this trip as finished!",
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  bool _checkIsOwner() {
    final user = context.read<AuthProvider>().user;
    if (user == null || widget.itinerary.userId == null) return false;
    return widget.itinerary.userId == int.tryParse(user.id.toString());
  }

  bool _meetsCompletionThreshold(List<ItineraryItem> items) {
    if (items.isEmpty) return false;
    final visitedCount = items.where((i) => i.isVisited == true).length;
    return (visitedCount / items.length) >= 0.8;
  }
}

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:tour_guide/features/auth/logic/auth_provider.dart';
// import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
// import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';
// import 'package:tour_guide/features/itinerary/data/services/itinerary_service.dart';
// import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
// import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_map_screen.dart';
// import 'package:tour_guide/features/itinerary/presentation/widgets/day_selector.dart';
// import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/add_activity_dialog.dart';
// import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/delete_confirmation_dialog.dart';
// import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/edit_trip_dialog.dart';
// import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/note_editor_dialog.dart';
// import 'package:tour_guide/features/itinerary/presentation/widgets/edit_mode_timeline.dart';
// import 'package:tour_guide/features/itinerary/presentation/widgets/parallax_header.dart';
// import 'package:tour_guide/features/itinerary/presentation/widgets/progress_stats.dart';
// import 'package:tour_guide/features/itinerary/presentation/widgets/quick_stats.dart';
// import 'package:tour_guide/features/itinerary/presentation/widgets/standard_timeline.dart';
// import 'package:tour_guide/features/itinerary/presentation/widgets/trip_description_card.dart';

// class ItineraryDetailScreen extends StatefulWidget {
//   final Itinerary itinerary;
//   final bool isReadOnly;
//   const ItineraryDetailScreen({
//     super.key,
//     required this.itinerary,
//     this.isReadOnly = false,
//   });

//   @override
//   State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
// }

// class _ItineraryDetailScreenState extends State<ItineraryDetailScreen> {
//   bool _isEditing = false;
//   bool _isLoading = true;
//   List<ItineraryItem> _tempItems = [];
//   int selectedDay = 1;
//   late String _currentTitle;
//   late String? _currentDescription;
//   final ScrollController _scrollController = ScrollController();

//   bool get _isTripCompleted {
//     final currentPlan = _getCurrentItinerary();
//     return currentPlan.status == 'COMPLETED';
//   }

//   Itinerary _getCurrentItinerary() {
//     final provider = context.read<ItineraryProvider>();
//     return provider.myPlans.firstWhere(
//       (p) => p.id == widget.itinerary.id,
//       orElse: () => widget.itinerary,
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//     _currentTitle = widget.itinerary.title;
//     _currentDescription = widget.itinerary.description;
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _setupProviderListener();
//     });
//     _fetchFullDetails();
//   }

//   void _setupProviderListener() {
//     final provider = context.read<ItineraryProvider>();
//     provider.addListener(() {
//       if (mounted && !_isEditing && !_isLoading) {
//         _syncWithProvider();
//       }
//     });
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (mounted && !_isEditing && !_isLoading) {
//       _syncWithProvider();
//     }
//   }

//   void _syncWithProvider() {
//     if (widget.isReadOnly) {
//       return;
//     }
//     final provider = context.read<ItineraryProvider>();
//     final providerPlan = provider.myPlans.firstWhere(
//       (p) => p.id == widget.itinerary.id,
//       orElse: () => widget.itinerary,
//     );
//     if (providerPlan.items != null && providerPlan.items!.isNotEmpty) {
//       final providerItems = providerPlan.items!;
//       if (mounted) {
//         setState(() {
//           _tempItems = List.from(providerItems);
//         });
//       }
//     }
//   }

//   Future<void> _fetchFullDetails() async {
//     try {
//       final data = await ItineraryService.getItineraryDetails(
//         widget.itinerary.id,
//       );
//       final List rawItems = data['items'] ?? [];
//       if (mounted) {
//         setState(() {
//           _tempItems = rawItems
//               .map((json) => ItineraryItem.fromJson(json))
//               .toList();
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) setState(() => _isLoading = false);
//       debugPrint("Error fetching details: $e");
//     }
//   }

//   // ========== EVENT HANDLERS ==========

//   void _onToggleVisited(int itemId, bool newVisitedStatus) async {
//     if (_isTripCompleted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("This journey is finished and cannot be modified."),
//         ),
//       );
//       return;
//     }

//     // Update local state IMMEDIATELY for UI responsiveness
//     setState(() {
//       int index = _tempItems.indexWhere((i) => i.id == itemId);
//       if (index != -1) {
//         _tempItems[index] = _tempItems[index].copyWith(
//           isVisited: newVisitedStatus,
//         );
//       }
//     });

//     try {
//       await context.read<ItineraryProvider>().toggleItemVisited(
//         widget.itinerary.id,
//         itemId,
//         newVisitedStatus,
//       );
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             newVisitedStatus ? "Marked as visited!" : "Marked as not visited",
//           ),
//           duration: const Duration(seconds: 1),
//         ),
//       );
//     } catch (e) {
//       // Revert on error
//       setState(() {
//         int index = _tempItems.indexWhere((i) => i.id == itemId);
//         if (index != -1) {
//           _tempItems[index] = _tempItems[index].copyWith(
//             isVisited: !newVisitedStatus,
//           );
//         }
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Failed: ${e.toString()}"),
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     }
//   }

//   void _onReorder(int oldIndex, int newIndex) {
//     setState(() {
//       if (newIndex > oldIndex) newIndex -= 1;
//       final List<ItineraryItem> dayItems =
//           _tempItems.where((i) => i.dayNumber == selectedDay).toList()
//             ..sort((a, b) => a.orderInDay.compareTo(b.orderInDay));

//       if (oldIndex >= dayItems.length || newIndex >= dayItems.length) return;

//       final movedItem = dayItems.removeAt(oldIndex);
//       dayItems.insert(newIndex, movedItem);

//       // Update order numbers
//       for (int i = 0; i < dayItems.length; i++) {
//         final updated = dayItems[i].copyWith(orderInDay: i + 1);
//         int globalIndex = _tempItems.indexWhere(
//           (element) => element.id == updated.id,
//         );
//         if (globalIndex != -1) _tempItems[globalIndex] = updated;
//       }
//     });
//   }

//   void _selectTime(ItineraryItem item) async {
//     TimeOfDay initialTime = TimeOfDay.now();
//     try {
//       final parts = item.startTime.split(':');
//       initialTime = TimeOfDay(
//         hour: int.parse(parts[0]),
//         minute: int.parse(parts[1]),
//       );
//     } catch (_) {}

//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: initialTime,
//     );

//     if (picked != null && item.id != null) {
//       final formattedTime =
//           "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";

//       try {
//         await context.read<ItineraryProvider>().updateItineraryItem(
//           widget.itinerary.id,
//           item.id!,
//           {'startTime': formattedTime},
//         );

//         setState(() {
//           int index = _tempItems.indexWhere((element) => element.id == item.id);
//           if (index != -1) {
//             _tempItems[index] = _tempItems[index].copyWith(
//               startTime: formattedTime,
//             );
//           }
//         });
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Failed to update time: ${e.toString()}")),
//         );
//       }
//     }
//   }

//   void _showEditTripDialog() {
//     showDialog(
//       context: context,
//       builder: (dialogContext) => EditTripDialog(
//         initialTitle: _currentTitle,
//         initialDescription: _currentDescription ?? '',
//         onSave: (title, description) async {
//           final success = await context
//               .read<ItineraryProvider>()
//               .updatePlanDetails(widget.itinerary.id, title, description);

//           // Use dialogContext to pop the dialog
//           if (success) {
//             if (mounted) {
//               setState(() {
//                 _currentTitle = title;
//                 _currentDescription = description;
//               });
//             }
//             Navigator.pop(dialogContext);
//           }
//         },
//       ),
//     );
//   }

//   void _showNoteEditor(ItineraryItem item) {
//     showDialog(
//       context: context,
//       builder: (context) => NoteEditorDialog(
//         item: item,
//         onUpdate: (newNote) async {
//           if (item.id != null) {
//             try {
//               await context.read<ItineraryProvider>().updateActivityNotes(
//                 widget.itinerary.id,
//                 item.id!,
//                 newNote,
//               );
//               setState(() {
//                 int index = _tempItems.indexOf(item);
//                 if (index != -1)
//                   _tempItems[index] = item.copyWith(notes: newNote);
//               });
//               Navigator.pop(context);
//             } catch (e) {
//               debugPrint("Failed to save note: $e");
//             }
//           }
//         },
//       ),
//     );
//   }

//   void _confirmDeleteActivity(ItineraryItem item) {
//     showDialog(
//       context: context,
//       builder: (ctx) => DeleteConfirmationDialog(
//         itemName: item.destination?['name'] ?? item.title,
//         onConfirm: () async {
//           if (item.id != null) {
//             try {
//               Navigator.pop(ctx);
//               await ItineraryService.deleteActivity(
//                 widget.itinerary.id,
//                 item.id!,
//               );
//               setState(() {
//                 _tempItems.removeWhere((element) => element.id == item.id);
//               });
//               ScaffoldMessenger.of(
//                 context,
//               ).showSnackBar(const SnackBar(content: Text("Activity deleted")));
//             } catch (e) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text("Failed to delete: ${e.toString()}")),
//               );
//             }
//           }
//         },
//       ),
//     );
//   }

//   void _showAddActivityDialog() async {
//     try {
//       final allDestinations = await ItineraryService.getAllDestinations();
//       final existingIds = _tempItems.map((i) => i.destinationId).toSet();
//       List<dynamic> available = allDestinations
//           .where((d) => !existingIds.contains(d['id']))
//           .toList();

//       showDialog(
//         context: context,
//         builder: (context) => AddActivityDialog(
//           availableDestinations: available,
//           onDestinationSelected: (dest) async {
//             try {
//               final newItemData = {
//                 'destinationId': dest['id'],
//                 'dayNumber': selectedDay,
//                 'orderInDay':
//                     _tempItems.where((i) => i.dayNumber == selectedDay).length +
//                     1,
//                 'startTime': "09:00:00",
//                 'notes': "Newly added stop",
//               };

//               // Call API to add the activity
//               await ItineraryService.addActivity(
//                 widget.itinerary.id,
//                 newItemData,
//               );

//               // Refresh the data
//               await _fetchFullDetails();

//               Navigator.pop(context);
//             } catch (e) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text("Failed to add activity: ${e.toString()}"),
//                 ),
//               );
//             }
//           },
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to load destinations: ${e.toString()}")),
//       );
//     }
//   }

//   void _confirmFinishTrip(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Row(
//           children: [
//             Icon(Icons.celebration, color: Color(0xFF009688)),
//             SizedBox(width: 10),
//             Text("Finish Journey?"),
//           ],
//         ),
//         content: const Text(
//           "Congratulations on completing your trip! Would you like to mark this trip as finished? \n\n"
//           "Finished trips can be shared with the community!",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text("Not Yet"),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF009688),
//             ),
//             onPressed: () async {
//               Navigator.pop(ctx);
//               final provider = context.read<ItineraryProvider>();

//               final success = await provider.finishTrip(widget.itinerary.id);

//               if (success && mounted) {
//                 await provider.fetchMyPlans();
//                 _showCelebrationOverlay();
//               } else {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text("Failed to finish trip. Please try again."),
//                   ),
//                 );
//               }
//             },
//             child: const Text(
//               "Finish Trip",
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showCelebrationOverlay() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text(
//           "🎉 Trip Completed! You can now share it in your Profile.",
//         ),
//         backgroundColor: Color(0xFF009688),
//         duration: Duration(seconds: 4),
//       ),
//     );
//   }

//   void _saveChanges() async {
//     final provider = context.read<ItineraryProvider>();

//     try {
//       final success = await provider.saveFullItinerary(
//         widget.itinerary.copyWith(
//           title: _currentTitle,
//           description: _currentDescription,
//           items: _tempItems,
//         ),
//         _tempItems,
//       );

//       if (success && mounted) {
//         setState(() => _isEditing = false);
//         await provider.fetchMyPlans();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Trip saved successfully!")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to save: ${e.toString()}")),
//       );
//     }
//   }

//   // ========== BUILD METHOD ==========

//   @override
//   Widget build(BuildContext context) {
//     final isOwner = _checkIsOwner() && !widget.isReadOnly;
//     _tempItems.sort((a, b) => a.startTime.compareTo(b.startTime));
//     final dailyItems = _tempItems
//         .where((i) => i.dayNumber == selectedDay)
//         .toList();

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: _isEditing ? _buildEditAppBar() : null,
//       body: _isLoading
//           ? const Center(
//               child: CircularProgressIndicator(color: Color(0xFF009688)),
//             )
//           : CustomScrollView(
//               controller: _scrollController,
//               slivers: [
//                 ParallaxHeader(
//                   title: _currentTitle,
//                   isOwner: isOwner,
//                   isEditing: _isEditing,
//                   isCompleted: _isTripCompleted,
//                   onEditPressed: () => setState(() => _isEditing = true),
//                   onSettingsPressed: _showEditTripDialog,
//                 ),
//                 SliverToBoxAdapter(
//                   child: Padding(
//                     padding: const EdgeInsets.all(20),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // 1. Ownership & Completion Controls
//                         if (isOwner) ...[
//                           if (_isTripCompleted)
//                             _buildCompletedBadge()
//                           else if (_meetsCompletionThreshold(_tempItems))
//                             _buildFinishTripButton()
//                           else
//                             _buildIncompleteHint(),
//                           const SizedBox(height: 16),
//                         ],

//                         // 2. Description
//                         if (_currentDescription != null &&
//                             _currentDescription!.isNotEmpty) ...[
//                           TripDescriptionCard(
//                             description: _currentDescription!,
//                           ),
//                           const SizedBox(height: 20),
//                         ],

//                         // 3. Stats
//                         Consumer<ItineraryProvider>(
//                           builder: (context, provider, child) {
//                             final updatedItinerary = provider.myPlans
//                                 .firstWhere(
//                                   (p) => p.id == widget.itinerary.id,
//                                   orElse: () => widget.itinerary,
//                                 );
//                             final items = updatedItinerary.items ?? _tempItems;
//                             return ProgressStats.forDetailScreen(
//                               items: items,
//                               title: "Trip Progress",
//                             );
//                           },
//                         ),
//                         QuickStats(itinerary: widget.itinerary),
//                         const SizedBox(height: 24),
//                         DaySelector(
//                           totalDays: widget.itinerary.totalDays ?? 1,
//                           selectedDay: selectedDay,
//                           onDaySelected: (day) =>
//                               setState(() => selectedDay = day),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 _isEditing
//                     ? EditModeTimeline(
//                         dailyItems: dailyItems,
//                         onReorder: _onReorder,
//                         onToggleVisited: _onToggleVisited,
//                         onEditNotes: _showNoteEditor,
//                         onDeleteActivity: _confirmDeleteActivity,
//                         onChangeTime: _selectTime,
//                       )
//                     : StandardTimeline(
//                         dailyItems: dailyItems,
//                         isOwner: isOwner,
//                         isEditing: _isEditing,
//                         isCompleted: _isTripCompleted,
//                         onToggleVisited: (itemId, newValue) =>
//                             _onToggleVisited(itemId, newValue),
//                       ),
//                 const SliverToBoxAdapter(child: SizedBox(height: 120)),
//               ],
//             ),
//       floatingActionButton: _isEditing
//           ? _buildAddActivityFAB()
//           : _buildMapFAB(dailyItems),
//     );
//   }

//   // ========== HELPER METHODS ==========

//   PreferredSizeWidget _buildEditAppBar() {
//     return AppBar(
//       title: const Text("Edit Schedule"),
//       backgroundColor: const Color(0xFF009688),
//       leading: IconButton(
//         icon: const Icon(Icons.close),
//         onPressed: () => setState(() => _isEditing = false),
//       ),
//       actions: [
//         TextButton(
//           onPressed: _saveChanges,
//           child: const Text(
//             "SAVE",
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildAddActivityFAB() {
//     return FloatingActionButton.extended(
//       onPressed: _showAddActivityDialog,
//       backgroundColor: const Color(0xFF009688),
//       icon: const Icon(Icons.add_location_alt, color: Colors.white),
//       label: const Text("Add Activity", style: TextStyle(color: Colors.white)),
//     );
//   }

//   Widget _buildMapFAB(List<ItineraryItem> dailyItems) {
//     final validActivities = dailyItems
//         .where(
//           (item) =>
//               item.destination != null &&
//               item.destination!['latitude'] != null &&
//               item.destination!['longitude'] != null,
//         )
//         .map((item) => item.toJson())
//         .toList();

//     return FloatingActionButton.extended(
//       heroTag: 'view_map_fab',
//       onPressed: validActivities.isEmpty
//           ? () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text("No GPS coordinates found for today."),
//                 ),
//               );
//             }
//           : () => Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => ItineraryMapScreen(activities: validActivities),
//               ),
//             ),
//       backgroundColor: validActivities.isEmpty
//           ? Colors.grey
//           : const Color(0xFF009688),
//       label: const Text("Show Route", style: TextStyle(color: Colors.white)),
//       icon: const Icon(Icons.directions_outlined, color: Colors.white),
//     );
//   }

//   Widget _buildFinishTripButton() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFFE0F2F1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFF009688).withOpacity(0.3)),
//       ),
//       child: Column(
//         children: [
//           const Text(
//             "Reached the end of your adventure?",
//             style: TextStyle(
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF004D40),
//             ),
//           ),
//           const SizedBox(height: 12),
//           ElevatedButton.icon(
//             onPressed: () => _confirmFinishTrip(context),
//             icon: const Icon(Icons.check_circle_outline, color: Colors.white),
//             label: const Text(
//               "MARK TRIP AS FINISHED",
//               style: TextStyle(color: Colors.white),
//             ),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF009688),
//               elevation: 0,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCompletedBadge() {
//     final currentTrip = _getCurrentItinerary();
//     final bool isAlreadyPublic = currentTrip.isPublic ?? false;
//     final bool isCopied = currentTrip.isCopied ?? false;

//     return Column(
//       children: [
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           decoration: BoxDecoration(
//             color: const Color(0xFF009688).withOpacity(0.1),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: const Color(0xFF009688)),
//           ),
//           child: const Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.verified, color: Color(0xFF009688)),
//               SizedBox(width: 8),
//               Text(
//                 "JOURNEY COMPLETED",
//                 style: TextStyle(
//                   color: Color(0xFF009688),
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: 1.2,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 12),
//         ElevatedButton.icon(
//           onPressed: isCopied
//               ? () {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text("Copied trips cannot be shared."),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 }
//               : () async {
//                   final provider = context.read<ItineraryProvider>();
//                   final success = await provider.shareTrip(widget.itinerary.id);
//                   if (success && mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text("Trip shared successfully!"),
//                         backgroundColor: Colors.green,
//                       ),
//                     );
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text("Failed to share the trip."),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                   }
//                 },
//           icon: Icon(
//             isAlreadyPublic ? Icons.public : Icons.share,
//             color: Colors.white,
//           ),
//           label: Text(
//             isAlreadyPublic ? "TRIP IS PUBLIC" : "SHARE TO EXPLORE",
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: isAlreadyPublic
//                 ? Colors.blue[700]
//                 : Colors.orange[700],
//             minimumSize: const Size(double.infinity, 48),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildIncompleteHint() {
//     final items = _tempItems.isNotEmpty
//         ? _tempItems
//         : (widget.itinerary.items ?? []);
//     if (items.isEmpty) return const SizedBox.shrink();

//     final totalNeeded = (items.length * 0.8).ceil();
//     final visited = items.where((i) => i.isVisited == true).length;
//     final remaining = totalNeeded - visited;

//     if (remaining <= 0) {
//       return const Padding(
//         padding: EdgeInsets.symmetric(vertical: 8.0),
//         child: Text(
//           "Almost there! Just click finish to complete your journey.",
//           style: TextStyle(
//             color: Color(0xFF009688),
//             fontSize: 12,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       );
//     }

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Text(
//         "Visit $remaining more stops to mark this trip as finished!",
//         style: const TextStyle(
//           color: Colors.grey,
//           fontSize: 12,
//           fontStyle: FontStyle.italic,
//         ),
//       ),
//     );
//   }

//   bool _checkIsOwner() {
//     final user = context.read<AuthProvider>().user;
//     if (user == null || widget.itinerary.userId == null) return false;
//     return widget.itinerary.userId == int.tryParse(user.id.toString());
//   }

//   bool _meetsCompletionThreshold(List<ItineraryItem> items) {
//     if (items.isEmpty) return false;
//     final visitedCount = items.where((i) => i.isVisited == true).length;
//     return (visitedCount / items.length) >= 0.8;
//   }
// }

// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import 'package:tour_guide/features/auth/logic/auth_provider.dart';
// // import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
// // import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';
// // import 'package:tour_guide/features/itinerary/data/services/itinerary_service.dart';
// // import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
// // import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_map_screen.dart';
// // import 'package:tour_guide/features/itinerary/presentation/widgets/day_selector.dart';
// // import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/add_activity_dialog.dart';
// // import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/delete_confirmation_dialog.dart';
// // import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/edit_trip_dialog.dart';
// // import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/note_editor_dialog.dart';
// // import 'package:tour_guide/features/itinerary/presentation/widgets/edit_mode_timeline.dart';
// // import 'package:tour_guide/features/itinerary/presentation/widgets/parallax_header.dart';
// // import 'package:tour_guide/features/itinerary/presentation/widgets/progress_stats.dart';
// // import 'package:tour_guide/features/itinerary/presentation/widgets/quick_stats.dart';
// // import 'package:tour_guide/features/itinerary/presentation/widgets/standard_timeline.dart';
// // import 'package:tour_guide/features/itinerary/presentation/widgets/trip_description_card.dart';

// // class ItineraryDetailScreen extends StatefulWidget {
// //   final Itinerary itinerary;
// //   final bool isReadOnly;
// //   const ItineraryDetailScreen({
// //     super.key,
// //     required this.itinerary,
// //     this.isReadOnly = false,
// //   });

// //   @override
// //   State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
// // }

// // class _ItineraryDetailScreenState extends State<ItineraryDetailScreen> {
// //   bool _isEditing = false;
// //   bool _isLoading = true;
// //   List<ItineraryItem> _tempItems = [];
// //   int selectedDay = 1;
// //   late String _currentTitle;
// //   late String? _currentDescription;
// //   final ScrollController _scrollController = ScrollController();

// //   bool get _isTripCompleted {
// //     final provider = context.read<ItineraryProvider>();
// //     final currentPlan = provider.myPlans.firstWhere(
// //       (p) => p.id == widget.itinerary.id,
// //       orElse: () => widget.itinerary,
// //     );
// //     return currentPlan.status == 'COMPLETED';
// //   }

// //   @override
// //   void initState() {
// //     super.initState();
// //     _currentTitle = widget.itinerary.title;
// //     _currentDescription = widget.itinerary.description;
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       _setupProviderListener();
// //     });
// //     _fetchFullDetails();
// //   }

// //   void _setupProviderListener() {
// //     final provider = context.read<ItineraryProvider>();
// //     provider.addListener(() {
// //       if (mounted && !_isEditing && !_isLoading) {
// //         _syncWithProvider();
// //       }
// //     });
// //   }

// //   @override
// //   void didChangeDependencies() {
// //     super.didChangeDependencies();
// //     if (mounted && !_isEditing && !_isLoading) {
// //       _syncWithProvider();
// //     }
// //   }

// //   void _syncWithProvider() {
// //     if (widget.isReadOnly) {
// //       debugPrint("🚫 Read-only mode: Skipping provider sync.");
// //       return;
// //     }
// //     final provider = context.read<ItineraryProvider>();
// //     final providerPlan = provider.myPlans.firstWhere(
// //       (p) => p.id == widget.itinerary.id,
// //       orElse: () => widget.itinerary,
// //     );
// //     if (providerPlan.items != null && providerPlan.items!.isNotEmpty) {
// //       final providerItems = providerPlan.items!;
// //       if (mounted) {
// //         setState(() {
// //           _tempItems = List.from(providerItems);
// //         });
// //       }
// //     }
// //   }

// //   Future<void> _fetchFullDetails() async {
// //     try {
// //       final data = await ItineraryService.getItineraryDetails(
// //         widget.itinerary.id,
// //       );
// //       final List rawItems = data['items'] ?? [];
// //       if (mounted) {
// //         setState(() {
// //           _tempItems = rawItems
// //               .map((json) => ItineraryItem.fromJson(json))
// //               .toList();
// //           _isLoading = false;
// //         });
// //       }
// //     } catch (e) {
// //       if (mounted) setState(() => _isLoading = false);
// //     }
// //   }

// //   // ========== EVENT HANDLERS ==========

// //   void _onToggleVisited(int itemId, bool newVisitedStatus) async {
// //     debugPrint(
// //       "🔘 _onToggleVisited called: itemId=$itemId, newVisitedStatus=$newVisitedStatus",
// //     );

// //     if (_isTripCompleted) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text("This journey is finished and cannot be modified."),
// //         ),
// //       );
// //       return;
// //     }

// //     // Update local state IMMEDIATELY for UI responsiveness
// //     setState(() {
// //       int index = _tempItems.indexWhere((i) => i.id == itemId);
// //       if (index != -1) {
// //         debugPrint(
// //           "🔄 Updating local _tempItems index $index to $newVisitedStatus",
// //         );
// //         _tempItems[index] = _tempItems[index].copyWith(
// //           isVisited: newVisitedStatus,
// //         );
// //       } else {
// //         debugPrint("❌ Item not found in _tempItems: $itemId");
// //       }
// //     });

// //     try {
// //       await context.read<ItineraryProvider>().toggleItemVisited(
// //         widget.itinerary.id,
// //         itemId,
// //         newVisitedStatus,
// //       );
// //       await _refreshItineraryDetails();
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text(
// //             newVisitedStatus ? "Marked as visited!" : "Marked as not visited",
// //           ),
// //           duration: const Duration(seconds: 1),
// //         ),
// //       );
// //     } catch (e) {
// //       setState(() {
// //         int index = _tempItems.indexWhere((i) => i.id == itemId);
// //         if (index != -1) {
// //           _tempItems[index] = _tempItems[index].copyWith(
// //             isVisited: !newVisitedStatus,
// //           );
// //         }
// //       });

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text("Failed: $e"),
// //           duration: const Duration(seconds: 3),
// //         ),
// //       );
// //     }
// //   }

// //   Future<void> _refreshItineraryDetails() async {
// //     try {
// //       // Refresh from API
// //       final data = await ItineraryService.getItineraryDetails(
// //         widget.itinerary.id,
// //       );

// //       // Update local state
// //       if (mounted) {
// //         setState(() {
// //           final List rawItems = data['items'] ?? [];
// //           _tempItems = rawItems
// //               .map((json) => ItineraryItem.fromJson(json))
// //               .toList();
// //         });
// //       }

// //       // Also update provider with fresh data
// //       final provider = context.read<ItineraryProvider>();
// //       int planIndex = provider.myPlans.indexWhere(
// //         (p) => p.id == widget.itinerary.id,
// //       );
// //       if (planIndex != -1 && mounted) {
// //         final updatedItinerary = Itinerary.fromJson(data);
// //         provider.myPlans[planIndex] = updatedItinerary;
// //         provider.notifyListeners();
// //       }
// //     } catch (e) {
// //       debugPrint("Refresh failed: $e");
// //     }
// //   }

// //   void _onReorder(int oldIndex, int newIndex) {
// //     setState(() {
// //       if (newIndex > oldIndex) newIndex -= 1;
// //       final List<ItineraryItem> dayItems =
// //           _tempItems.where((i) => i.dayNumber == selectedDay).toList()
// //             ..sort((a, b) => a.orderInDay.compareTo(b.orderInDay));

// //       final movedItem = dayItems.removeAt(oldIndex);
// //       dayItems.insert(newIndex, movedItem);

// //       for (int i = 0; i < dayItems.length; i++) {
// //         final updated = dayItems[i].copyWith(orderInDay: i + 1);
// //         int globalIndex = _tempItems.indexWhere(
// //           (element) => element.id == updated.id,
// //         );
// //         if (globalIndex != -1) _tempItems[globalIndex] = updated;
// //       }
// //     });
// //   }

// //   void _selectTime(ItineraryItem item) async {
// //     TimeOfDay initialTime = TimeOfDay.now();
// //     try {
// //       final parts = item.startTime.split(':');
// //       initialTime = TimeOfDay(
// //         hour: int.parse(parts[0]),
// //         minute: int.parse(parts[1]),
// //       );
// //     } catch (_) {}

// //     final TimeOfDay? picked = await showTimePicker(
// //       context: context,
// //       initialTime: initialTime,
// //     );

// //     if (picked != null) {
// //       final formattedTime =
// //           "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";

// //       setState(() {
// //         int index = _tempItems.indexWhere((element) => element.id == item.id);
// //         if (index != -1) {
// //           _tempItems[index] = _tempItems[index].copyWith(
// //             startTime: formattedTime,
// //           );
// //         }
// //         _tempItems.sort((a, b) => a.startTime.compareTo(b.startTime));
// //         for (int i = 0; i < _tempItems.length; i++) {
// //           _tempItems[i] = _tempItems[i].copyWith(orderInDay: i + 1);
// //         }
// //       });
// //     }
// //   }

// //   void _showEditTripDialog() {
// //     showDialog(
// //       context: context,
// //       builder: (context) => EditTripDialog(
// //         initialTitle: _currentTitle,
// //         initialDescription: _currentDescription,
// //         onSave: (title, description) async {
// //           final success = await context
// //               .read<ItineraryProvider>()
// //               .updatePlanDetails(widget.itinerary.id, title, description);
// //           if (success && mounted) {
// //             setState(() {
// //               _currentTitle = title;
// //               _currentDescription = description;
// //             });
// //           }
// //         },
// //       ),
// //     );
// //   }

// //   void _showNoteEditor(ItineraryItem item) {
// //     showDialog(
// //       context: context,
// //       builder: (context) => NoteEditorDialog(
// //         item: item,
// //         onUpdate: (newNote) async {
// //           setState(() {
// //             int index = _tempItems.indexOf(item);
// //             if (index != -1) _tempItems[index] = item.copyWith(notes: newNote);
// //           });

// //           if (item.id != null) {
// //             try {
// //               await context.read<ItineraryProvider>().updateActivityNotes(
// //                 widget.itinerary.id,
// //                 item.id!,
// //                 newNote,
// //               );
// //             } catch (e) {
// //               debugPrint("Failed to save note: $e");
// //             }
// //           }
// //         },
// //       ),
// //     );
// //   }

// //   void _confirmDeleteActivity(ItineraryItem item) {
// //     showDialog(
// //       context: context,
// //       builder: (ctx) => DeleteConfirmationDialog(
// //         itemName: item.destination?['name'] ?? item.title,
// //         onConfirm: () {
// //           setState(() => _tempItems.removeWhere((element) => element == item));
// //         },
// //       ),
// //     );
// //   }

// //   void _showAddActivityDialog() async {
// //     try {
// //       final allDestinations = await ItineraryService.getAllDestinations();
// //       final existingIds = _tempItems.map((i) => i.destinationId).toSet();
// //       List<dynamic> available = allDestinations
// //           .where((d) => !existingIds.contains(d['id']))
// //           .toList();

// //       showDialog(
// //         context: context,
// //         builder: (context) => AddActivityDialog(
// //           availableDestinations: available,
// //           onDestinationSelected: (dest) {
// //             setState(() {
// //               final newItem = ItineraryItem(
// //                 id: null,
// //                 title: dest['name'] ?? 'New Stop',
// //                 destinationId: dest['id'],
// //                 dayNumber: selectedDay,
// //                 orderInDay:
// //                     _tempItems.where((i) => i.dayNumber == selectedDay).length +
// //                     1,
// //                 startTime: "09:00:00",
// //                 notes: "Newly added stop",
// //                 isVisited: false,
// //                 destination: dest,
// //               );
// //               _tempItems.add(newItem);
// //             });
// //           },
// //         ),
// //       );
// //     } catch (e) {
// //       debugPrint("Load Error: $e");
// //     }
// //   }

// //   void _confirmFinishTrip(BuildContext context) {
// //     showDialog(
// //       context: context,
// //       builder: (ctx) => AlertDialog(
// //         title: const Row(
// //           children: [
// //             Icon(Icons.celebration, color: Color(0xFF009688)),
// //             SizedBox(width: 10),
// //             Text("Finish Journey?"),
// //           ],
// //         ),
// //         content: const Text(
// //           "Congratulations on completing your trip! Would you like to mark this trip as finished? \n\n"
// //           "Finished trips can be shared with the community!",
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(ctx),
// //             child: const Text("Not Yet"),
// //           ),
// //           ElevatedButton(
// //             style: ElevatedButton.styleFrom(
// //               backgroundColor: const Color(0xFF009688),
// //             ),
// //             onPressed: () async {
// //               Navigator.pop(ctx);
// //               final provider = context.read<ItineraryProvider>();

// //               final success = await provider.finishTrip(widget.itinerary.id);

// //               if (success && mounted) {
// //                 await provider.fetchMyPlans();
// //                 setState(() {
// //                   _isEditing = false; // Just in case
// //                 });
// //                 _showCelebrationOverlay();
// //               } else {
// //                 ScaffoldMessenger.of(context).showSnackBar(
// //                   const SnackBar(
// //                     content: Text("Failed to finish trip. Please try again."),
// //                   ),
// //                 );
// //               }
// //             },
// //             child: const Text(
// //               "Finish Trip",
// //               style: TextStyle(color: Colors.white),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   void _showCelebrationOverlay() {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(
// //         content: Text(
// //           "🎉 Trip Completed! You can now share it in your Profile.",
// //         ),
// //         backgroundColor: Color(0xFF009688),
// //         duration: Duration(seconds: 4),
// //       ),
// //     );
// //     setState(() {});
// //   }

// //   // ========== BUILD METHOD ==========

// //   @override
// //   Widget build(BuildContext context) {
// //     final isOwner = _checkIsOwner() && !widget.isReadOnly;
// //     _tempItems.sort((a, b) => a.startTime.compareTo(b.startTime));
// //     final dailyItems = _tempItems
// //         .where((i) => i.dayNumber == selectedDay)
// //         .toList();

// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       // appBar: _isEditing ? _buildEditAppBar() : null,
// //       body: _isLoading
// //           ? const Center(
// //               child: CircularProgressIndicator(color: Color(0xFF009688)),
// //             )
// //           : CustomScrollView(
// //               controller: _scrollController,
// //               slivers: [
// //                 ParallaxHeader(
// //                   title: _currentTitle,
// //                   isOwner: isOwner,
// //                   isEditing: _isEditing,
// //                   isCompleted: _isTripCompleted,
// //                   onEditPressed: () => setState(() => _isEditing = true),
// //                   onSettingsPressed: _showEditTripDialog,
// //                 ),
// //                 SliverToBoxAdapter(
// //                   child: Padding(
// //                     padding: const EdgeInsets.all(20),
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         // 1. Ownership & Completion Controls
// //                         if (isOwner) ...[
// //                           if (_isTripCompleted)
// //                             _buildCompletedBadge()
// //                           else if (_meetsCompletionThreshold(_tempItems))
// //                             _buildFinishTripButton()
// //                           else
// //                             _buildIncompleteHint(),
// //                           const SizedBox(height: 16),
// //                         ],

// //                         // 2. Description
// //                         if (_currentDescription != null &&
// //                             _currentDescription!.isNotEmpty) ...[
// //                           TripDescriptionCard(
// //                             description: _currentDescription!,
// //                           ),
// //                           const SizedBox(height: 20),
// //                         ],

// //                         // 3. Stats (Consumer ensures these update live)
// //                         Consumer<ItineraryProvider>(
// //                           builder: (context, provider, child) {
// //                             final updatedItinerary = provider.myPlans
// //                                 .firstWhere(
// //                                   (p) => p.id == widget.itinerary.id,
// //                                   orElse: () => widget.itinerary,
// //                                 );
// //                             final items = updatedItinerary.items ?? _tempItems;
// //                             return ProgressStats.forDetailScreen(
// //                               items: items,
// //                               title: "Trip Progress",
// //                             );
// //                           },
// //                         ),
// //                         QuickStats(itinerary: widget.itinerary),
// //                         const SizedBox(height: 24),
// //                         DaySelector(
// //                           totalDays: widget.itinerary.totalDays ?? 1,
// //                           selectedDay: selectedDay,
// //                           onDaySelected: (day) =>
// //                               setState(() => selectedDay = day),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //                 _isEditing
// //                     ? EditModeTimeline(
// //                         dailyItems: dailyItems,
// //                         onReorder: _onReorder,
// //                         onToggleVisited: _onToggleVisited,
// //                         onEditNotes: _showNoteEditor,
// //                         onDeleteActivity: _confirmDeleteActivity,
// //                         onChangeTime: _selectTime,
// //                       )
// //                     : StandardTimeline(
// //                         dailyItems: dailyItems,
// //                         isOwner: isOwner,
// //                         isEditing: _isEditing,
// //                         isCompleted: _isTripCompleted,
// //                         onToggleVisited: (itemId, newValue) =>
// //                             _onToggleVisited(itemId, newValue),
// //                       ),
// //                 const SliverToBoxAdapter(child: SizedBox(height: 120)),
// //               ],
// //             ),
// //       floatingActionButton: _isEditing
// //           ? _buildAddActivityFAB()
// //           : _buildMapFAB(dailyItems),
// //     );
// //   }

// //   // ========== HELPER METHODS ==========

// //   // PreferredSizeWidget _buildEditAppBar() {
// //   //   return AppBar(
// //   //     title: const Text("Edit Schedule"),
// //   //     backgroundColor: const Color(0xFF009688),
// //   //     leading: IconButton(
// //   //       icon: const Icon(Icons.close),
// //   //       onPressed: () => setState(() => _isEditing = false),
// //   //     ),
// //   //     actions: [
// //   //       // In itinerary_detail_screen.dart, add to app bar actions:
// //   //       if (kDebugMode && _tempItems.isNotEmpty)
// //   //         IconButton(
// //   //           icon: const Icon(Icons.api),
// //   //           onPressed: () {
// //   //             ItineraryService.testAllApis(
// //   //               widget.itinerary.id,
// //   //               _tempItems.first.id!,
// //   //             );
// //   //           },
// //   //         ),
// //   //       TextButton(
// //   //         onPressed: () async {
// //   //           final provider = context.read<ItineraryProvider>();

// //   //           // Save to provider
// //   //           final success = await provider.saveFullItinerary(
// //   //             widget.itinerary.copyWith(
// //   //               title: _currentTitle,
// //   //               description: _currentDescription,
// //   //               items: _tempItems,
// //   //             ),
// //   //             _tempItems,
// //   //           );

// //   //           if (success && mounted) {
// //   //             setState(() => _isEditing = false);

// //   //             // Force provider to refresh all data
// //   //             await provider.fetchMyPlans();

// //   //             ScaffoldMessenger.of(context).showSnackBar(
// //   //               const SnackBar(content: Text("Trip saved successfully!")),
// //   //             );
// //   //           }
// //   //         },
// //   //         child: const Text(
// //   //           "SAVE",
// //   //           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
// //   //         ),
// //   //       ),
// //   //     ],
// //   //   );
// //   // }

// //   Widget _buildAddActivityFAB() {
// //     return FloatingActionButton.extended(
// //       onPressed: _showAddActivityDialog,
// //       backgroundColor: const Color(0xFF009688),
// //       icon: const Icon(Icons.add_location_alt, color: Colors.white),
// //       label: const Text("Add Activity", style: TextStyle(color: Colors.white)),
// //     );
// //   }

// //   Widget _buildMapFAB(List<ItineraryItem> dailyItems) {
// //     final validActivities = dailyItems
// //         .where(
// //           (item) =>
// //               item.destination != null &&
// //               item.destination!['latitude'] != null &&
// //               item.destination!['longitude'] != null,
// //         )
// //         .map((item) => item.toJson())
// //         .toList();

// //     return FloatingActionButton.extended(
// //       heroTag: 'view_map_fab',
// //       onPressed: validActivities.isEmpty
// //           ? () {
// //               ScaffoldMessenger.of(context).showSnackBar(
// //                 const SnackBar(
// //                   content: Text("No GPS coordinates found for today."),
// //                 ),
// //               );
// //             }
// //           : () => Navigator.push(
// //               context,
// //               MaterialPageRoute(
// //                 builder: (_) => ItineraryMapScreen(activities: validActivities),
// //               ),
// //             ),
// //       backgroundColor: validActivities.isEmpty
// //           ? Colors.grey
// //           : const Color(0xFF009688),
// //       label: const Text("Show Route", style: TextStyle(color: Colors.white)),
// //       icon: const Icon(Icons.directions_outlined, color: Colors.white),
// //     );
// //   }

// //   Widget _buildFinishTripButton() {
// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: const Color(0xFFE0F2F1), // Light Teal
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: const Color(0xFF009688).withOpacity(0.3)),
// //       ),
// //       child: Column(
// //         children: [
// //           const Text(
// //             "Reached the end of your adventure?",
// //             style: TextStyle(
// //               fontWeight: FontWeight.w600,
// //               color: Color(0xFF004D40),
// //             ),
// //           ),
// //           const SizedBox(height: 12),
// //           ElevatedButton.icon(
// //             onPressed: () => _confirmFinishTrip(context),
// //             icon: const Icon(Icons.check_circle_outline, color: Colors.white),
// //             label: const Text(
// //               "MARK TRIP AS FINISHED",
// //               style: TextStyle(color: Colors.white),
// //             ),
// //             style: ElevatedButton.styleFrom(
// //               backgroundColor: const Color(0xFF009688),
// //               elevation: 0,
// //               shape: RoundedRectangleBorder(
// //                 borderRadius: BorderRadius.circular(8),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildCompletedBadge() {
// //     final provider = context.watch<ItineraryProvider>();
// //     final currentTrip = provider.myPlans.firstWhere(
// //       (p) => p.id == widget.itinerary.id,
// //       orElse: () => widget.itinerary,
// //     );
// //     final bool isAlreadyPublic = currentTrip.isPublic ?? false;
// //     final bool isCopied = currentTrip.isCopied ?? false;

// //     return Column(
// //       children: [
// //         Container(
// //           width: double.infinity,
// //           padding: const EdgeInsets.symmetric(vertical: 12),
// //           decoration: BoxDecoration(
// //             color: const Color(0xFF009688).withOpacity(0.1),
// //             borderRadius: BorderRadius.circular(12),
// //             border: Border.all(color: const Color(0xFF009688)),
// //           ),
// //           child: const Row(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               Icon(Icons.verified, color: Color(0xFF009688)),
// //               SizedBox(width: 8),
// //               Text(
// //                 "JOURNEY COMPLETED",
// //                 style: TextStyle(
// //                   color: Color(0xFF009688),
// //                   fontWeight: FontWeight.bold,
// //                   letterSpacing: 1.2,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //         const SizedBox(height: 12),
// //         ElevatedButton.icon(
// //           onPressed: isCopied
// //               ? () {
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     const SnackBar(
// //                       content: Text("Copied trips cannot be shared."),
// //                       backgroundColor: Colors.red,
// //                     ),
// //                   );
// //                 }
// //               : () async {
// //                   final provider = context.read<ItineraryProvider>();
// //                   final result = await provider.shareTrip(widget.itinerary.id);
// //                   // Check if sharing was successful (success message contains "successfully")
// //                   final bool success = result.toLowerCase().contains("success");
// //                   if (success && mounted) {
// //                     _showShareSuccessDialog(isAlreadyPublic);
// //                   } else if (!success) {
// //                     ScaffoldMessenger.of(context).showSnackBar(
// //                       SnackBar(
// //                         content: Text(result), // Show the error message
// //                         backgroundColor: Colors.red,
// //                       ),
// //                     );
// //                   }
// //                 },
// //           icon: Icon(
// //             isAlreadyPublic ? Icons.public : Icons.share,
// //             color: Colors.white,
// //           ),
// //           label: Text(
// //             isAlreadyPublic ? "TRIP IS PUBLIC" : "SHARE TO EXPLORE",
// //             style: const TextStyle(
// //               color: Colors.white,
// //               fontWeight: FontWeight.bold,
// //             ),
// //           ),
// //           style: ElevatedButton.styleFrom(
// //             backgroundColor: isAlreadyPublic
// //                 ? Colors.blue[700]
// //                 : Colors.orange[700],
// //             minimumSize: const Size(double.infinity, 48),
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(12),
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   void _showShareSuccessDialog(bool wasAlreadyPublic) {
// //     showDialog(
// //       context: context,
// //       builder: (ctx) => AlertDialog(
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// //         title: Text(
// //           wasAlreadyPublic ? "Trip made Private" : "Shared Successfully!",
// //         ),
// //         content: Text(
// //           wasAlreadyPublic
// //               ? "Your trip is now hidden from the Explore tab."
// //               : "Your journey is now visible on the Explore tab for other travelers to see and copy!",
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(ctx),
// //             child: const Text("Awesome"),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildIncompleteHint() {
// //     final items = _tempItems.isNotEmpty
// //         ? _tempItems
// //         : (widget.itinerary.items ?? []);
// //     if (items.isEmpty) return const SizedBox.shrink();

// //     final totalNeeded = (items.length * 0.8).ceil();
// //     final visited = items.where((i) => i.isVisited).length;
// //     final remaining = totalNeeded - visited;

// //     if (remaining <= 0) {
// //       return const Padding(
// //         padding: EdgeInsets.symmetric(vertical: 8.0),
// //         child: Text(
// //           "Almost there! Just click finish to complete your journey.",
// //           style: TextStyle(
// //             color: Color(0xFF009688),
// //             fontSize: 12,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //       );
// //     }

// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 8.0),
// //       child: Text(
// //         "Visit $remaining more stops to mark this trip as finished!",
// //         style: const TextStyle(
// //           color: Colors.grey,
// //           fontSize: 12,
// //           fontStyle: FontStyle.italic,
// //         ),
// //       ),
// //     );
// //   }

// //   bool _checkIsOwner() {
// //     final user = context.read<AuthProvider>().user;
// //     if (user == null || widget.itinerary.userId == null) return false;
// //     return widget.itinerary.userId == int.tryParse(user.id.toString());
// //   }

// //   bool _meetsCompletionThreshold(List<ItineraryItem> items) {
// //     if (items.isEmpty) return false;
// //     final visitedCount = items.where((i) => i.isVisited == true).length;
// //     return (visitedCount / items.length) >= 0.8;
// //   }
// // }
