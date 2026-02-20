import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/core/api/api_client.dart';
import 'package:tour_guide/features/user/logic/saved_provider.dart';
import '../data/models/itinerary.dart';
import '../data/models/itinerary_item.dart';
import '../data/services/itinerary_service.dart';

class ItineraryProvider with ChangeNotifier {
  // --- PERSONAL PLANS ---
  List<Itinerary> _myPlans = [];
  List<Itinerary> get myPlans => _myPlans;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- PUBLIC PLANS ---
  List<Itinerary> _publicPlans = [];
  List<Itinerary> get publicPlans => _publicPlans;

  bool _isPublicLoading = false;
  bool get isPublicLoading => _isPublicLoading;

  List<Map<String, dynamic>> _destinations = [];
  List<Map<String, dynamic>> get destinations => _destinations;
  bool _isDestinationsLoading = false;
  bool get isDestinationsLoading => _isDestinationsLoading;

  void updateItineraryInAllLists(Itinerary updatedItinerary) {
    // 1. Update or add to public plans
    final publicIndex = _publicPlans.indexWhere(
      (it) => it.id == updatedItinerary.id,
    );
    if (publicIndex != -1) {
      _publicPlans[publicIndex] = updatedItinerary;
    } else {
      _publicPlans.add(updatedItinerary);
    }

    // 2. Update in my plans
    final myPlanIndex = _myPlans.indexWhere(
      (it) => it.id == updatedItinerary.id,
    );
    if (myPlanIndex != -1) {
      _myPlans[myPlanIndex] = updatedItinerary;
    }
    notifyListeners();
  }

  /// Sync expert plans with the current provider state
  List<Itinerary> syncExpertPlans(List<Itinerary> expertPlans) {
    bool changed = false;

    for (int i = 0; i < expertPlans.length; i++) {
      final itinerary = expertPlans[i];

      // Check if this itinerary exists in public plans with updated state
      final updatedItinerary = _publicPlans.firstWhere(
        (it) => it.id == itinerary.id,
        orElse: () => itinerary,
      );

      // If different, update
      if (updatedItinerary.isLikedByCurrentUser !=
              itinerary.isLikedByCurrentUser ||
          updatedItinerary.likeCount != itinerary.likeCount ||
          updatedItinerary.isSavedByCurrentUser !=
              itinerary.isSavedByCurrentUser) {
        expertPlans[i] = updatedItinerary;
        changed = true;
      }
    }

    // Return the updated list
    return expertPlans;
  }

  // Force refresh a single itinerary
  Future<void> refreshItinerary(int itineraryId) async {
    try {
      await _fetchUpdatedItinerary(itineraryId);
    } catch (e) {
      debugPrint("Error refreshing itinerary: $e");
    }
  }

  // --- FETCH METHODS ---

  Future<void> fetchDestinations() async {
    _isDestinationsLoading = true;
    notifyListeners();
    try {
      _destinations = await ItineraryService.getAllDestinations();
    } catch (e) {
      debugPrint("Fetch destinations error: $e");
      _destinations = [];
    } finally {
      _isDestinationsLoading = false;
      notifyListeners();
    }
  }

  /// Fetch user's own plans
  Future<void> fetchMyPlans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myPlans = await ItineraryService.getMyPlans();
    } catch (e) {
      debugPrint("FetchMyPlans Error: $e");
      _errorMessage = "Failed to load your trips";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch public trips
  Future<void> fetchPublicPlans() async {
    _isPublicLoading = true;
    _errorMessage = null; // Reset error message
    notifyListeners();

    try {
      _publicPlans = await ItineraryService.getPublicTrips();
      debugPrint("Fetched ${_publicPlans.length} public plans");
    } catch (e) {
      debugPrint("FetchPublicPlans Error: $e");
      _errorMessage = "Could not load community trips."; // Set user-friendly error
    } finally {
      _isPublicLoading = false;
      notifyListeners();
    }
  }

  /// Fetch expert/admin templates
  Future<List<Itinerary>> fetchExpertTemplates() async {
    _isLoading = true; // Use a loading state
    notifyListeners();
    try {
      final templates = await ItineraryService.getExpertTemplates();
      return templates;
    } catch (e) {
      debugPrint("FetchExpertTemplates Error: $e");
      // Don't just return []; set an error state so the UI knows why it's empty
      _errorMessage = "Failed to load expert templates.";
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch itineraries by destination
  Future<List<Itinerary>> fetchItinerariesByDestination(
    int destinationId,
  ) async {
    try {
      return await ItineraryService.getItinerariesByDestination(destinationId);
    } catch (e) {
      debugPrint("FetchByDestination Error: $e");
      return [];
    }
  }

  // --- CREATE & COPY ---

  Future<Itinerary?> createNewTrip(Map<String, dynamic> data) async {
    try {
      final newTrip = await ItineraryService.createNewItinerary(data);
      if (newTrip != null) {
        _myPlans.insert(0, newTrip);
        notifyListeners();
      }
      return newTrip;
    } catch (e) {
      debugPrint("CreateNewTrip Error: $e");
      return null;
    }
  }

  Future<Itinerary?> copyTrip(int itineraryId, {DateTime? startDate}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Pass the startDate to the service
      final newTrip = await ItineraryService.copyItinerary(
        itineraryId,
        startDate: startDate,
      );

      _myPlans.insert(0, newTrip);

      // Update copy count in public lists
      final publicIndex = _publicPlans.indexWhere((it) => it.id == itineraryId);
      if (publicIndex != -1) {
        final publicTrip = _publicPlans[publicIndex];
        _publicPlans[publicIndex] = publicTrip.copyWith(
          copyCount: (publicTrip.copyCount ?? 0) + 1,
        );
      }

      _isLoading = false;
      notifyListeners();
      return newTrip;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Failed to copy trip";
      notifyListeners();
      return null;
    }
  }

  // --- UPDATE METHODS ---

  /// Update headers only
  Future<bool> updateItineraryHeaders(Itinerary itinerary) async {
    try {
      final updated = await ItineraryService.updateItinerary(itinerary.id, {
        'title': itinerary.title,
        'description': itinerary.description,
      });

      int index = _myPlans.indexWhere((p) => p.id == itinerary.id);
      if (index != -1) {
        _myPlans[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint("UpdateHeaders Error: $e");
      return false;
    }
  }

  /// Update trip title and description
  Future<bool> updatePlanDetails(
    int itineraryId,
    String newTitle,
    String newDescription,
  ) async {
    try {
      // Find the itinerary
      int planIndex = _myPlans.indexWhere((p) => p.id == itineraryId);
      if (planIndex == -1) return false;

      final itinerary = _myPlans[planIndex];

      // Call service to update
      final updated = await ItineraryService.updateItinerary(itineraryId, {
        'title': newTitle,
        'description': newDescription,
      });

      // Update local state
      _myPlans[planIndex] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("UpdatePlanDetails Error: $e");
      return false;
    }
  }

  /// Update only the notes of a specific activity item
  Future<void> updateActivityNotes(
    int itineraryId,
    int itemId,
    String newNote,
  ) async {
    try {
      // Call the service to update just the notes
      await ItineraryService.updateItineraryItem(itineraryId, itemId, {
        'notes': newNote,
      });

      // Update local state
      int planIndex = _myPlans.indexWhere((p) => p.id == itineraryId);
      if (planIndex != -1) {
        final plan = _myPlans[planIndex];
        if (plan.items != null) {
          int itemIndex = plan.items!.indexWhere((item) => item.id == itemId);
          if (itemIndex != -1) {
            plan.items![itemIndex] = plan.items![itemIndex].copyWith(
              notes: newNote,
            );
            _myPlans[planIndex] = plan;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint("UpdateActivityNotes Error: $e");
      rethrow; // optional: let UI handle error
    }
  }

  /// Save full itinerary (headers + items)
  Future<bool> saveFullItinerary(
    Itinerary itinerary,
    List<ItineraryItem> items,
  ) async {
    try {
      final itemsJson = items.map((e) => e.toJson()).toList();
      final updated = await ItineraryService.updateFullItinerary(itinerary.id, {
        'title': itinerary.title,
        'description': itinerary.description,
        'items': itemsJson,
      });

      int index = _myPlans.indexWhere((p) => p.id == itinerary.id);
      if (index != -1) {
        _myPlans[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint("SaveFullItinerary Error: $e");
      return false;
    }
  }

  /// Update single itinerary item (notes, time, etc.)
  Future<void> updateItineraryItem(
    int itineraryId,
    int itemId,
    Map<String, dynamic> data,
  ) async {
    try {
      await ItineraryService.updateItineraryItem(itineraryId, itemId, data);

      int planIndex = _myPlans.indexWhere((p) => p.id == itineraryId);
      if (planIndex != -1) {
        final plan = _myPlans[planIndex];
        if (plan.items != null) {
          int itemIndex = plan.items!.indexWhere((i) => i.id == itemId);
          if (itemIndex != -1) {
            plan.items![itemIndex] = plan.items![itemIndex].copyWith(
              notes: data['notes'] ?? plan.items![itemIndex].notes,
            );
            _myPlans[planIndex] = plan;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint("UpdateItineraryItem Error: $e");
      rethrow;
    }
  }

  Future<bool> addDayToTrip(int itineraryId) async {
    try {
      // 1. Find the trip in local state
      final tripIndex = _myPlans.indexWhere((p) => p.id == itineraryId);
      if (tripIndex == -1) return false;

      final currentTrip = _myPlans[tripIndex];
      final int newTotalDays = (currentTrip.totalDays ?? 1) + 1;

      // 2. Prepare data with proper Date formatting (YYYY-MM-DD)
      final Map<String, dynamic> updateData = {
        'title': currentTrip.title,
        'description': currentTrip.description ?? "",
        'totalDays': newTotalDays,
        'theme': currentTrip.theme ?? "Adventure",
      };

      // Only add startDate if it exists, formatted specifically for backend date fields
      if (currentTrip.startDate != null) {
        updateData['startDate'] = currentTrip.startDate!
            .toIso8601String()
            .split('T')[0];
      }

      // 3. Call the service
      // We treat the operation as successful if it doesn't throw an error
      final response = await ItineraryService.updateItinerary(
        itineraryId,
        updateData,
      );

      // 4. Update local state optimistically or with response
      _myPlans[tripIndex] = currentTrip.copyWith(
        totalDays: newTotalDays,
        // Ensure we don't accidentally null out the date locally
        startDate: currentTrip.startDate,
      );

      notifyListeners();
      return true; // Explicitly return true because the call succeeded
    } catch (e) {
      debugPrint("Error adding day: $e");
      return false;
    }
  }

  Future<bool> removeLastDay(int itineraryId) async {
    try {
      final tripIndex = _myPlans.indexWhere((p) => p.id == itineraryId);
      if (tripIndex == -1) return false;

      final currentTrip = _myPlans[tripIndex];
      final int currentDays = currentTrip.totalDays ?? 1;

      if (currentDays <= 1) return false;

      final int newTotalDays = currentDays - 1;

      // Calculate new end date locally for immediate UI update
      DateTime? newEndDate;
      if (currentTrip.startDate != null) {
        newEndDate = currentTrip.startDate!.add(
          Duration(days: newTotalDays - 1),
        );
      }

      final Map<String, dynamic> updateData = {
        'totalDays': newTotalDays,
        'title': currentTrip.title,
        'startDate': currentTrip.startDate?.toIso8601String().split('T')[0],
        // Let the backend know we expect this new end date
        'endDate': newEndDate?.toIso8601String().split('T')[0],
      };

      await ItineraryService.updateItinerary(itineraryId, updateData);

      // Update local state with BOTH new day count and new end date
      _myPlans[tripIndex] = currentTrip.copyWith(
        totalDays: newTotalDays,
        endDate: newEndDate,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error removing day: $e");
      return false;
    }
  }

  // --- TOGGLE & COMPLETE ---

  Future<void> toggleItemVisited(
    int itineraryId,
    int itemId,
    bool isVisited,
  ) async {
    try {
      await ItineraryService.toggleItemVisited(itineraryId, itemId, isVisited);

      int planIndex = _myPlans.indexWhere((p) => p.id == itineraryId);
      if (planIndex != -1) {
        final plan = _myPlans[planIndex];
        if (plan.items != null) {
          int itemIndex = plan.items!.indexWhere((i) => i.id == itemId);
          if (itemIndex != -1) {
            plan.items![itemIndex] = plan.items![itemIndex].copyWith(
              isVisited: isVisited,
            );
            _myPlans[planIndex] = plan;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint("ToggleItemVisited Error: $e");
      rethrow;
    }
  }

  Future<bool> finishTrip(int id) async {
    try {
      final updated = await ItineraryService.markAsComplete(id);
      int index = _myPlans.indexWhere((p) => p.id == id);
      if (index != -1) {
        _myPlans[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint("FinishTrip Error: $e");
      return false;
    }
  }

  // --- SHARE ---

  /// Shares a trip to make it public
  Future<bool> shareTrip(int id) async {
    final planIndex = _myPlans.indexWhere((p) => p.id == id);
    if (planIndex == -1) return false;

    final trip = _myPlans[planIndex];

    // Check if trip is copied - backend will reject it
    if (trip.sourceId != null) {
      debugPrint("Cannot share a copied trip");
      return false;
    }

    // Check if trip is already public
    if (trip.isPublic) {
      debugPrint("Trip is already public");
      return false;
    }

    // Check if trip is completed
    if (trip.status != 'COMPLETED') {
      debugPrint("Only completed trips can be shared");
      return false;
    }

    try {
      final updated = await ItineraryService.shareTrip(id);
      if (updated != null) {
        _myPlans[planIndex] = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error sharing itinerary: $e");
      return false;
    }
  }

  /// Makes a public trip private
  Future<bool> unshareTrip(int id) async {
    final planIndex = _myPlans.indexWhere((p) => p.id == id);
    if (planIndex == -1) return false;

    final trip = _myPlans[planIndex];

    // Check if trip is actually public
    if (!(trip.isPublic)) {
      debugPrint("Trip is already private");
      return false;
    }

    try {
      final updated = await ItineraryService.unshareTrip(id);
      if (updated != null) {
        _myPlans[planIndex] = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error unsharing itinerary: $e");
      return false;
    }
  }

  // --- DELETE ---

  Future<bool> deleteTrip(int id) async {
    try {
      await ItineraryService.deleteItinerary(id);
      _myPlans.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("DeleteTrip Error: $e");
      return false;
    }
  }

  /// Deletes a trip by ID (wrapper for deleteTrip)
  Future<bool> deletePlan(int itineraryId) async {
    return await deleteTrip(itineraryId);
  }

  // Saving Public Trips with optimistic updates
  /// Save any itinerary (public, expert, or personal)
  Future<void> saveItinerary(int itineraryId, {BuildContext? context}) async {
    try {
      int publicIndex = _publicPlans.indexWhere((it) => it.id == itineraryId);

      bool isCurrentlySaved = false;

      if (publicIndex != -1) {
        isCurrentlySaved =
            _publicPlans[publicIndex].isSavedByCurrentUser ?? false;
      }
      if (isCurrentlySaved) {
        return;
      }
      final updatedItinerary = await ItineraryService.savePublicPlan(
        itineraryId,
      );
      if (publicIndex != -1) {
        _publicPlans[publicIndex] = updatedItinerary;
        notifyListeners();
      }
      if (context != null) {
        try {
          final savedProvider = context.read<SavedProvider>();
          await savedProvider.fetchSavedItineraries(); // Refresh saved list
        } catch (e) {
          debugPrint('Could not update SavedProvider: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in saveItinerary: $e');
      rethrow;
    }
  }

  /// Unsave any itinerary
  Future<void> unsaveItinerary(int itineraryId, {BuildContext? context}) async {
    try {
      int publicIndex = _publicPlans.indexWhere((it) => it.id == itineraryId);

      bool isCurrentlySaved = false;

      if (publicIndex != -1) {
        isCurrentlySaved =
            _publicPlans[publicIndex].isSavedByCurrentUser ?? false;
      }
      if (!isCurrentlySaved) {
        return;
      }
      final updatedItinerary = await ItineraryService.unsavePublicPlan(
        itineraryId,
      );
      if (publicIndex != -1) {
        _publicPlans[publicIndex] = updatedItinerary;
        notifyListeners();
      }
      if (context != null) {
        try {
          final savedProvider = context.read<SavedProvider>();
          await savedProvider.fetchSavedItineraries(); // Refresh saved list
        } catch (e) {
          debugPrint('Could not update SavedProvider: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in unsaveItinerary: $e');
      rethrow;
    }
  }

  /// Toggle like for any itinerary
  Future<void> toggleLike(int itineraryId, {BuildContext? context}) async {
    try {
      final updatedItinerary = await ItineraryService.toggleLike(itineraryId);
      updateItineraryInAllLists(updatedItinerary);
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to fetch updated itinerary
  Future<void> _fetchUpdatedItinerary(int itineraryId) async {
    try {
      final response = await ApiClient.get('/api/v1/itineraries/$itineraryId');
      
      // Ensure response is cast as a Map before passing to fromJson
      if (response is Map<String, dynamic>) {
        final updatedItinerary = Itinerary.fromJson(response);
        updateItineraryInAllLists(updatedItinerary);
      }
    } catch (e) {
      debugPrint("Failed to fetch updated itinerary $itineraryId: $e");
    }
  }

  /// Sync a single itinerary's saved/liked state with backend
  Future<void> syncItineraryState(int itineraryId) async {
    try {
      await _fetchUpdatedItinerary(itineraryId);
    } catch (e) {
      debugPrint('Failed to sync itinerary $itineraryId: $e');
    }
  }

  /// Sync all public plans with backend
  Future<void> syncAllPublicPlans() async {
    try {
      await fetchPublicPlans();
    } catch (e) {
      debugPrint('Failed to sync public plans: $e');
    }
  }

  /// Force refresh all data
  Future<void> refreshAllData() async {
    try {
      // Fetch public plans
      await fetchPublicPlans();

      // Fetch my plans if user is logged in
      if (ApiClient.currentUserId != null) {
        await fetchMyPlans();
      }
    } catch (e, stackTrace) {
      debugPrint('Error refreshing all data: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // --- UTILITIES ---

  void clear() {
    _myPlans = [];
    _publicPlans = [];
    _errorMessage = null;
    notifyListeners();
  }
}
