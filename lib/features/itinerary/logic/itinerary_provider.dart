import 'package:flutter/material.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';
import '../data/models/itinerary.dart';
import '../data/services/itinerary_service.dart';

class ItineraryProvider extends ChangeNotifier {
  List<Itinerary> _myPlans = [];
  bool _isLoading = false;
  String? _errorMessage;

  // --- GETTERS ---
  List<Itinerary> get myPlans => _myPlans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- ACTIONS ---

  /// Fetches personal plans from the database
  Future<void> fetchMyPlans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myPlans = await ItineraryService.getMyPlans();
    } catch (e) {
      _errorMessage = "Failed to load your trips. Please try again.";
      debugPrint("FetchMyPlans Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePlanDetails(
    int id,
    String title,
    String description,
  ) async {
    try {
      final updated = await ItineraryService.updateItinerary(id, {
        'title': title,
        'description': description,
      });

      // Update the item in our local list
      int index = _myPlans.indexWhere((p) => p.id == id);
      if (index != -1) {
        _myPlans[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle activity progress and update local state
  Future<void> toggleActivityProgress(
    int itineraryId,
    int itemId,
    bool isVisited,
  ) async {
    try {
      debugPrint(
        "🔄 toggleActivityProgress: itemId=$itemId, visited=$isVisited",
      );

      // Call the service
      await ItineraryService.toggleItemVisited(itineraryId, itemId, isVisited);

      // Update local state
      int planIndex = _myPlans.indexWhere((p) => p.id == itineraryId);
      if (planIndex != -1) {
        final plan = _myPlans[planIndex];
        if (plan.items != null) {
          List<ItineraryItem> updatedItems = List.from(plan.items!);
          int itemIndex = updatedItems.indexWhere((item) => item.id == itemId);
          if (itemIndex != -1) {
            updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(
              isVisited: isVisited,
            );

            _myPlans[planIndex] = plan.copyWith(items: updatedItems);

            // Update summary
            int visitedCount = updatedItems
                .where((item) => item.isVisited)
                .length;
            if (plan.summary != null) {
              _myPlans[planIndex] = _myPlans[planIndex].copyWith(
                summary: plan.summary!.copyWith(
                  completedActivities: visitedCount,
                ),
              );
            }

            notifyListeners();
            debugPrint("✅ Updated: $visitedCount visited activities");
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Progress Sync Error: $e");
      throw Exception("Failed to update progress: $e");
    }
  }

  /// Deletes a trip and updates the local list instantly (Optimistic UI)
  Future<bool> deletePlan(int itineraryId) async {
    // We don't set global _isLoading to true here to avoid flickering the whole list.
    // Instead, we handle the specific deletion.
    try {
      await ItineraryService.deleteItinerary(itineraryId);

      // Update local state immediately so the card disappears
      _myPlans.removeWhere((plan) => plan.id == itineraryId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Could not delete trip.";
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveFullItinerary(
    Itinerary updatedItinerary,
    List<ItineraryItem> items,
  ) async {
    try {
      final itemsJson = items.map((item) => item.toJson()).toList();

      // The backend now returns the FRESH itinerary with FRESH database IDs
      final response =
          await ItineraryService.updateFullItinerary(updatedItinerary.id, {
            'title': updatedItinerary.title,
            'description': updatedItinerary.description,
            'items': itemsJson,
          });
      int index = _myPlans.indexWhere((p) => p.id == updatedItinerary.id);
      if (index != -1) {
        _myPlans[index] = response;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint("Save Full Itinerary Error: $e");
      return false;
    }
  }

  /// Updates only the notes of a specific activity item independently
  Future<void> updateActivityNotes(
    int itineraryId,
    int itemId,
    String newNote,
  ) async {
    try {
      // 1. Call the service to update the database
      // Ensure your ItineraryService has an 'updateItem' or similar method
      await ItineraryService.updateItineraryItem(itineraryId, itemId, {
        'notes': newNote,
      });

      // 2. Update the local state in _myPlans so the change persists
      // even if the user leaves the screen and comes back.
      int planIndex = _myPlans.indexWhere((p) => p.id == itineraryId);
      if (planIndex != -1) {
        final plan = _myPlans[planIndex];
        if (plan.items != null) {
          int itemIndex = plan.items!.indexWhere((item) => item.id == itemId);
          if (itemIndex != -1) {
            plan.items![itemIndex] = plan.items![itemIndex].copyWith(
              notes: newNote,
            );
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint("Update Note Error: $e");
      rethrow; // Pass error back to the UI if needed
    }
  }

  /// Use this when copying a trip from the Explore feed
  /// to ensure the Profile tab stays in sync.
  void addPlanLocally(Itinerary newPlan) {
    _myPlans.insert(0, newPlan); // Add to the top of the list
    notifyListeners();
  }

  /// Call this during logout to prevent the next user from seeing old data
  void clear() {
    _myPlans = [];
    _errorMessage = null;
    notifyListeners();
  }
}
