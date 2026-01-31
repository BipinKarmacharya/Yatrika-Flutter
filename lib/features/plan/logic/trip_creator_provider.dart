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
  }) {
    _draftItinerary = Itinerary(
      id: 0, // Temporary ID
      title: title,
      description: description,
      totalDays: totalDays,
      theme: theme,
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
      // 1. Create the header first to get a real ID
      final Map<String, dynamic> tripData = {
        'title': _draftItinerary!.title,
        'description': _draftItinerary!.description,
        'theme': _draftItinerary!.theme,
        'totalDays': _draftItinerary!.totalDays,
      };

      final createdTrip = await ItineraryService.createNewItinerary(tripData);

      if (createdTrip != null && _draftItinerary!.items != null) {
        // 2. Sync all items to the newly created trip ID using your "Full Update" endpoint
        final finalizedTrip = await ItineraryService.updateFullItinerary(
          createdTrip.id, 
          {
            'title': createdTrip.title,
            'description': createdTrip.description,
            'items': _draftItinerary!.items!.map((i) => i.toJson()).toList(),
          }
        );
        
        _draftItinerary = null; // Clear draft after success
        return finalizedTrip;
      }
      return createdTrip;
    } catch (e) {
      debugPrint("Error saving manual trip: $e");
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}