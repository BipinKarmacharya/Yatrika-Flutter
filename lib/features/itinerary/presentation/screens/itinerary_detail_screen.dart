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
                  onEditPressed: () => setState(() => _isEditing = true),
                  onSettingsPressed: _showEditTripDialog,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentDescription != null &&
                            _currentDescription!.isNotEmpty)
                          Column(
                            children: [
                              TripDescriptionCard(
                                description: _currentDescription!,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        Consumer<ItineraryProvider>(
                          builder: (context, provider, child) {
                            // Get the latest from provider
                            final updatedItinerary = provider.myPlans
                                .firstWhere(
                                  (p) => p.id == widget.itinerary.id,
                                  orElse: () => widget.itinerary,
                                );

                            // Debug
                            debugPrint(
                              "📊 Consumer rebuilding - Itinerary ID: ${updatedItinerary.id}",
                            );
                            debugPrint(
                              "📊 Provider items count: ${updatedItinerary.items?.length ?? 0}",
                            );
                            debugPrint(
                              "📊 Local _tempItems count: ${_tempItems.length}",
                            );

                            if (updatedItinerary.items != null &&
                                updatedItinerary.items!.isNotEmpty) {
                              final visitedCount = updatedItinerary.items!
                                  .where((i) => i.isVisited)
                                  .length;
                              final totalCount = updatedItinerary.items!.length;
                              debugPrint(
                                "📊 Provider visited: $visitedCount/$totalCount",
                              );
                            }

                            // Use provider items if available, otherwise use local _tempItems
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
}
