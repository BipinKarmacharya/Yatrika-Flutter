import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    notifyListeners();

    try {
      _publicPlans = await ItineraryService.getPublicTrips();
    } catch (e) {
      debugPrint("FetchPublicPlans Error: $e");
    } finally {
      _isPublicLoading = false;
      notifyListeners();
    }
  }

  /// Fetch expert/admin templates
  Future<List<Itinerary>> fetchExpertTemplates() async {
    try {
      return await ItineraryService.getExpertTemplates();
    } catch (e) {
      debugPrint("FetchExpertTemplates Error: $e");
      return [];
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

  Future<Itinerary?> copyTrip(int itineraryId) async {
    try {
      final newTrip = await ItineraryService.copyItinerary(itineraryId);
      await fetchMyPlans();
      return newTrip;
    } catch (e) {
      debugPrint("CopyTrip Error: $e");
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
    if (trip.isPublic ?? false) {
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

  // Saving Public Trips
  Future<void> savePublicPlan(int itineraryId, {BuildContext? context}) async {
    try {
      // If context is provided, use SavedProvider
      if (context != null) {
        final savedProvider = context.read<SavedProvider>();
        await savedProvider.saveItinerary(itineraryId);
      } else {
        // Fallback to old method
        await ItineraryService.savePublicPlan(itineraryId);
      }

      // Refresh public plans to show updated state
      await fetchPublicPlans();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to save public plan: $e');
    }
  }

  Future<void> toggleLike(int itineraryId) async {
    try {
      await ItineraryService.toggleLike(itineraryId);
      // Refresh to get updated like count
      await fetchPublicPlans();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
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

// import 'package:flutter/material.dart';
// import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';
// import '../data/models/itinerary.dart';
// import '../data/services/itinerary_service.dart';

// class ItineraryProvider extends ChangeNotifier {
//   List<Itinerary> _myPlans = [];
//   bool _isLoading = false;
//   String? _errorMessage;

//   List<Itinerary> _publicPlans = [];
//   List<Itinerary> get publicPlans => _publicPlans;

//   bool _isPublicLoading = false;
//   bool get isPublicLoading => _isPublicLoading;

//   // --- GETTERS ---
//   List<Itinerary> get myPlans => _myPlans;
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;

//   // --- ACTIONS ---

//   /// Create a quick empty trip (just title and destination)
//   Future<Itinerary?> createQuickTrip({
//     required String title,
//     required String destination,
//   }) async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       final newTrip = await ItineraryService.createNewItinerary({
//         'title': title,
//         'description': 'Trip to $destination',
//         'destination': destination,
//         'is_quick_start': true,
//       });

//       if (newTrip != null) {
//         _myPlans.insert(0, newTrip); // Add to beginning of list
//         notifyListeners();
//         return newTrip;
//       }
//       return null;
//     } catch (e) {
//       debugPrint("Create Quick Trip Error: $e");
//       _errorMessage = "Failed to create trip. Please try again.";
//       notifyListeners();
//       return null;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   /// Create a detailed trip with all parameters
//   Future<Itinerary?> createDetailedTrip({
//     required String title,
//     required String destination,
//     int? totalDays,
//     int? travelers,
//     double? budget,
//     String? notes,
//   }) async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       final Map<String, dynamic> tripData = {
//         'title': title,
//         'description': notes ?? 'Trip to $destination',
//         'destination': destination,
//         'is_quick_start': false,
//       };

//       // Add optional fields if provided
//       if (totalDays != null) tripData['total_days'] = totalDays;
//       if (travelers != null) tripData['travelers'] = travelers;
//       if (budget != null) tripData['budget'] = budget;

//       final newTrip = await ItineraryService.createNewItinerary(tripData);

//       if (newTrip != null) {
//         _myPlans.insert(0, newTrip);
//         notifyListeners();
//         return newTrip;
//       }
//       return null;
//     } catch (e) {
//       debugPrint("Create Detailed Trip Error: $e");
//       _errorMessage = "Failed to create detailed trip. Please try again.";
//       notifyListeners();
//       return null;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   /// Fetches personal plans from the database
//   Future<void> fetchMyPlans() async {
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();

//     try {
//       _myPlans = await ItineraryService.getMyPlans();

//       // DEBUG: Check what was parsed
//       debugPrint("📦 fetchMyPlans completed - Got ${_myPlans.length} plans");
//       for (var plan in _myPlans) {
//         debugPrint("   Plan ${plan.id}: ${plan.items?.length ?? 0} items");
//         if (plan.items != null) {
//           for (var item in plan.items!) {
//             debugPrint("     Item ${item.id}: isVisited=${item.isVisited}");
//           }
//         }
//       }
//     } catch (e) {
//       _errorMessage = "Failed to load your trips. Please try again.";
//       debugPrint("FetchMyPlans Error: $e");
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   /// Update plan basic details
//   Future<bool> updatePlanDetails(
//     int id,
//     String title,
//     String description,
//   ) async {
//     try {
//       final updated = await ItineraryService.updateItinerary(id, {
//         'title': title,
//         'description': description,
//       });

//       // Update the item in our local list
//       int index = _myPlans.indexWhere((p) => p.id == id);
//       if (index != -1) {
//         _myPlans[index] = updated;
//         notifyListeners();
//       }
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }

//   /// Toggle activity progress and update local state
//   Future<void> toggleActivityProgress(
//     int itineraryId,
//     int itemId,
//     bool isVisited,
//   ) async {
//     try {
//       debugPrint(
//         "🔄 toggleActivityProgress: itemId=$itemId, visited=$isVisited",
//       );

//       // Call the service
//       await ItineraryService.toggleItemVisited(itineraryId, itemId, isVisited);

//       // Update local state
//       int planIndex = _myPlans.indexWhere((p) => p.id == itineraryId);
//       if (planIndex != -1) {
//         final plan = _myPlans[planIndex];

//         // If items is null, we need to fetch them or initialize empty list
//         List<ItineraryItem> updatedItems = plan.items != null
//             ? List.from(plan.items!)
//             : [];

//         int itemIndex = updatedItems.indexWhere((item) => item.id == itemId);
//         if (itemIndex != -1) {
//           updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(
//             isVisited: isVisited,
//           );

//           _myPlans[planIndex] = plan.copyWith(items: updatedItems);

//           // Update summary
//           int visitedCount = updatedItems
//               .where((item) => item.isVisited)
//               .length;
//           if (plan.summary != null) {
//             _myPlans[planIndex] = _myPlans[planIndex].copyWith(
//               summary: plan.summary!.copyWith(
//                 completedActivities: visitedCount,
//               ),
//             );
//           }

//           notifyListeners();
//           debugPrint("✅ Updated: $visitedCount visited activities");
//         } else {
//           debugPrint("❌ Item not found in provider: $itemId");
//           // Item not in provider, need to refresh from API
//           await _refreshPlanFromApi(itineraryId);
//         }
//       }
//     } catch (e) {
//       debugPrint("❌ Progress Sync Error: $e");
//       throw Exception("Failed to update progress: $e");
//     }
//   }

//   // Helper method to refresh a single plan
//   Future<void> _refreshPlanFromApi(int itineraryId) async {
//     try {
//       final data = await ItineraryService.getItineraryDetails(itineraryId);
//       final updatedItinerary = Itinerary.fromJson(data);

//       int planIndex = _myPlans.indexWhere((p) => p.id == itineraryId);
//       if (planIndex != -1) {
//         _myPlans[planIndex] = updatedItinerary;
//         notifyListeners();
//         debugPrint("✅ Refreshed plan $itineraryId from API");
//       }
//     } catch (e) {
//       debugPrint("❌ Failed to refresh plan: $e");
//     }
//   }

//   /// Deletes a trip and updates the local list instantly (Optimistic UI)
//   Future<bool> deletePlan(int itineraryId) async {
//     try {
//       await ItineraryService.deleteItinerary(itineraryId);

//       // Update local state immediately so the card disappears
//       _myPlans.removeWhere((plan) => plan.id == itineraryId);
//       notifyListeners();
//       return true;
//     } catch (e) {
//       _errorMessage = "Could not delete trip.";
//       notifyListeners();
//       return false;
//     }
//   }

//   Future<bool> saveFullItinerary(
//     Itinerary updatedItinerary,
//     List<ItineraryItem> items,
//   ) async {
//     try {
//       final itemsJson = items.map((item) => item.toJson()).toList();

//       final response =
//           await ItineraryService.updateFullItinerary(updatedItinerary.id, {
//             'title': updatedItinerary.title,
//             'description': updatedItinerary.description,
//             'items': itemsJson,
//           });
//       int index = _myPlans.indexWhere((p) => p.id == updatedItinerary.id);
//       if (index != -1) {
//         _myPlans[index] = response;
//         notifyListeners();
//       }
//       return true;
//     } catch (e) {
//       debugPrint("Save Full Itinerary Error: $e");
//       return false;
//     }
//   }

//   /// Updates only the notes of a specific activity item independently
//   Future<void> updateActivityNotes(
//     int itineraryId,
//     int itemId,
//     String newNote,
//   ) async {
//     try {
//       // 1. Call the service to update the database
//       await ItineraryService.updateItineraryItem(itineraryId, itemId, {
//         'notes': newNote,
//       });

//       // 2. Update the local state in _myPlans so the change persists
//       // even if the user leaves the screen and comes back.
//       int planIndex = _myPlans.indexWhere((p) => p.id == itineraryId);
//       if (planIndex != -1) {
//         final plan = _myPlans[planIndex];
//         if (plan.items != null) {
//           int itemIndex = plan.items!.indexWhere((item) => item.id == itemId);
//           if (itemIndex != -1) {
//             plan.items![itemIndex] = plan.items![itemIndex].copyWith(
//               notes: newNote,
//             );
//             notifyListeners();
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("Update Note Error: $e");
//       rethrow; // Pass error back to the UI if needed
//     }
//   }

//   /// Use this when copying a trip from the Explore feed
//   /// to ensure the Profile tab stays in sync.
//   void addPlanLocally(Itinerary newPlan) {
//     _myPlans.insert(0, newPlan); // Add to the top of the list
//     notifyListeners();
//   }

//   /// Call this during logout to prevent the next user from seeing old data
//   void clear() {
//     _myPlans = [];
//     _errorMessage = null;
//     notifyListeners();
//   }

//   /// Create New Trip from Scratch
//   ///
//   /// Mark complete
//   Future<bool> finishTrip(int id) async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       // Use the specific PATCH endpoint
//       final updated = await ItineraryService.markAsComplete(id);

//       int index = _myPlans.indexWhere((p) => p.id == id);
//       if (index != -1) {
//         _myPlans[index] = updated;
//         notifyListeners();
//       }
//       return true;
//     } catch (e) {
//       debugPrint("Finish Trip Error: $e");
//       return false;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   /// Shares a completed original trip to the community
//   Future<bool> shareTrip(int id) async {
//     // Find the itinerary in local state
//     final planIndex = _myPlans.indexWhere((p) => p.id == id);
//     if (planIndex == -1) return false;

//     final trip = _myPlans[planIndex];

//     // Prevent sharing copied trips
//     if (trip.isCopied) {
//       debugPrint("⚠️ Cannot share copied trips");
//       return false; // Or show a snackbar/toast from UI
//     }

//     try {
//       _isLoading = true;
//       notifyListeners();

//       final updatedTrip = await ItineraryService.shareTrip(id);

//       if (updatedTrip != null) {
//         _myPlans[planIndex] = updatedTrip;
//         notifyListeners();
//         return true;
//       }
//       return false;
//     } catch (e) {
//       debugPrint("Provider Share Error: $e");
//       return false;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   /// Fetch all User Created Public Plan
//   Future<void> fetchPublicPlans() async {
//     _isPublicLoading = true;
//     notifyListeners();
//     try {
//       _publicPlans = await ItineraryService.getPublicTrips();
//     } catch (e) {
//       debugPrint("Error fetching public trips: $e");
//     } finally {
//       _isPublicLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<Itinerary?> copyTrip(int itineraryId) async {
//     try {
//       final newTrip = await ItineraryService.copyItinerary(itineraryId);
//       // Refresh the local list of personal plans so 'isAlreadyCopied' updates
//       await fetchMyPlans();
//       return newTrip;
//     } catch (e) {
//       debugPrint("Copy Trip Error: $e");
//       return null;
//     }
//   }
// }
