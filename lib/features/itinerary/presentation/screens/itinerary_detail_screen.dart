import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/core/api/api_client.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/auth/logic/auth_provider.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';
import 'package:tour_guide/features/itinerary/data/services/itinerary_service.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/add_activity_dialog.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/delete_confirmation_dialog.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/edit_trip_dialog.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/note_editor_dialog.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/edit_mode_timeline.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/parallax_header.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/standard_timeline.dart';

// --- Extracted widgets ---
import 'package:tour_guide/features/itinerary/presentation/widgets/edit_app_bar.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/add_activity_fab.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/map_fab.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary_detail_content.dart';

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
  bool _isAddingDay = false;
  bool _isRemovingDay = false;
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
    if (widget.isReadOnly) return;
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

  // ========== EVENT HANDLERS (unchanged) ==========

  void _onToggleVisited(int itemId, bool newVisitedStatus) async {
    if (_isTripCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This journey is finished and cannot be modified."),
        ),
      );
      return;
    }

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

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AddActivityDialog(
          availableDestinations: allDestinations,
          onDestinationSelected: (data) async {
            // 'data' usually contains the whole map
            try {
              // FIX: Ensure we are pulling the 'id' correctly from the nested 'destination' object
              final destination = data['destination'];
              final destinationId = destination['id'];

              if (destinationId == null) {
                throw Exception("Destination ID is missing");
              }

              final newItemData = {
                'destinationId': destinationId,
                'dayNumber': selectedDay,
                'orderInDay':
                    _tempItems.where((i) => i.dayNumber == selectedDay).length +
                    1,
                'startTime': data['startTime'] ?? "09:00:00",
                'notes': data['notes'] ?? "Newly added stop",
                'activityType': data['activityType'] ?? "VISIT",
              };

              await ItineraryService.addActivity(
                widget.itinerary.id,
                newItemData,
              );

              // Refresh the UI
              await _fetchFullDetails();

              if (mounted) Navigator.pop(context);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to add activity: $e")),
              );
            }
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load destinations")));
    }
  }

  void _confirmRemoveDay() {
    final currentTrip = _getCurrentItinerary();
    final int dayToRemove = currentTrip.totalDays ?? 1;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Last Day?"),
        content: Text(
          "Are you sure you want to remove Day $dayToRemove? "
          "Any activities scheduled for this day will be permanently deleted.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog

              setState(() => _isRemovingDay = true);

              try {
                final success = await context
                    .read<ItineraryProvider>()
                    .removeLastDay(widget.itinerary.id);

                if (success && mounted) {
                  // IMPORTANT: If we are on the day being deleted, jump back
                  if (selectedDay >= dayToRemove) {
                    setState(() => selectedDay = dayToRemove - 1);
                  }

                  await _fetchFullDetails(); // Sync items from server

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Day removed successfully")),
                  );
                }
              } finally {
                if (mounted) setState(() => _isRemovingDay = false);
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
    setState(() => _isEditing = false);
    final provider = context.read<ItineraryProvider>();
    await provider.fetchMyPlans();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("All changes synced!")));
  }

  void _showShareConfirmation() {
    final currentTrip = _getCurrentItinerary();
    final bool isCopied = currentTrip.isCopied;

    if (isCopied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Copied trips cannot be shared. Only original plans can be shared.",
          ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to share trip. Please try again."),
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
                      Icon(
                        Icons.warning_outlined,
                        size: 16,
                        color: Colors.orange,
                      ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final provider = context.read<ItineraryProvider>();
              bool success = false;

              try {
                success = await provider.unshareTrip(widget.itinerary.id);
              } catch (e) {
                debugPrint("Unshare method not available: $e");
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
                  setState(() {});
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

  Future<void> _uploadItineraryImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final List<File> files = pickedFiles.map((x) => File(x.path)).toList();

        await ApiClient.multipart(
          '/api/v1/itineraries/${widget.itinerary.id}/images',
          files: files,
          fileKey: 'files',
        );

        // 1. Refresh the global provider state so the header sees the new images
        await context.read<ItineraryProvider>().fetchMyPlans();

        // 2. Refresh local items list
        await _fetchFullDetails();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Images uploaded successfully!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // ========== BUILD METHOD (now concise) ==========

  @override
  Widget build(BuildContext context) {
    final bool isOwner = !_isLoading && _checkIsOwner() && !widget.isReadOnly;
    final canEdit = isOwner && !widget.isReadOnly;
    final currentTrip = _getCurrentItinerary();
    _tempItems.sort((a, b) => a.startTime.compareTo(b.startTime));

    final dailyItems = _tempItems
        .where((i) => i.dayNumber == selectedDay)
        .toList();

    final List<String> headerImages =
      (currentTrip.images != null && currentTrip.images!.isNotEmpty)
      ? currentTrip.images!
      : [
          "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?q=80&w=1000&auto=format&fit=crop",
        ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isEditing
          ? EditAppBar(
              onClose: () => setState(() => _isEditing = false),
              onAddPhotos: _uploadItineraryImages,
              onSave: _saveChanges,
            )
          : null,
      // Use a Stack to layer the loading overlay over the content
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF009688)),
                )
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    ParallaxHeader(
                      title: _currentTitle,
                      images: headerImages,
                      isOwner: canEdit,
                      isEditing: _isEditing,
                      isCompleted: _isTripCompleted,
                      onEditPressed: () => setState(() => _isEditing = true),
                      onSettingsPressed: _showEditTripDialog,
                    ),
                    SliverToBoxAdapter(
                      child: ItineraryDetailContent(
                        isOwner: canEdit,
                        isEditing: _isEditing,
                        isCompleted: _isTripCompleted,
                        currentDescription: _currentDescription,
                        tempItems: _tempItems,
                        itinerary: currentTrip,
                        selectedDay: selectedDay,
                        onDaySelected: (day) =>
                            setState(() => selectedDay = day),
                        onFinishTrip: () => _confirmFinishTrip(context),
                        onShare: _showShareConfirmation,
                        onUnshare: _showUnshareConfirmation,
                        currentTrip: _getCurrentItinerary(),
                        onRemoveDay: _confirmRemoveDay,
                        onAddDay: () async {
                          if (_isAddingDay) return;
                          setState(() => _isAddingDay = true);

                          try {
                            final itineraryProvider = context
                                .read<ItineraryProvider>();
                            final success = await itineraryProvider
                                .addDayToTrip(widget.itinerary.id);

                            if (success == true) {
                              if (!mounted) return;
                              await _fetchFullDetails();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Day added successfully!"),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isAddingDay = false);
                          }
                        },
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

          // --- THE LOADING OVERLAY ---
          if (_isAddingDay || _isRemovingDay)
            Container(
              color: Colors.black.withOpacity(0.4), // Dims the background
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF009688),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _isAddingDay ? "Adding Day..." : "Removing Day...",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isEditing
          ? AddActivityFAB(onPressed: _showAddActivityDialog)
          : MapFAB(dailyItems: dailyItems),
    );
  }

  // ========== HELPER METHODS ==========

  bool _checkIsOwner() {
    final user = context.read<AuthProvider>().user;
    final currentItinerary = context
        .read<ItineraryProvider>()
        .myPlans
        .firstWhere(
          (it) => it.id == widget.itinerary.id,
          orElse: () => widget.itinerary,
        );

    if (user == null || currentItinerary.userId == null) return false;
    return user.id.toString() == currentItinerary.userId.toString();
  }

  bool _meetsCompletionThreshold(List<ItineraryItem> items) {
    if (items.isEmpty) return false;
    final visitedCount = items.where((i) => i.isVisited == true).length;
    return (visitedCount / items.length) >= 0.8;
  }

  String getDayLabel(int dayNumber, DateTime? startDate) {
    if (startDate == null) return "Day $dayNumber";

    // Calculate the specific date for this day number
    // Day 1 = startDate + 0 days
    final actualDate = startDate.add(Duration(days: dayNumber - 1));

    // Format: "Mon, Feb 17"
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

    return "${weekdays[actualDate.weekday]}, ${months[actualDate.month]} ${actualDate.day}";
  }
}

// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
// import 'package:tour_guide/core/api/api_client.dart';
// import 'package:tour_guide/core/theme/app_colors.dart';
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
//                 if (index != -1) {
//                   _tempItems[index] = item.copyWith(notes: newNote);
//                 }
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
//           "🎉 Trip Completed! You can now share it with the community.",
//         ),
//         backgroundColor: Color(0xFF009688),
//         duration: Duration(seconds: 4),
//       ),
//     );
//   }

//   void _saveChanges() async {
//     // Since addActivity and updateItineraryItem already sync with the backend,
//     // we just need to exit edit mode and refresh the local provider state.
//     setState(() => _isEditing = false);

//     final provider = context.read<ItineraryProvider>();
//     await provider.fetchMyPlans(); // Refresh the list from server

//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text("All changes synced!")));
//   }

//   void _showShareConfirmation() {
//     final currentTrip = _getCurrentItinerary();
//     final bool isCopied = currentTrip.isCopied;

//     if (isCopied) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             "Copied trips cannot be shared. Only original plans can be shared.",
//           ),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Row(
//           children: [
//             Icon(Icons.public, color: Colors.green),
//             SizedBox(width: 10),
//             Text("Share with Community"),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               "This will make your itinerary visible on the Explore tab for other travelers to see and copy.",
//             ),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.green[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.green[200]!),
//               ),
//               child: const Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.info_outline, size: 16, color: Colors.green),
//                       SizedBox(width: 8),
//                       Text(
//                         "Benefits of sharing:",
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Colors.green,
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     "• Help other travelers discover great routes\n"
//                     "• Get recognition for your planning skills\n"
//                     "• Your trip might be featured on Explore page\n"
//                     "• You can always make it private later",
//                     style: TextStyle(fontSize: 12, color: AppColors.primary),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//             onPressed: () async {
//               final provider = context.read<ItineraryProvider>();
//               final success = await provider.shareTrip(widget.itinerary.id);
//               if (ctx.mounted) {
//                 Navigator.pop(ctx);
//                 if (success) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text(
//                         "🎉 Trip is now public! Others can now view and copy it.",
//                       ),
//                       backgroundColor: Colors.green,
//                     ),
//                   );
//                   setState(() {}); // Refresh UI
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text("Failed to share trip. Please try again."),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 }
//               }
//             },
//             child: const Text(
//               "Share Now",
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showUnshareConfirmation() {
//     final currentTrip = _getCurrentItinerary();

//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Row(
//           children: [
//             Icon(Icons.lock_outline, color: Colors.orange),
//             SizedBox(width: 10),
//             Text("Make Trip Private"),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               "Are you sure you want to make '${currentTrip.title}' private?",
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               "This trip will no longer be visible to other users on the Explore tab.",
//             ),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.orange[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.orange[200]!),
//               ),
//               child: const Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.warning_outlined,
//                         size: 16,
//                         color: Colors.orange,
//                       ),
//                       SizedBox(width: 8),
//                       Text(
//                         "Note:",
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Colors.orange,
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     "• Existing copies made by other users will remain\n"
//                     "• You can share it again anytime if you change your mind\n"
//                     "• The trip will still be visible in your 'My Trips' tab",
//                     style: TextStyle(fontSize: 12, color: Color(0xFFEF6C00)),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text("Keep Public"),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
//             onPressed: () async {
//               final provider = context.read<ItineraryProvider>();
//               bool success = false;

//               // Try to use unshareTrip method if it exists
//               try {
//                 // Check if provider has unshareTrip method
//                 success = await provider.unshareTrip(widget.itinerary.id);
//               } catch (e) {
//                 debugPrint("Unshare method not available: $e");
//                 // Fallback: Use the share method if unshare doesn't exist
//                 // This assumes the backend toggles the public status
//                 success = await provider.shareTrip(widget.itinerary.id);
//               }

//               if (ctx.mounted) {
//                 Navigator.pop(ctx);
//                 if (success) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text("Trip is now private."),
//                       backgroundColor: Colors.orange,
//                     ),
//                   );
//                   setState(() {}); // Refresh UI
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text("Failed to make trip private."),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 }
//               }
//             },
//             child: const Text(
//               "Make Private",
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _uploadItineraryImages() async {
//     final ImagePicker picker = ImagePicker();
//     // Select multiple images
//     final List<XFile> pickedFiles = await picker.pickMultiImage();

//     if (pickedFiles.isNotEmpty) {
//       setState(() => _isLoading = true);
//       try {
//         final List<File> files = pickedFiles.map((x) => File(x.path)).toList();

//         // Call the multipart helper in ApiClient
//         await ApiClient.multipart(
//           '/api/v1/itineraries/${widget.itinerary.id}/images',
//           files: files,
//         );

//         await _fetchFullDetails(); // Refresh to show new images
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Images uploaded successfully!")),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
//       } finally {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   // ========== BUILD METHOD ==========

//   @override
//   Widget build(BuildContext context) {
//     final bool isOwner = !_isLoading && _checkIsOwner() && !widget.isReadOnly;

//     final canEdit = isOwner && !widget.isReadOnly;

//     _tempItems.sort((a, b) => a.startTime.compareTo(b.startTime));

//     final dailyItems = _tempItems
//         .where((i) => i.dayNumber == selectedDay)
//         .toList();

//     final List<String> headerImages =
//         (widget.itinerary.images != null && widget.itinerary.images!.isNotEmpty)
//         ? widget.itinerary.images!
//         : [
//             "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?q=80&w=1000&auto=format&fit=crop",
//           ];

//     print(
//       "Detail Screen - isOwner: ${_checkIsOwner()}, isReadOnly: ${widget.isReadOnly}, isLoading: $_isLoading",
//     );

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
//                   images: headerImages,
//                   isOwner: canEdit,
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
//                         if (canEdit) ...[
//                           if (_isTripCompleted)
//                             _buildCompletedSection()
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
//         IconButton(
//           icon: const Icon(Icons.add_a_photo_outlined),
//           onPressed: _uploadItineraryImages,
//           tooltip: "Add Photos",
//         ),
//         TextButton(
//           onPressed: _saveChanges,
//           child: const Text("DONE", style: TextStyle(color: Colors.white)),
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

//   Widget _buildCompletedSection() {
//     final currentTrip = _getCurrentItinerary();
//     final bool isPublic = currentTrip.isPublic;
//     final bool isCopied = currentTrip.isCopied;

//     return Column(
//       children: [
//         // Completion Badge
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

//         // Information card
//         if (isCopied)
//           _buildCopiedInfoCard()
//         else if (isPublic)
//           _buildPublicTripCard()
//         else
//           _buildShareableTripCard(),
//       ],
//     );
//   }

//   Widget _buildCopiedInfoCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.orange[50],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.orange[200]!),
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Icon(Icons.info_outline, color: Colors.orange[800]),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   "Copied Plan",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.orange[800],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "This is a copy of another user's trip. Only original trips can be shared with the community.",
//             style: TextStyle(fontSize: 14, color: Colors.orange[700]),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPublicTripCard() {
//     return Column(
//       children: [
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.green[50],
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.green[200]!),
//           ),
//           child: Column(
//             children: [
//               Row(
//                 children: [
//                   Icon(Icons.public, color: Colors.green[800]),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       "Public Trip",
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green[800],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "This trip is visible to other travelers on the Explore tab.",
//                 style: TextStyle(fontSize: 14, color: Colors.green[700]),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 12),
//         ElevatedButton.icon(
//           onPressed: _showUnshareConfirmation,
//           icon: const Icon(Icons.lock_outline, color: Colors.white),
//           label: const Text(
//             "MAKE PRIVATE",
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//           ),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.orange[700],
//             minimumSize: const Size(double.infinity, 48),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildShareableTripCard() {
//     return ElevatedButton.icon(
//       onPressed: _showShareConfirmation,
//       icon: const Icon(Icons.share, color: Colors.white),
//       label: const Text(
//         "SHARE TO COMMUNITY",
//         style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//       ),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.green[700],
//         minimumSize: const Size(double.infinity, 48),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
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
//     // Get the fresh data from the Provider
//     final currentItinerary = context
//         .read<ItineraryProvider>()
//         .myPlans
//         .firstWhere(
//           (it) => it.id == widget.itinerary.id,
//           orElse: () => widget.itinerary,
//         );

//     print("DEBUG: AuthUser ID: ${user?.id} (Type: ${user?.id.runtimeType})");
//     print(
//       "DEBUG: Trip Owner ID: ${currentItinerary.userId} (Type: ${currentItinerary.userId.runtimeType})",
//     );

//     if (user == null || currentItinerary.userId == null) return false;

//     // Final solution for type mismatch: toString() comparison
//     return user.id.toString() == currentItinerary.userId.toString();
//   }

//   bool _meetsCompletionThreshold(List<ItineraryItem> items) {
//     if (items.isEmpty) return false;
//     final visitedCount = items.where((i) => i.isVisited == true).length;
//     return (visitedCount / items.length) >= 0.8;
//   }
// }
