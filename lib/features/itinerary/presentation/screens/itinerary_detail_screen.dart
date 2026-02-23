import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/core/api/api_client.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/auth/logic/auth_provider.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/add_activity_dialog.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/delete_confirmation_dialog.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/edit_trip_dialog.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/note_editor_dialog.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/edit_mode_timeline.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/parallax_header.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/standard_timeline.dart';
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
    final provider = context.read<ItineraryProvider>();

    // 1. Try to find it in My Plans (Private/Owned)
    // 2. If not found, try to find it in Public Plans (Templates/Expert trips)
    Itinerary? providerPlan;

    final myPlanIndex = provider.myPlans.indexWhere(
      (p) => p.id == widget.itinerary.id,
    );
    if (myPlanIndex != -1) {
      providerPlan = provider.myPlans[myPlanIndex];
    } else {
      final publicIndex = provider.publicPlans.indexWhere(
        (p) => p.id == widget.itinerary.id,
      );
      if (publicIndex != -1) {
        providerPlan = provider.publicPlans[publicIndex];
      }
    }

    // 3. Fallback to the widget's initial itinerary if not in provider yet
    providerPlan ??= widget.itinerary;

    if (mounted) {
      setState(() {
        // Use the items from the provider if they exist, otherwise the widget's items
        _tempItems = List.from(
          providerPlan?.items ?? widget.itinerary.items ?? [],
        );
        _currentTitle = providerPlan?.title ?? widget.itinerary.title;
        _currentDescription =
            providerPlan?.description ?? widget.itinerary.description;
      });
    }
  }

  Future<void> _fetchFullDetails() async {
    try {
      // Use provider to refresh the itinerary – it will update its own state.
      await context.read<ItineraryProvider>().refreshItinerary(
        widget.itinerary.id,
      );
      // After refresh, sync local items.
      _syncWithProvider();
    } catch (e) {
      debugPrint("Error fetching details: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ========== EVENT HANDLERS (all use provider) ==========

  void _onToggleVisited(int itemId, bool newVisitedStatus) async {
    if (_isTripCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This journey is finished and cannot be modified."),
        ),
      );
      return;
    }

    // Optimistic update
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
      // Provider listener will sync later, but we already updated UI.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newVisitedStatus ? "Marked as visited!" : "Marked as not visited",
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      // Revert optimistic update
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

      // Optimistic update
      setState(() {
        int index = _tempItems.indexWhere((element) => element.id == item.id);
        if (index != -1) {
          _tempItems[index] = _tempItems[index].copyWith(
            startTime: formattedTime,
          );
        }
      });

      try {
        await context.read<ItineraryProvider>().saveItem(
          itineraryId: widget.itinerary.id,
          itemId: item.id!,
          data: {'startTime': formattedTime},
        );
      } catch (e) {
        // Revert optimistic update
        setState(() {
          int index = _tempItems.indexWhere((element) => element.id == item.id);
          if (index != -1) {
            _tempItems[index] = _tempItems[index].copyWith(
              startTime: item.startTime,
            );
          }
        });
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
              .updateItineraryHeaders(
                widget.itinerary.id,
                title: title,
                description: description,
              );

          if (success && mounted) {
            setState(() {
              _currentTitle = title;
              _currentDescription = description;
            });
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
            // Optimistic update
            setState(() {
              int index = _tempItems.indexOf(item);
              if (index != -1) {
                _tempItems[index] = item.copyWith(notes: newNote);
              }
            });

            try {
              await context.read<ItineraryProvider>().updateActivityNotes(
                widget.itinerary.id,
                item.id!,
                newNote,
              );
              Navigator.pop(context);
            } catch (e) {
              // Revert optimistic update
              setState(() {
                int index = _tempItems.indexOf(item);
                if (index != -1) {
                  _tempItems[index] = item;
                }
              });
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
              await context.read<ItineraryProvider>().removeItem(
                widget.itinerary.id,
                item.id!,
              );
              // Provider listener will sync items; we also remove locally.
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
    // Use provider's destinations list if already loaded, otherwise fetch.
    final provider = context.read<ItineraryProvider>();
    if (provider.destinations.isEmpty) {
      await provider.fetchDestinations();
    }
    final allDestinations = provider.destinations;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AddActivityDialog(
        availableDestinations: allDestinations,
        onDestinationSelected: (data) async {
          try {
            final destination = data['destination'];
            final destinationId = destination['id'];
            if (destinationId == null) {
              throw Exception("Destination ID missing");
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

            await context.read<ItineraryProvider>().saveItem(
              itineraryId: widget.itinerary.id,
              data: newItemData,
            );
            // Provider listener will sync items.
            if (mounted) Navigator.pop(context);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to add activity: $e")),
            );
          }
        },
      ),
    );
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
              Navigator.pop(ctx);
              setState(() => _isRemovingDay = true);
              try {
                final success = await context
                    .read<ItineraryProvider>()
                    .removeLastDay(widget.itinerary.id);

                if (success && mounted) {
                  if (selectedDay >= dayToRemove) {
                    setState(() => selectedDay = dayToRemove - 1);
                  }
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
            Icon(Icons.celebration, color: AppColors.primary),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
        backgroundColor: AppColors.primary,
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
    if (currentTrip.isCopied) {
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
            Icon(Icons.public, color: AppColors.primary),
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
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Benefits of sharing:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
                      backgroundColor: AppColors.primary,
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
              final success = await provider.unshareTrip(widget.itinerary.id);
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
        // Refresh the provider's state to get the new images
        await context.read<ItineraryProvider>().fetchMyPlans();
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

  // ========== BUILD METHOD ==========

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
              // onClose: () => setState(() => _isEditing = false),
              onAddPhotos: _uploadItineraryImages,
              onSave: _saveChanges,
            )
          : null,
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
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
                        currentTrip: currentTrip,
                        onRemoveDay: _confirmRemoveDay,
                        onAddDay: () async {
                          if (_isAddingDay) return;
                          setState(() => _isAddingDay = true);
                          try {
                            final success = await context
                                .read<ItineraryProvider>()
                                .addDayToTrip(widget.itinerary.id);
                            if (success && mounted) {
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
          if (_isAddingDay || _isRemovingDay)
            Container(
              color: Colors.black.withOpacity(0.4),
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
                          color: AppColors.primary,
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

  String getDayLabel(int dayNumber, DateTime? startDate) {
    if (startDate == null) return "Day $dayNumber";

    final actualDate = startDate.add(Duration(days: dayNumber - 1));
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
