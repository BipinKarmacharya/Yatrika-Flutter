import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/core/api/api_client.dart';
import 'package:tour_guide/features/user/logic/saved_provider.dart';
import '../data/models/itinerary.dart';
import '../data/services/itinerary_service.dart';

class ItineraryProvider with ChangeNotifier {
  // --- State ---
  List<Itinerary> _myPlans = [];
  List<Itinerary> _publicPlans = [];
  List<Map<String, dynamic>> _destinations = [];
  List<Itinerary> _expertTemplates = [];
  List<Itinerary> get expertTemplates => _expertTemplates;

  bool _isLoading = false;
  bool _isPublicLoading = false;
  bool _isDestinationsLoading = false;
  String? _errorMessage;

  // --- Getters ---
  List<Itinerary> get myPlans => _myPlans;
  List<Itinerary> get publicPlans => _publicPlans;
  List<Map<String, dynamic>> get destinations => _destinations;

  bool get isLoading => _isLoading;
  bool get isPublicLoading => _isPublicLoading;
  bool get isDestinationsLoading => _isDestinationsLoading;
  String? get errorMessage => _errorMessage;

  // ===========================================================================
  // CORE STATE MANAGEMENT – Single source of truth
  // ===========================================================================

  /// Updates both personal and public lists with the fresh itinerary from backend.
  void _updateLocalState(Itinerary updated) {
    // Update in My Plans
    final myIdx = _myPlans.indexWhere((it) => it.id == updated.id);
    if (myIdx != -1) {
      _myPlans[myIdx] = updated;
    }

    // Update in Public Plans (if present)
    final pubIdx = _publicPlans.indexWhere((it) => it.id == updated.id);
    if (pubIdx != -1) {
      _publicPlans[pubIdx] = updated;
    }

    final expIdx = _expertTemplates.indexWhere((it) => it.id == updated.id);
    if (expIdx != -1) _expertTemplates[expIdx] = updated;

    notifyListeners();
  }

  // ===========================================================================
  // FETCH OPERATIONS
  // ===========================================================================

  Future<void> fetchDestinations() async {
    _setDestinationsLoading(true);
    try {
      _destinations = await ItineraryService.getAllDestinations();
    } catch (e) {
      debugPrint("fetchDestinations error: $e");
      _destinations = [];
    } finally {
      _setDestinationsLoading(false);
    }
  }

  Future<void> fetchMyPlans() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _myPlans = await ItineraryService.getMyPlans();
    } catch (e) {
      debugPrint("fetchMyPlans error: $e");
      _errorMessage = "Failed to load your trips";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchPublicPlans() async {
    _setPublicLoading(true);
    _errorMessage = null;
    try {
      _publicPlans = await ItineraryService.getPublicTrips();
    } catch (e) {
      debugPrint("fetchPublicPlans error: $e");
      _errorMessage = "Could not load community trips.";
    } finally {
      _setPublicLoading(false);
    }
  }

  /// Returns list of expert templates (admin created) – they are not stored in provider state.
  Future<List<Itinerary>> fetchExpertTemplates() async {
    _setLoading(true);
    try {
      _expertTemplates = await ItineraryService.getExpertTemplates();
      notifyListeners();
      return _expertTemplates;
    } catch (e) {
      debugPrint("fetchExpertTemplates error: $e");
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Itinerary>> fetchItinerariesByDestination(
    int destinationId,
  ) async {
    try {
      return await ItineraryService.getItinerariesByDestination(destinationId);
    } catch (e) {
      debugPrint("fetchByDestination error: $e");
      return [];
    }
  }

  // ===========================================================================
  // CREATE & COPY
  // ===========================================================================

  Future<Itinerary?> createNewTrip(Map<String, dynamic> data) async {
    try {
      final newTrip = await ItineraryService.createNewItinerary(data);
      _myPlans.insert(0, newTrip);
      notifyListeners();
      return newTrip;
    } catch (e) {
      debugPrint("createNewTrip error: $e");
      return null;
    }
  }

  Future<Itinerary?> copyTrip(int itineraryId, {DateTime? startDate}) async {
    try {
      _setLoading(true);
      // Ensure the service receives the date
      final newTrip = await ItineraryService.copyItinerary(
        itineraryId,
        startDate: startDate,
      );

      _myPlans.insert(0, newTrip);
      notifyListeners();
      return newTrip;
    } catch (e) {
      _errorMessage = "Failed to copy trip";
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ===========================================================================
  // HEADER & GENERAL UPDATES
  // ===========================================================================

  Future<bool> updateItineraryHeaders(
    int id, {
    String? title,
    String? description,
    String? theme,
    int? totalDays,
  }) async {
    try {
      // 1. Find the current version of this itinerary in your local state
      // We search all lists to be safe
      final current = _myPlans.firstWhere(
        (it) => it.id == id,
        orElse: () => _publicPlans.firstWhere((it) => it.id == id),
      );

      // 2. Build a COMPLETE map.
      // If a parameter is null, use the value we already have in memory.
      final Map<String, dynamic> body = {
        'title': title ?? current.title,
        'description': description ?? current.description,
        'theme': theme ?? current.theme,
        'totalDays': totalDays ?? current.totalDays,
        // Include status or other mandatory fields if your backend requires them
        'status': current.status,
      };

      // 3. Send the full data to the service
      final updated = await ItineraryService.updateItineraryHeader(id, body);

      // 4. Sync the UI
      _updateLocalState(updated);
      return true;
    } catch (e) {
      debugPrint("updateItineraryHeaders error: $e");
      return false;
    }
  }
  // Future<bool> updateItineraryHeaders(
  //   int id, {
  //   String? title,
  //   String? description,
  //   int? totalDays, // Ensure this is definitely passed as int
  // }) async {
  //   try {
  //     final Map<String, dynamic> body = {};
  //     if (title != null) body['title'] = title;
  //     if (description != null) body['description'] = description;
  //     if (totalDays != null) body['totalDays'] = totalDays;

  //     final updated = await ItineraryService.updateItineraryHeader(id, body);
  //     _updateLocalState(updated);
  //     return true;
  //   } catch (e) {
  //     debugPrint("Header update failed: $e");
  //     return false;
  //   }
  // }

  // Future<bool> updatePlanDetails(
  //   int itineraryId,
  //   String newTitle,
  //   String newDescription,
  // ) async {
  //   try {
  //     final updated = await ItineraryService.updateItinerary(itineraryId, {
  //       'title': newTitle,
  //       'description': newDescription,
  //     });
  //     _updateLocalState(updated);
  //     return true;
  //   } catch (e) {
  //     debugPrint("updatePlanDetails error: $e");
  //     return false;
  //   }
  // }

  /// Change total days – backend handles date adjustments automatically.
  Future<void> changeDuration(int itineraryId, int newTotalDays) async {
    try {
      final updated = await ItineraryService.updateItineraryHeader(
        itineraryId,
        {'totalDays': newTotalDays},
      );
      _updateLocalState(updated);
    } catch (e) {
      debugPrint("changeDuration error: $e");
    }
  }

  /// Add a day to a trip – simply increments totalDays, backend does the rest.
  Future<bool> addDayToTrip(int itineraryId) async {
    final index = _myPlans.indexWhere((p) => p.id == itineraryId);
    if (index == -1) return false;

    final currentDays = _myPlans[index].totalDays ?? 1;
    return await updateItineraryHeaders(
      itineraryId,
      totalDays: currentDays + 1,
    );
  }

  // Remove last day
  Future<bool> removeLastDay(int itineraryId) async {
    final index = _myPlans.indexWhere((p) => p.id == itineraryId);
    if (index == -1) return false;

    final currentDays = _myPlans[index].totalDays ?? 1;
    if (currentDays <= 1) return false;

    return await updateItineraryHeaders(
      itineraryId,
      totalDays: currentDays - 1,
    );
  }

  // ===========================================================================
  // ITEM MANAGEMENT
  // ===========================================================================

  /// Unified method for adding or updating an item.
  Future<Itinerary?> saveItem({
    required int itineraryId,
    int? itemId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final updated = (itemId == null)
          ? await ItineraryService.addItem(itineraryId, data)
          : await ItineraryService.updateItineraryItem(
              itineraryId,
              itemId,
              data,
            );
      _updateLocalState(updated);
      return updated;
    } catch (e) {
      debugPrint("saveItem error: $e");
      rethrow;
    }
  }

  /// Remove an item (delete endpoint returns void, so we manually remove from local lists).
  Future<void> removeItem(int itineraryId, int itemId) async {
    try {
      await ItineraryService.removeItem(itineraryId, itemId);

      // Helper to remove item from a specific list
      void removeFromList(List<Itinerary> list) {
        final idx = list.indexWhere((it) => it.id == itineraryId);
        if (idx != -1 && list[idx].items != null) {
          list[idx].items!.removeWhere((item) => item.id == itemId);
        }
      }

      removeFromList(_myPlans);
      removeFromList(_publicPlans);
      notifyListeners();
    } catch (e) {
      debugPrint("removeItem error: $e");
    }
  }

  /// Update only the notes of an item.
  Future<void> updateActivityNotes(
    int itineraryId,
    int itemId,
    String newNote,
  ) async {
    // Reuse saveItem with only notes field
    await saveItem(
      itineraryId: itineraryId,
      itemId: itemId,
      data: {'notes': newNote},
    );
  }

  /// Toggle visited status of an item.
  Future<void> toggleItemVisited(
    int itineraryId,
    int itemId,
    bool isVisited,
  ) async {
    try {
      // final updated = await ItineraryService.toggleItemVisited(
      //   itineraryId,
      //   itemId,
      //   isVisited,
      // );
      await ItineraryService.toggleItemVisited(itineraryId, itemId, isVisited);

    } catch (e) {
      debugPrint("toggleItemVisited error: $e");
      rethrow;
    }
  }

  /// Reorder items – backend returns full itinerary.
  Future<void> reorderItems(int itineraryId, List<int> itemIdsInOrder) async {
    try {
      final updated = await ItineraryService.reorderItems(
        itineraryId,
        itemIdsInOrder,
      );
      _updateLocalState(updated);
    } catch (e) {
      debugPrint("reorderItems error: $e");
    }
  }

  // ===========================================================================
  // FULL ITINERARY SAVE (headers + items)
  // ===========================================================================

  // Future<bool> saveFullItinerary(
  //   Itinerary itinerary,
  //   List<ItineraryItem> items,
  // ) async {
  //   try {
  //     final itemsJson = items.map((e) => e.toJson()).toList();
  //     final updated = await ItineraryService.updateFullItinerary(itinerary.id, {
  //       'title': itinerary.title,
  //       'description': itinerary.description,
  //       'items': itemsJson,
  //     });
  //     _updateLocalState(updated);
  //     return true;
  //   } catch (e) {
  //     debugPrint("saveFullItinerary error: $e");
  //     return false;
  //   }
  // }

  // ===========================================================================
  // SOCIAL ACTIONS (Like / Save)
  // ===========================================================================

  Future<void> toggleLike(int itineraryId, {BuildContext? context}) async {
    try {
      final updated = await ItineraryService.toggleLike(itineraryId);
      _updateLocalState(updated);
    } catch (e) {
      debugPrint("toggleLike error: $e");
      rethrow;
    }
  }

  Future<void> saveItinerary(int itineraryId, {BuildContext? context}) async {
    try {
      final updated = await ItineraryService.savePublicPlan(itineraryId);
      _updateLocalState(updated);
      if (context != null) {
        // Optionally refresh saved list in another provider
        context.read<SavedProvider>().fetchSavedItineraries();
      }
    } catch (e) {
      debugPrint("saveItinerary error: $e");
      rethrow;
    }
  }

  Future<void> unsaveItinerary(int itineraryId, {BuildContext? context}) async {
    try {
      final updated = await ItineraryService.unsavePublicPlan(itineraryId);
      _updateLocalState(updated);
      if (context != null) {
        context.read<SavedProvider>().fetchSavedItineraries();
      }
    } catch (e) {
      debugPrint("unsaveItinerary error: $e");
      rethrow;
    }
  }

  // ===========================================================================
  // SHARE / UNSHARE
  // ===========================================================================

  Future<bool> shareTrip(int itineraryId) async {
    try {
      final updated = await ItineraryService.shareTrip(itineraryId);
      _updateLocalState(updated);
      return true;
    } catch (e) {
      debugPrint("shareTrip error: $e");
      return false;
    }
  }

  Future<bool> unshareTrip(int itineraryId) async {
    try {
      final updated = await ItineraryService.unshareTrip(itineraryId);
      _updateLocalState(updated);
      return true;
    } catch (e) {
      debugPrint("unshareTrip error: $e");
      return false;
    }
  }

  // ===========================================================================
  // COMPLETE TRIP
  // ===========================================================================

  Future<bool> finishTrip(int itineraryId) async {
    try {
      final updated = await ItineraryService.markAsComplete(itineraryId);
      _updateLocalState(updated);
      return true;
    } catch (e) {
      debugPrint("finishTrip error: $e");
      return false;
    }
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  Future<bool> deleteTrip(int itineraryId) async {
    try {
      await ItineraryService.deleteItinerary(itineraryId);
      _myPlans.removeWhere((it) => it.id == itineraryId);
      _publicPlans.removeWhere((it) => it.id == itineraryId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("deleteTrip error: $e");
      return false;
    }
  }

  // ===========================================================================
  // REFRESH & SYNC
  // ===========================================================================

  /// Fetch a single itinerary by id and update local state.
  Future<void> refreshItinerary(int itineraryId) async {
    try {
      final updated = await ItineraryService.getItineraryById(itineraryId);
      _updateLocalState(updated);
    } catch (e) {
      debugPrint("refreshItinerary error: $e");
    }
  }

  /// Sync all public plans with backend.
  Future<void> syncAllPublicPlans() async {
    await fetchPublicPlans();
  }

  /// Force refresh all data (public + personal).
  Future<void> refreshAllData() async {
    await Future.wait([
      fetchPublicPlans(),
      if (ApiClient.currentUserId != null) fetchMyPlans(),
    ]);
  }

  // ===========================================================================
  // UTILITY
  // ===========================================================================

  void clear() {
    _myPlans = [];
    _publicPlans = [];
    _destinations = [];
    _errorMessage = null;
    notifyListeners();
  }

  // ===========================================================================
  // PRIVATE LOADING SETTERS
  // ===========================================================================

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setPublicLoading(bool val) {
    _isPublicLoading = val;
    notifyListeners();
  }

  void _setDestinationsLoading(bool val) {
    _isDestinationsLoading = val;
    notifyListeners();
  }
}



// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:tour_guide/core/api/api_client.dart';
// import 'package:tour_guide/features/user/logic/saved_provider.dart';
// import '../data/models/itinerary.dart';
// import '../data/models/itinerary_item.dart';
// import '../data/services/itinerary_service.dart';

// class ItineraryProvider with ChangeNotifier {
//   // --- PERSONAL PLANS ---
//   List<Itinerary> _myPlans = [];
//   List<Itinerary> get myPlans => _myPlans;

//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   String? _errorMessage;
//   String? get errorMessage => _errorMessage;

//   // --- PUBLIC PLANS ---
//   List<Itinerary> _publicPlans = [];
//   List<Itinerary> get publicPlans => _publicPlans;

//   bool _isPublicLoading = false;
//   bool get isPublicLoading => _isPublicLoading;

//   List<Map<String, dynamic>> _destinations = [];
//   List<Map<String, dynamic>> get destinations => _destinations;
//   bool _isDestinationsLoading = false;
//   bool get isDestinationsLoading => _isDestinationsLoading;

//   void updateItineraryInAllLists(Itinerary updatedItinerary) {
//     // 1. Update or add to public plans
//     final publicIndex = _publicPlans.indexWhere(
//       (it) => it.id == updatedItinerary.id,
//     );
//     if (publicIndex != -1) {
//       _publicPlans[publicIndex] = updatedItinerary;
//     } else {
//       _publicPlans.add(updatedItinerary);
//     }

//     // 2. Update in my plans
//     final myPlanIndex = _myPlans.indexWhere(
//       (it) => it.id == updatedItinerary.id,
//     );
//     if (myPlanIndex != -1) {
//       _myPlans[myPlanIndex] = updatedItinerary;
//     }
//     notifyListeners();
//   }

//   /// Sync expert plans with the current provider state
//   List<Itinerary> syncExpertPlans(List<Itinerary> expertPlans) {
//     bool changed = false;

//     for (int i = 0; i < expertPlans.length; i++) {
//       final itinerary = expertPlans[i];

//       // Check if this itinerary exists in public plans with updated state
//       final updatedItinerary = _publicPlans.firstWhere(
//         (it) => it.id == itinerary.id,
//         orElse: () => itinerary,
//       );

//       // If different, update
//       if (updatedItinerary.isLikedByCurrentUser !=
//               itinerary.isLikedByCurrentUser ||
//           updatedItinerary.likeCount != itinerary.likeCount ||
//           updatedItinerary.isSavedByCurrentUser !=
//               itinerary.isSavedByCurrentUser) {
//         expertPlans[i] = updatedItinerary;
//         changed = true;
//       }
//     }

//     // Return the updated list
//     return expertPlans;
//   }

//   // Force refresh a single itinerary
//   Future<void> refreshItinerary(int itineraryId) async {
//     try {
//       await _fetchUpdatedItinerary(itineraryId);
//     } catch (e) {
//       debugPrint("Error refreshing itinerary: $e");
//     }
//   }

//   // --- FETCH METHODS ---

//   Future<void> fetchDestinations() async {
//     _isDestinationsLoading = true;
//     notifyListeners();
//     try {
//       _destinations = await ItineraryService.getAllDestinations();
//     } catch (e) {
//       debugPrint("Fetch destinations error: $e");
//       _destinations = [];
//     } finally {
//       _isDestinationsLoading = false;
//       notifyListeners();
//     }
//   }

//   /// Fetch user's own plans
//   Future<void> fetchMyPlans() async {
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();

//     try {
//       _myPlans = await ItineraryService.getMyPlans();
//     } catch (e) {
//       debugPrint("FetchMyPlans Error: $e");
//       _errorMessage = "Failed to load your trips";
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   /// Fetch public trips
//   Future<void> fetchPublicPlans() async {
//     _isPublicLoading = true;
//     _errorMessage = null; // Reset error message
//     notifyListeners();

//     try {
//       _publicPlans = await ItineraryService.getPublicTrips();
//       debugPrint("Fetched ${_publicPlans.length} public plans");
//     } catch (e) {
//       debugPrint("FetchPublicPlans Error: $e");
//       _errorMessage = "Could not load community trips."; // Set user-friendly error
//     } finally {
//       _isPublicLoading = false;
//       notifyListeners();
//     }
//   }

//   /// Fetch expert/admin templates
//   Future<List<Itinerary>> fetchExpertTemplates() async {
//     _isLoading = true; // Use a loading state
//     notifyListeners();
//     try {
//       final templates = await ItineraryService.getExpertTemplates();
//       return templates;
//     } catch (e) {
//       debugPrint("FetchExpertTemplates Error: $e");
//       // Don't just return []; set an error state so the UI knows why it's empty
//       _errorMessage = "Failed to load expert templates.";
//       return [];
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   /// Fetch itineraries by destination
//   Future<List<Itinerary>> fetchItinerariesByDestination(
//     int destinationId,
//   ) async {
//     try {
//       return await ItineraryService.getItinerariesByDestination(destinationId);
//     } catch (e) {
//       debugPrint("FetchByDestination Error: $e");
//       return [];
//     }
//   }

//   // --- CREATE & COPY ---

//   Future<Itinerary?> createNewTrip(Map<String, dynamic> data) async {
//     try {
//       final newTrip = await ItineraryService.createNewItinerary(data);
//       if (newTrip != null) {
//         _myPlans.insert(0, newTrip);
//         notifyListeners();
//       }
//       return newTrip;
//     } catch (e) {
//       debugPrint("CreateNewTrip Error: $e");
//       return null;
//     }
//   }

//   Future<Itinerary?> copyTrip(int itineraryId, {DateTime? startDate}) async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       // Pass the startDate to the service
//       final newTrip = await ItineraryService.copyItinerary(
//         itineraryId,
//         startDate: startDate,
//       );

//       _myPlans.insert(0, newTrip);

//       // Update copy count in public lists
//       final publicIndex = _publicPlans.indexWhere((it) => it.id == itineraryId);
//       if (publicIndex != -1) {
//         final publicTrip = _publicPlans[publicIndex];
//         _publicPlans[publicIndex] = publicTrip.copyWith(
//           copyCount: (publicTrip.copyCount ?? 0) + 1,
//         );
//       }

//       _isLoading = false;
//       notifyListeners();
//       return newTrip;
//     } catch (e) {
//       _isLoading = false;
//       _errorMessage = "Failed to copy trip";
//       notifyListeners();
//       return null;
//     }
//   }

//   // --- UPDATE METHODS ---

//   /// Update headers only
//   Future<bool> updateItineraryHeaders(Itinerary itinerary) async {
//     try {
//       final updated = await ItineraryService.updateItinerary(itinerary.id, {
//         'title': itinerary.title,
//         'description': itinerary.description,
//       });

//       int index = _myPlans.indexWhere((p) => p.id == itinerary.id);
//       if (index != -1) {
//         _myPlans[index] = updated;
//         notifyListeners();
//       }
//       return true;
//     } catch (e) {
//       debugPrint("UpdateHeaders Error: $e");
//       return false;
//     }
//   }

//   /// Update trip title and description
//   Future<bool> updatePlanDetails(
//     int itineraryId,
//     String newTitle,
//     String newDescription,
//   ) async {
//     try {
//       // Find the itinerary
//       int planIndex = _myPlans.indexWhere((p) => p.id == itineraryId);
//       if (planIndex == -1) return false;

//       final itinerary = _myPlans[planIndex];

//       // Call service to update
//       final updated = await ItineraryService.updateItinerary(itineraryId, {
//         'title': newTitle,
//         'description': newDescription,
//       });

//       // Update local state
//       _myPlans[planIndex] = updated;
//       notifyListeners();
//       return true;
//     } catch (e) {
//       debugPrint("UpdatePlanDetails Error: $e");
//       return false;
//     }
//   }

//   /// Update only the notes of a specific activity item
//   Future<void> updateActivityNotes(
//     int itineraryId,
//     int itemId,
//     String newNote,
//   ) async {
//     try {
//       // Call the service to update just the notes
//       await ItineraryService.updateItineraryItem(itineraryId, itemId, {
//         'notes': newNote,
//       });

//       // Update local state
//       int planIndex = _myPlans.indexWhere((p) => p.id == itineraryId);
//       if (planIndex != -1) {
//         final plan = _myPlans[planIndex];
//         if (plan.items != null) {
//           int itemIndex = plan.items!.indexWhere((item) => item.id == itemId);
//           if (itemIndex != -1) {
//             plan.items![itemIndex] = plan.items![itemIndex].copyWith(
//               notes: newNote,
//             );
//             _myPlans[planIndex] = plan;
//             notifyListeners();
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("UpdateActivityNotes Error: $e");
//       rethrow; // optional: let UI handle error
//     }
//   }

//   /// Save full itinerary (headers + items)
//   Future<bool> saveFullItinerary(
//     Itinerary itinerary,
//     List<ItineraryItem> items,
//   ) async {
//     try {
//       final itemsJson = items.map((e) => e.toJson()).toList();
//       final updated = await ItineraryService.updateFullItinerary(itinerary.id, {
//         'title': itinerary.title,
//         'description': itinerary.description,
//         'items': itemsJson,
//       });

//       int index = _myPlans.indexWhere((p) => p.id == itinerary.id);
//       if (index != -1) {
//         _myPlans[index] = updated;
//         notifyListeners();
//       }
//       return true;
//     } catch (e) {
//       debugPrint("SaveFullItinerary Error: $e");
//       return false;
//     }
//   }

//   /// Update single itinerary item (notes, time, etc.)
//   Future<void> updateItineraryItem(
//     int itineraryId,
//     int itemId,
//     Map<String, dynamic> data,
//   ) async {
//     try {
//       await ItineraryService.updateItineraryItem(itineraryId, itemId, data);

//       int planIndex = _myPlans.indexWhere((p) => p.id == itineraryId);
//       if (planIndex != -1) {
//         final plan = _myPlans[planIndex];
//         if (plan.items != null) {
//           int itemIndex = plan.items!.indexWhere((i) => i.id == itemId);
//           if (itemIndex != -1) {
//             plan.items![itemIndex] = plan.items![itemIndex].copyWith(
//               notes: data['notes'] ?? plan.items![itemIndex].notes,
//             );
//             _myPlans[planIndex] = plan;
//             notifyListeners();
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("UpdateItineraryItem Error: $e");
//       rethrow;
//     }
//   }

//   Future<bool> addDayToTrip(int itineraryId) async {
//     try {
//       // 1. Find the trip in local state
//       final tripIndex = _myPlans.indexWhere((p) => p.id == itineraryId);
//       if (tripIndex == -1) return false;

//       final currentTrip = _myPlans[tripIndex];
//       final int newTotalDays = (currentTrip.totalDays ?? 1) + 1;

//       // 2. Prepare data with proper Date formatting (YYYY-MM-DD)
//       final Map<String, dynamic> updateData = {
//         'title': currentTrip.title,
//         'description': currentTrip.description ?? "",
//         'totalDays': newTotalDays,
//         'theme': currentTrip.theme ?? "Adventure",
//       };

//       // Only add startDate if it exists, formatted specifically for backend date fields
//       if (currentTrip.startDate != null) {
//         updateData['startDate'] = currentTrip.startDate!
//             .toIso8601String()
//             .split('T')[0];
//       }

//       // 3. Call the service
//       // We treat the operation as successful if it doesn't throw an error
//       final response = await ItineraryService.updateItinerary(
//         itineraryId,
//         updateData,
//       );

//       // 4. Update local state optimistically or with response
//       _myPlans[tripIndex] = currentTrip.copyWith(
//         totalDays: newTotalDays,
//         // Ensure we don't accidentally null out the date locally
//         startDate: currentTrip.startDate,
//       );

//       notifyListeners();
//       return true; // Explicitly return true because the call succeeded
//     } catch (e) {
//       debugPrint("Error adding day: $e");
//       return false;
//     }
//   }

//   Future<bool> removeLastDay(int itineraryId) async {
//     try {
//       final tripIndex = _myPlans.indexWhere((p) => p.id == itineraryId);
//       if (tripIndex == -1) return false;

//       final currentTrip = _myPlans[tripIndex];
//       final int currentDays = currentTrip.totalDays ?? 1;

//       if (currentDays <= 1) return false;

//       final int newTotalDays = currentDays - 1;

//       // Calculate new end date locally for immediate UI update
//       DateTime? newEndDate;
//       if (currentTrip.startDate != null) {
//         newEndDate = currentTrip.startDate!.add(
//           Duration(days: newTotalDays - 1),
//         );
//       }

//       final Map<String, dynamic> updateData = {
//         'totalDays': newTotalDays,
//         'title': currentTrip.title,
//         'startDate': currentTrip.startDate?.toIso8601String().split('T')[0],
//         // Let the backend know we expect this new end date
//         'endDate': newEndDate?.toIso8601String().split('T')[0],
//       };

//       await ItineraryService.updateItinerary(itineraryId, updateData);

//       // Update local state with BOTH new day count and new end date
//       _myPlans[tripIndex] = currentTrip.copyWith(
//         totalDays: newTotalDays,
//         endDate: newEndDate,
//       );

//       notifyListeners();
//       return true;
//     } catch (e) {
//       debugPrint("Error removing day: $e");
//       return false;
//     }
//   }

//   // --- TOGGLE & COMPLETE ---

//   Future<void> toggleItemVisited(
//     int itineraryId,
//     int itemId,
//     bool isVisited,
//   ) async {
//     try {
//       await ItineraryService.toggleItemVisited(itineraryId, itemId, isVisited);

//       int planIndex = _myPlans.indexWhere((p) => p.id == itineraryId);
//       if (planIndex != -1) {
//         final plan = _myPlans[planIndex];
//         if (plan.items != null) {
//           int itemIndex = plan.items!.indexWhere((i) => i.id == itemId);
//           if (itemIndex != -1) {
//             plan.items![itemIndex] = plan.items![itemIndex].copyWith(
//               isVisited: isVisited,
//             );
//             _myPlans[planIndex] = plan;
//             notifyListeners();
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("ToggleItemVisited Error: $e");
//       rethrow;
//     }
//   }

//   Future<bool> finishTrip(int id) async {
//     try {
//       final updated = await ItineraryService.markAsComplete(id);
//       int index = _myPlans.indexWhere((p) => p.id == id);
//       if (index != -1) {
//         _myPlans[index] = updated;
//         notifyListeners();
//       }
//       return true;
//     } catch (e) {
//       debugPrint("FinishTrip Error: $e");
//       return false;
//     }
//   }

//   // --- SHARE ---

//   /// Shares a trip to make it public
//   Future<bool> shareTrip(int id) async {
//     final planIndex = _myPlans.indexWhere((p) => p.id == id);
//     if (planIndex == -1) return false;

//     final trip = _myPlans[planIndex];

//     // Check if trip is copied - backend will reject it
//     if (trip.sourceId != null) {
//       debugPrint("Cannot share a copied trip");
//       return false;
//     }

//     // Check if trip is already public
//     if (trip.isPublic) {
//       debugPrint("Trip is already public");
//       return false;
//     }

//     // Check if trip is completed
//     if (trip.status != 'COMPLETED') {
//       debugPrint("Only completed trips can be shared");
//       return false;
//     }

//     try {
//       final updated = await ItineraryService.shareTrip(id);
//       if (updated != null) {
//         _myPlans[planIndex] = updated;
//         notifyListeners();
//         return true;
//       }
//       return false;
//     } catch (e) {
//       debugPrint("Error sharing itinerary: $e");
//       return false;
//     }
//   }

//   /// Makes a public trip private
//   Future<bool> unshareTrip(int id) async {
//     final planIndex = _myPlans.indexWhere((p) => p.id == id);
//     if (planIndex == -1) return false;

//     final trip = _myPlans[planIndex];

//     // Check if trip is actually public
//     if (!(trip.isPublic)) {
//       debugPrint("Trip is already private");
//       return false;
//     }

//     try {
//       final updated = await ItineraryService.unshareTrip(id);
//       if (updated != null) {
//         _myPlans[planIndex] = updated;
//         notifyListeners();
//         return true;
//       }
//       return false;
//     } catch (e) {
//       debugPrint("Error unsharing itinerary: $e");
//       return false;
//     }
//   }

//   // --- DELETE ---

//   Future<bool> deleteTrip(int id) async {
//     try {
//       await ItineraryService.deleteItinerary(id);
//       _myPlans.removeWhere((p) => p.id == id);
//       notifyListeners();
//       return true;
//     } catch (e) {
//       debugPrint("DeleteTrip Error: $e");
//       return false;
//     }
//   }

//   /// Deletes a trip by ID (wrapper for deleteTrip)
//   Future<bool> deletePlan(int itineraryId) async {
//     return await deleteTrip(itineraryId);
//   }

//   // Saving Public Trips with optimistic updates
//   /// Save any itinerary (public, expert, or personal)
//   Future<void> saveItinerary(int itineraryId, {BuildContext? context}) async {
//     try {
//       int publicIndex = _publicPlans.indexWhere((it) => it.id == itineraryId);

//       bool isCurrentlySaved = false;

//       if (publicIndex != -1) {
//         isCurrentlySaved =
//             _publicPlans[publicIndex].isSavedByCurrentUser ?? false;
//       }
//       if (isCurrentlySaved) {
//         return;
//       }
//       final updatedItinerary = await ItineraryService.savePublicPlan(
//         itineraryId,
//       );
//       if (publicIndex != -1) {
//         _publicPlans[publicIndex] = updatedItinerary;
//         notifyListeners();
//       }
//       if (context != null) {
//         try {
//           final savedProvider = context.read<SavedProvider>();
//           await savedProvider.fetchSavedItineraries(); // Refresh saved list
//         } catch (e) {
//           debugPrint('Could not update SavedProvider: $e');
//         }
//       }
//     } catch (e) {
//       debugPrint('Error in saveItinerary: $e');
//       rethrow;
//     }
//   }

//   /// Unsave any itinerary
//   Future<void> unsaveItinerary(int itineraryId, {BuildContext? context}) async {
//     try {
//       int publicIndex = _publicPlans.indexWhere((it) => it.id == itineraryId);

//       bool isCurrentlySaved = false;

//       if (publicIndex != -1) {
//         isCurrentlySaved =
//             _publicPlans[publicIndex].isSavedByCurrentUser ?? false;
//       }
//       if (!isCurrentlySaved) {
//         return;
//       }
//       final updatedItinerary = await ItineraryService.unsavePublicPlan(
//         itineraryId,
//       );
//       if (publicIndex != -1) {
//         _publicPlans[publicIndex] = updatedItinerary;
//         notifyListeners();
//       }
//       if (context != null) {
//         try {
//           final savedProvider = context.read<SavedProvider>();
//           await savedProvider.fetchSavedItineraries(); // Refresh saved list
//         } catch (e) {
//           debugPrint('Could not update SavedProvider: $e');
//         }
//       }
//     } catch (e) {
//       debugPrint('Error in unsaveItinerary: $e');
//       rethrow;
//     }
//   }

//   /// Toggle like for any itinerary
//   Future<void> toggleLike(int itineraryId, {BuildContext? context}) async {
//     try {
//       final updatedItinerary = await ItineraryService.toggleLike(itineraryId);
//       updateItineraryInAllLists(updatedItinerary);
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // Helper method to fetch updated itinerary
//   Future<void> _fetchUpdatedItinerary(int itineraryId) async {
//     try {
//       final response = await ApiClient.get('/api/v1/itineraries/$itineraryId');
      
//       // Ensure response is cast as a Map before passing to fromJson
//       if (response is Map<String, dynamic>) {
//         final updatedItinerary = Itinerary.fromJson(response);
//         updateItineraryInAllLists(updatedItinerary);
//       }
//     } catch (e) {
//       debugPrint("Failed to fetch updated itinerary $itineraryId: $e");
//     }
//   }

//   /// Sync a single itinerary's saved/liked state with backend
//   Future<void> syncItineraryState(int itineraryId) async {
//     try {
//       await _fetchUpdatedItinerary(itineraryId);
//     } catch (e) {
//       debugPrint('Failed to sync itinerary $itineraryId: $e');
//     }
//   }

//   /// Sync all public plans with backend
//   Future<void> syncAllPublicPlans() async {
//     try {
//       await fetchPublicPlans();
//     } catch (e) {
//       debugPrint('Failed to sync public plans: $e');
//     }
//   }

//   /// Force refresh all data
//   Future<void> refreshAllData() async {
//     try {
//       // Fetch public plans
//       await fetchPublicPlans();

//       // Fetch my plans if user is logged in
//       if (ApiClient.currentUserId != null) {
//         await fetchMyPlans();
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Error refreshing all data: $e');
//       debugPrint('Stack trace: $stackTrace');
//     }
//   }

//   // --- UTILITIES ---

//   void clear() {
//     _myPlans = [];
//     _publicPlans = [];
//     _errorMessage = null;
//     notifyListeners();
//   }
// }
