import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  // Add this getter near the top of your state class
  bool get _isTripCompleted {
    // We check the provider first to get the most up-to-date status
    final provider = context.read<ItineraryProvider>();
    final currentPlan = provider.myPlans.firstWhere(
      (p) => p.id == widget.itinerary.id,
      orElse: () => widget.itinerary,
    );
    debugPrint("🔍 Current Trip Status: ${currentPlan.status}"); // Add this!
    return currentPlan.status == 'COMPLETED';
  }

  // Check if the trip is actually "finished" in the database
  bool _meetsCompletionThreshold(List<ItineraryItem> items) {
    if (items.isEmpty) return false;

    // Count how many are actually visited
    final visitedCount = items.where((i) => i.isVisited == true).length;

    // Calculate percentage (e.g., 80%)
    double progress = visitedCount / items.length;

    debugPrint(
      "📊 Logic Check: Visited $visitedCount / Total ${items.length} = $progress",
    );

    return progress >= 0.8;
  }

  late String _currentTitle;
  late String? _currentDescription;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.itinerary.title;
    _currentDescription = widget.itinerary.description;

    // Add a post-frame callback to setup provider listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupProviderListener();
    });

    _fetchFullDetails();
  }

  void _setupProviderListener() {
    final provider = context.read<ItineraryProvider>();

    // Listen to provider changes
    provider.addListener(() {
      if (mounted && !_isEditing && !_isLoading) {
        _syncWithProvider();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Always sync with provider when not editing and mounted
    if (mounted && !_isEditing && !_isLoading) {
      _syncWithProvider();
    }
  }

  void _syncWithProvider() {
    if (widget.isReadOnly) {
      debugPrint("🚫 Read-only mode: Skipping provider sync.");
      return;
    }
    final provider = context.read<ItineraryProvider>();
    final providerPlan = provider.myPlans.firstWhere(
      (p) => p.id == widget.itinerary.id,
      orElse: () => widget.itinerary,
    );

    debugPrint(
      "🔄 Syncing: Provider has ${providerPlan.items?.length ?? 0} items, Local has ${_tempItems.length} items",
    );

    if (providerPlan.items != null && providerPlan.items!.isNotEmpty) {
      final providerItems = providerPlan.items!;

      // Debug: Print visited status
      for (int i = 0; i < providerItems.length; i++) {
        if (i < _tempItems.length) {
          if (providerItems[i].isVisited != _tempItems[i].isVisited) {
            debugPrint(
              "   Item ${providerItems[i].id}: Provider=${providerItems[i].isVisited}, Local=${_tempItems[i].isVisited}",
            );
          }
        }
      }

      // Always update when provider has items
      if (mounted) {
        setState(() {
          _tempItems = List.from(providerItems);
        });
        debugPrint("✅ Updated _tempItems from provider");
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
    }
  }

  // ========== EVENT HANDLERS ==========

  void _onToggleVisited(int itemId, bool newVisitedStatus) async {
    debugPrint(
      "🔘 _onToggleVisited called: itemId=$itemId, newVisitedStatus=$newVisitedStatus",
    );

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
        debugPrint(
          "🔄 Updating local _tempItems index $index to $newVisitedStatus",
        );
        _tempItems[index] = _tempItems[index].copyWith(
          isVisited: newVisitedStatus,
        );
      } else {
        debugPrint("❌ Item not found in _tempItems: $itemId");
      }
    });

    try {
      debugPrint("📡 Calling provider.toggleActivityProgress");
      // Update provider
      await context.read<ItineraryProvider>().toggleActivityProgress(
        widget.itinerary.id,
        itemId,
        newVisitedStatus,
      );

      debugPrint("✅ Provider call completed");

      // Optional: Refresh from API to ensure sync
      await _refreshItineraryDetails();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newVisitedStatus ? "Marked as visited!" : "Marked as not visited",
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint("❌ Error in _onToggleVisited: $e");
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
          content: Text("Failed: $e"),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _refreshItineraryDetails() async {
    try {
      // Refresh from API
      final data = await ItineraryService.getItineraryDetails(
        widget.itinerary.id,
      );

      // Update local state
      if (mounted) {
        setState(() {
          final List rawItems = data['items'] ?? [];
          _tempItems = rawItems
              .map((json) => ItineraryItem.fromJson(json))
              .toList();
        });
      }

      // Also update provider with fresh data
      final provider = context.read<ItineraryProvider>();
      int planIndex = provider.myPlans.indexWhere(
        (p) => p.id == widget.itinerary.id,
      );
      if (planIndex != -1 && mounted) {
        final updatedItinerary = Itinerary.fromJson(data);
        provider.myPlans[planIndex] = updatedItinerary;
        provider.notifyListeners();
      }
    } catch (e) {
      debugPrint("Refresh failed: $e");
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final List<ItineraryItem> dayItems =
          _tempItems.where((i) => i.dayNumber == selectedDay).toList()
            ..sort((a, b) => a.orderInDay.compareTo(b.orderInDay));

      final movedItem = dayItems.removeAt(oldIndex);
      dayItems.insert(newIndex, movedItem);

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

    if (picked != null) {
      final formattedTime =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";

      setState(() {
        int index = _tempItems.indexWhere((element) => element.id == item.id);
        if (index != -1) {
          _tempItems[index] = _tempItems[index].copyWith(
            startTime: formattedTime,
          );
        }
        _tempItems.sort((a, b) => a.startTime.compareTo(b.startTime));
        for (int i = 0; i < _tempItems.length; i++) {
          _tempItems[i] = _tempItems[i].copyWith(orderInDay: i + 1);
        }
      });
    }
  }

  void _showEditTripDialog() {
    showDialog(
      context: context,
      builder: (context) => EditTripDialog(
        initialTitle: _currentTitle,
        initialDescription: _currentDescription,
        onSave: (title, description) async {
          final success = await context
              .read<ItineraryProvider>()
              .updatePlanDetails(widget.itinerary.id, title, description);
          if (success && mounted) {
            setState(() {
              _currentTitle = title;
              _currentDescription = description;
            });
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
          setState(() {
            int index = _tempItems.indexOf(item);
            if (index != -1) _tempItems[index] = item.copyWith(notes: newNote);
          });

          if (item.id != null) {
            try {
              await context.read<ItineraryProvider>().updateActivityNotes(
                widget.itinerary.id,
                item.id!,
                newNote,
              );
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
        onConfirm: () {
          setState(() => _tempItems.removeWhere((element) => element == item));
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
          onDestinationSelected: (dest) {
            setState(() {
              final newItem = ItineraryItem(
                id: null,
                title: dest['name'] ?? 'New Stop',
                destinationId: dest['id'],
                dayNumber: selectedDay,
                orderInDay:
                    _tempItems.where((i) => i.dayNumber == selectedDay).length +
                    1,
                startTime: "09:00:00",
                notes: "Newly added stop",
                isVisited: false,
                destination: dest,
              );
              _tempItems.add(newItem);
            });
          },
        ),
      );
    } catch (e) {
      debugPrint("Load Error: $e");
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
                // 1. Force a refresh of the plans list from the server
                // to ensure the 'status' is now 'COMPLETED'
                await provider.fetchMyPlans();

                // 2. Trigger UI update
                setState(() {
                  _isEditing = false; // Just in case
                });

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
          "🎉 Trip Completed! You can now share it in your Profile.",
        ),
        backgroundColor: Color(0xFF009688),
        duration: Duration(seconds: 4),
      ),
    );
    // Optional: Trigger a state refresh or navigate back
    setState(() {});
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
                            _buildCompletedBadge()
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

                        // 3. Stats (Consumer ensures these update live)
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
        // In itinerary_detail_screen.dart, add to app bar actions:
        if (kDebugMode && _tempItems.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.api),
            onPressed: () {
              ItineraryService.testAllApis(
                widget.itinerary.id,
                _tempItems.first.id!,
              );
            },
          ),
        TextButton(
          onPressed: () async {
            final provider = context.read<ItineraryProvider>();

            // Save to provider
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

              // Force provider to refresh all data
              await provider.fetchMyPlans();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Trip saved successfully!")),
              );
            }
          },
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

  bool _checkIsOwner() {
    final user = context.read<AuthProvider>().user;
    if (user == null || widget.itinerary.userId == null) return false;
    return widget.itinerary.userId == int.tryParse(user.id.toString());
  }

  Widget _buildFinishTripButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1), // Light Teal
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

  Widget _buildCompletedBadge() {
    return Column(
      children: [
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
        // NEW: Share button appears only after completion
        ElevatedButton.icon(
          onPressed: () =>
              context.read<ItineraryProvider>().shareTrip(widget.itinerary.id),
          icon: const Icon(Icons.share, color: Colors.white),
          label: const Text(
            "SHARE TO COMMUNITY",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            minimumSize: const Size(double.infinity, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncompleteHint() {
    final totalNeeded = (_tempItems.length * 0.8)
        .ceil(); // Use .ceil() to round up
    final visited = _tempItems.where((i) => i.isVisited).length;
    final remaining = totalNeeded - visited;

    // If for some reason remaining is <= 0 but status isn't COMPLETED yet
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
}
