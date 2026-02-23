import 'package:flutter/material.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';
import 'package:tour_guide/features/itinerary/data/services/itinerary_service.dart';

class TripCreatorProvider extends ChangeNotifier {
  // The "Draft" itinerary
  Itinerary? _draftItinerary;
  bool _isSaving = false;

  Itinerary? get draftItinerary => _draftItinerary;
  bool get isSaving => _isSaving;

  /// Initialize a new blank trip
  void initNewTrip({
    required String title,
    String? description,
    int totalDays = 1,
    String theme = 'Adventure',
    DateTime? startDate,
  }) {
    DateTime? calculatedEndDate;
    if (startDate != null) {
      calculatedEndDate = startDate.add(Duration(days: totalDays - 1));
    }
    _draftItinerary = Itinerary(
      id: 0, // Temporary ID
      title: title,
      description: description,
      totalDays: totalDays,
      theme: theme,
      startDate: startDate,
      endDate: calculatedEndDate,
      isAdminCreated: false,
      isPublic: false,
      items: [], // Start with empty list
    );
    notifyListeners();
  }

  /// Add an activity to the draft
  void addActivity(ItineraryItem item) {
    if (_draftItinerary == null) return;

    final updatedItems = List<ItineraryItem>.from(_draftItinerary!.items ?? []);
    updatedItems.add(item);

    _draftItinerary = _draftItinerary!.copyWith(items: updatedItems);
    notifyListeners();
  }

  /// Remove an activity before saving
  void removeActivity(int index) {
    if (_draftItinerary == null) return;
    final updatedItems = List<ItineraryItem>.from(_draftItinerary!.items ?? []);
    updatedItems.removeAt(index);
    _draftItinerary = _draftItinerary!.copyWith(items: updatedItems);
    notifyListeners();
  }

  /// Update an existing activity in the draft
  void updateActivity(ItineraryItem updatedItem) {
    if (_draftItinerary == null) return;

    final items = List<ItineraryItem>.from(_draftItinerary!.items ?? []);

    // Find item by ID if it exists, otherwise find by a combination of title and order (for temporary items)
    final index = items.indexWhere(
      (i) =>
          (i.id != null && i.id == updatedItem.id) ||
          (i.title == updatedItem.title &&
              i.orderInDay == updatedItem.orderInDay),
    );

    if (index != -1) {
      items[index] = updatedItem;

      // Keep items sorted by time automatically
      items.sort((a, b) => a.startTime.compareTo(b.startTime));

      _draftItinerary = _draftItinerary!.copyWith(items: items);
      notifyListeners();
    }
  }

  /// Reorder activities locally
  void reorderActivities(int oldIndex, int newIndex) {
    if (_draftItinerary == null) return;
    final items = List<ItineraryItem>.from(_draftItinerary!.items ?? []);

    if (newIndex > oldIndex) newIndex -= 1;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    // Update orders based on position
    for (int i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(orderInDay: i + 1);
    }

    _draftItinerary = _draftItinerary!.copyWith(items: items);
    notifyListeners();
  }

  /// Finalize and save to Backend
  Future<Itinerary?> saveTripToBackend() async {
    if (_draftItinerary == null) return null;

    _isSaving = true;
    notifyListeners();

    try {
      // 1. Prepare Date Strings (Ensuring YYYY-MM-DD format)
      String? startDateStr;
      String? endDateStr;

      if (_draftItinerary!.startDate != null) {
        startDateStr = _draftItinerary!.startDate!.toIso8601String().split(
          'T',
        )[0];

        // Calculate end date: Start + (Total Days - 1)
        // Use '!' if totalDays is nullable in your model
        final int duration = _draftItinerary!.totalDays ?? 1;
        final endDt = _draftItinerary!.startDate!.add(
          Duration(days: duration - 1),
        );
        endDateStr = endDt.toIso8601String().split('T')[0];
      }

      // 2. Construct the exact JSON the backend expects
      final Map<String, dynamic> tripData = {
        'title': _draftItinerary!.title,
        'description': _draftItinerary!.description ?? "",
        'theme': _draftItinerary!.theme ?? "Adventure",
        'startDate': startDateStr, // Must be "YYYY-MM-DD"
        'endDate': endDateStr, // Must be "YYYY-MM-DD"
        'totalDays': _draftItinerary!.totalDays ?? 1,
        'status': 'DRAFT',
        'isAdminCreated': false,
        'isPublic': false,
      };

      // 3. Create the Header
      final createdTrip = await ItineraryService.createNewItinerary(tripData);

      if (_draftItinerary!.items != null) {
        // 4. Save items sequentially
        for (var item in _draftItinerary!.items!) {
          final itemData = {
            'destinationId': item.destinationId,
            'title': item.title,
            'dayNumber': item.dayNumber,
            'orderInDay': item.orderInDay,
            'startTime': item.startTime, // Ensure this is "HH:mm:ss"
            'notes': item.notes ?? "",
            'activityType': item.activityType ?? "VISIT",
          };
          await ItineraryService.addItem(createdTrip.id, itemData);
        }

        _draftItinerary = null; // Clear draft on success
        return createdTrip;
      }
      return createdTrip;
    } catch (e) {
      debugPrint("CRITICAL ERROR SAVING: $e");
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
