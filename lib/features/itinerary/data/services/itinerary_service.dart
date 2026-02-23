import 'package:flutter/foundation.dart';
import 'package:tour_guide/core/api/api_client.dart';
import '../models/itinerary.dart';

class ItineraryService {
  static const String _featurePath = '/api/v1/itineraries';

  // ===========================================================================
  // HELPER: MAPPING & PARSING (handles both paginated and flat lists)
  // ===========================================================================

  static List<Itinerary> _mapItineraryList(dynamic responseData) {
    if (responseData == null) return [];
    List<dynamic> list = [];
    if (responseData is Map) {
      // Paginated response (Page object)
      list = responseData['content'] ?? responseData['data'] ?? [];
    } else if (responseData is List) {
      list = responseData;
    }
    return list
        .map((json) => Itinerary.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ===========================================================================
  // DISCOVERY
  // ===========================================================================

  /// Fetch admin‑created templates (expert trips)
  static Future<List<Itinerary>> getExpertTemplates() async {
    final response = await ApiClient.get('$_featurePath/admin-templates');
    return _mapItineraryList(response);
  }

  /// Fetch public community trips (completed, non‑admin, non‑copied)
  static Future<List<Itinerary>> getPublicTrips() async {
    final response = await ApiClient.get('$_featurePath/community');
    return _mapItineraryList(response);
  }

  /// Fetch a single itinerary by ID (used for refresh)
  static Future<Itinerary> getItineraryById(int id) async {
    final response = await ApiClient.get('$_featurePath/$id');
    return Itinerary.fromJson(response);
  }

  // ===========================================================================
  // PERSONAL MANAGEMENT
  // ===========================================================================

  /// Create an empty draft itinerary
  static Future<Itinerary> createNewItinerary(Map<String, dynamic> data) async {
    final response = await ApiClient.post(_featurePath, body: data);
    return Itinerary.fromJson(response);
  }

  /// Fetch the current user’s itineraries (paginated, returns content list)
  static Future<List<Itinerary>> getMyPlans() async {
    final response = await ApiClient.get('$_featurePath/my-plans');
    return _mapItineraryList(response);
  }

  /// Update only the header fields (title, description, dates, etc.)
  static Future<Itinerary> updateItineraryHeader(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiClient.patch('$_featurePath/$id', body: data);
    return Itinerary.fromJson(response);
  }

  /// Mark a trip as COMPLETED (must have at least one item)
  static Future<Itinerary> markAsComplete(int id) async {
    final response = await ApiClient.patch('$_featurePath/$id/complete');
    return Itinerary.fromJson(response);
  }

  /// Delete an itinerary (owned by the current user)
  static Future<void> deleteItinerary(int id) async {
    await ApiClient.delete('$_featurePath/$id');
  }

  // ===========================================================================
  // ITEM MANAGEMENT (all return full itinerary for instant sync)
  // ===========================================================================

  /// Add a new item to an itinerary
  static Future<Itinerary> addItem(
    int itineraryId,
    Map<String, dynamic> itemData,
  ) async {
    final response = await ApiClient.post(
      '$_featurePath/$itineraryId/items',
      body: itemData,
    );
    return Itinerary.fromJson(response);
  }

  /// Update an existing item
  static Future<Itinerary> updateItineraryItem(
    int itineraryId,
    int itemId,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiClient.put(
      '$_featurePath/$itineraryId/items/$itemId',
      body: data,
    );
    return Itinerary.fromJson(response);
  }

  /// Remove an item (delete returns void)
  static Future<void> removeItem(int itineraryId, int itemId) async {
    await ApiClient.delete('$_featurePath/$itineraryId/items/$itemId');
  }

  /// Toggle visited status of an item
  static Future<void> toggleItemVisited(
    int itineraryId,
    int itemId,
    bool isVisited,
  ) async {
    try {
      await ApiClient.patch(
        '$_featurePath/$itineraryId/items/$itemId/toggle-visited',
        query: {'visited': isVisited},
      );
    } catch (e) {
      debugPrint("Error toggling visited: $e");
      throw Exception("Failed to update visited status");
    }
  }

  /// Reorder items within a day (or globally, depending on backend)
  static Future<Itinerary> reorderItems(
    int itineraryId,
    List<int> itemIdsInOrder,
  ) async {
    final response = await ApiClient.patch(
      '$_featurePath/$itineraryId/items/reorder',
      body: itemIdsInOrder, // backend expects a list of IDs in new order
    );
    return Itinerary.fromJson(response);
  }

  /// Full update (headers + items) – if your backend supports it
  static Future<Itinerary> updateFullItinerary(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiClient.put('$_featurePath/$id/full', body: data);
    return Itinerary.fromJson(response);
  }

  // ===========================================================================
  // COPY & SHARE
  // ===========================================================================

  /// Copy an existing itinerary (optionally with a new start date)
  static Future<Itinerary> copyItinerary(int id, {DateTime? startDate}) async {
    // 1. Create the body map instead of a query map
    Map<String, dynamic>? body;

    if (startDate != null) {
      // Format: YYYY-MM-DD
      final String formattedDate =
          "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";

      body = {'startDate': formattedDate};
    }

    // 2. Pass 'body' to ApiClient.post (remove 'query')
    final response = await ApiClient.post(
      '$_featurePath/$id/copy',
      body: body, // Data goes here for JSON @RequestBody
    );

    return Itinerary.fromJson(response);
  }

  /// Make a private trip public (only if completed and not copied)
  static Future<Itinerary> shareTrip(int id) async {
    final response = await ApiClient.patch('$_featurePath/$id/share');
    return Itinerary.fromJson(response);
  }

  /// Revert a public trip to private
  static Future<Itinerary> unshareTrip(int id) async {
    final response = await ApiClient.patch('$_featurePath/$id/unshare');
    return Itinerary.fromJson(response);
  }

  // ===========================================================================
  // SOCIAL (SAVE / LIKE)
  // ===========================================================================

  /// Save a public itinerary to the user’s saved list
  static Future<Itinerary> savePublicPlan(int itineraryId) async {
    final response = await ApiClient.post('$_featurePath/$itineraryId/save');
    return Itinerary.fromJson(response);
  }

  /// Remove an itinerary from the user’s saved list
  static Future<Itinerary> unsavePublicPlan(int itineraryId) async {
    final response = await ApiClient.delete('$_featurePath/$itineraryId/save');
    return Itinerary.fromJson(response);
  }

  /// Toggle like on an itinerary (returns updated itinerary)
  static Future<Itinerary> toggleLike(int itineraryId) async {
    final response = await ApiClient.post(
      '$_featurePath/$itineraryId/like/toggle',
    );
    return Itinerary.fromJson(response);
  }

  // ===========================================================================
  // ADDITIONAL ENDPOINTS (used by the provider, may belong to other domains)
  // ===========================================================================

  /// Fetch all destinations (for dropdowns, etc.) – consider moving to DestinationService
  static Future<List<Map<String, dynamic>>> getAllDestinations() async {
    final response = await ApiClient.get('/api/destinations');
    if (response is Map && response.containsKey('content')) {
      return List<Map<String, dynamic>>.from(response['content']);
    }
    return [];
  }

  /// Fetch itineraries by destination – if such an endpoint exists
  static Future<List<Itinerary>> getItinerariesByDestination(
    int destinationId,
  ) async {
    final response = await ApiClient.get(
      '$_featurePath/destination/$destinationId',
    );
    return _mapItineraryList(response);
  }

  /// Recommended itineraries (home screen) – if endpoint exists
  static Future<List<Itinerary>> getRecommended() async {
    final response = await ApiClient.get('$_featurePath/recommended');
    return _mapItineraryList(response);
  }
}



// import 'package:flutter/foundation.dart';
// import 'package:tour_guide/core/api/api_client.dart';
// import '../models/itinerary.dart';

// class ItineraryService {
//   static const String _featurePath = '/api/v1/itineraries';

//   /// CREATE: Create a brand new itinerary
//   static Future<Itinerary?> createNewItinerary(
//     Map<String, dynamic> data,
//   ) async {
//     try {
//       print("SENDING TO BACKEND: $data");
//       final response = await ApiClient.post(_featurePath, body: data);
//       return Itinerary.fromJson(response);
//     } catch (e) {
//       debugPrint("Create itinerary error: $e");
//       return null;
//     }
//   }

//   /// Fetch user's own plans with pagination
//   static Future<List<Itinerary>> getMyPlans({
//     int page = 0,
//     int size = 20,
//   }) async {
//     try {
//       final dynamic responseData = await ApiClient.get(
//         '$_featurePath/my-plans',
//         query: {'page': page, 'size': size},
//       );

//       // Check the response structure
//       if (responseData is Map) {
//         // Handle paginated response
//         final List<dynamic> data =
//             responseData['content'] ?? responseData['data'] ?? [];
//         return data.map((json) => Itinerary.fromJson(json)).toList();
//       } else if (responseData is List) {
//         // Handle list response directly
//         return responseData.map((json) => Itinerary.fromJson(json)).toList();
//       }
//       return [];
//     } catch (e) {
//       debugPrint("Error fetching my plans: $e");
//       throw Exception("Failed to load your trips");
//     }
//   }

//   /// FETCH RECOMMENDED ITINERARIES (for Home screen)
//   static Future<List<Itinerary>> getRecommended() async {
//     try {
//       final List<dynamic> data = await ApiClient.get(
//         '$_featurePath/recommended',
//       );

//       return data.map((json) => Itinerary.fromJson(json)).toList();
//     } catch (e) {
//       debugPrint("Error fetching recommended itineraries: $e");
//       return [];
//     }
//   }

//   static List<Itinerary> _mapItineraryList(dynamic responseData) {
//     if (responseData == null) return [];
    
//     List<dynamic> list = [];
//     if (responseData is Map) {
//       list = responseData['content'] ?? responseData['data'] ?? [];
//     } else if (responseData is List) {
//       list = responseData;
//     }

//     return list.map((json) {
//       try {
//         return Itinerary.fromJson(json as Map<String, dynamic>);
//       } catch (e) {
//         debugPrint("❌ Failed to parse Itinerary item: $e");
//         // We return a 'null' or skip to prevent the whole screen from crashing
//         return null; 
//       }
//     }).whereType<Itinerary>().toList(); // Removes any nulls from failed parses
//   }

//   // Then update your methods to use that helper:
//   static Future<List<Itinerary>> getExpertTemplates() async {
//     try {
//       final response = await ApiClient.get('$_featurePath/admin-templates');
//       return _mapItineraryList(response);
//     } catch (e) {
//       debugPrint("Expert Templates Error: $e");
//       return [];
//     }
//   }

//   static Future<List<Itinerary>> getPublicTrips() async {
//     try {
//       final response = await ApiClient.get('$_featurePath/community');
//       return _mapItineraryList(response);
//     } catch (e) {
//       debugPrint("Public Trips Error: $e");
//       return [];
//     }
//   }


//   /// FETCH BY DESTINATION
//   static Future<List<Itinerary>> getItinerariesByDestination(
//     int destinationId,
//   ) async {
//     try {
//       final List<dynamic> data = await ApiClient.get(
//         '$_featurePath/destination/$destinationId',
//       );
//       return data.map((json) => Itinerary.fromJson(json)).toList();
//     } catch (e) {
//       debugPrint("Error fetching itineraries for destination: $e");
//       return [];
//     }
//   }

//   /// FETCH ALL DESTINATIONS
//   static Future<List<Map<String, dynamic>>> getAllDestinations() async {
//     try {
//       final dynamic response = await ApiClient.get('/api/destinations');
//       if (response is Map && response.containsKey('content')) {
//         return List<Map<String, dynamic>>.from(response['content']);
//       }
//       return [];
//     } catch (e) {
//       debugPrint("Error fetching all destinations: $e");
//       return [];
//     }
//   }

//   /// FETCH DETAILS
//   static Future<Map<String, dynamic>> getItineraryDetails(int id) async {
//     try {
//       final dynamic response = await ApiClient.get('$_featurePath/$id');
//       print(
//         "RAW API RESPONSE FOR ITINERARY: $response",
//       ); // Check if 'userId' or 'user_id' is here
//       return response as Map<String, dynamic>;
//     } catch (e) {
//       debugPrint("Error fetching itinerary details: $e");
//       throw Exception("Failed to load itinerary details");
//     }
//   }

//   /// COPY ITINERARY
//   static Future<Itinerary> copyItinerary(int id, {DateTime? startDate}) async {
//     try {
//       Map<String, dynamic>? body;
//       if (startDate != null) {
//         body = {'startDate': startDate.toIso8601String().split('T')[0]};
//       }

//       final dynamic response = await ApiClient.post(
//         '$_featurePath/$id/copy',
//         body: body, // Now sends the chosen date to backend
//       );
//       return Itinerary.fromJson(response);
//     } catch (e) {
//       debugPrint("Error copying itinerary: $e");
//       throw Exception("Failed to copy itinerary");
//     }
//   }

//   /// UPDATE HEADERS (title + description)
//   static Future<Itinerary> updateItinerary(
//     int id,
//     Map<String, dynamic> data,
//   ) async {
//     try {
//       final dynamic response = await ApiClient.patch(
//         '$_featurePath/$id',
//         body: data,
//       );

//       // If your backend returns 204 No Content, response might be null.
//       // In that case, we can't parse it, so handle accordingly:
//       if (response == null) {
//         throw Exception("No data returned from server");
//       }

//       return Itinerary.fromJson(response);
//     } catch (e) {
//       debugPrint("Error updating itinerary: $e");
//       // If it's a 400/500 error, ApiClient usually throws, which is caught here
//       throw Exception("Failed to update itinerary");
//     }
//   }

//   /// UPDATE FULL ITINERARY (headers + items)
//   static Future<Itinerary> updateFullItinerary(
//     int id,
//     Map<String, dynamic> data,
//   ) async {
//     try {
//       // Backend expects ItineraryRequest format
//       final Map<String, dynamic> requestData = {
//         'title': data['title'] ?? '',
//         'description': data['description'] ?? '',
//         'items': data['items'] ?? [],
//       };

//       final dynamic response = await ApiClient.put(
//         '$_featurePath/$id/full',
//         body: requestData,
//       );
//       return Itinerary.fromJson(response);
//     } catch (e) {
//       debugPrint("Error updating full itinerary: $e");
//       throw Exception("Failed to update full itinerary");
//     }
//   }

//   /// DELETE ITINERARY
//   static Future<void> deleteItinerary(int id) async {
//     await ApiClient.delete('$_featurePath/$id');
//   }

//   /// MARK COMPLETE
//   static Future<Itinerary> markAsComplete(int id) async {
//     try {
//       final dynamic response = await ApiClient.patch(
//         '$_featurePath/$id/complete',
//       );
//       return Itinerary.fromJson(response);
//     } catch (e) {
//       debugPrint("Error completing itinerary: $e");
//       throw Exception("Failed to mark itinerary complete");
//     }
//   }

//   /// SHARE ITINERARY (make public)
//   static Future<Itinerary?> shareTrip(int id) async {
//     try {
//       final dynamic response = await ApiClient.patch('$_featurePath/$id/share');
//       return Itinerary.fromJson(response);
//     } catch (e) {
//       debugPrint("Error sharing itinerary: $e");
//       return null;
//     }
//   }

//   /// Make a public trip private
//   static Future<Itinerary?> unshareTrip(int id) async {
//     try {
//       final dynamic response = await ApiClient.patch(
//         '$_featurePath/$id/unshare',
//       );
//       return Itinerary.fromJson(response);
//     } catch (e) {
//       debugPrint("Error unsharing itinerary: $e");
//       return null;
//     }
//   }

//   /// TOGGLE VISITED STATUS
//   static Future<void> toggleItemVisited(
//     int itineraryId,
//     int itemId,
//     bool isVisited,
//   ) async {
//     try {
//       await ApiClient.patch(
//         '$_featurePath/$itineraryId/items/$itemId/toggle-visited',
//         query: {'visited': isVisited},
//       );
//     } catch (e) {
//       debugPrint("Error toggling visited: $e");
//       throw Exception("Failed to update visited status");
//     }
//   }

//   /// UPDATE SINGLE ITEM (e.g., notes or time)
//   static Future<void> updateItineraryItem(
//     int itineraryId,
//     int itemId,
//     Map<String, dynamic> data,
//   ) async {
//     try {
//       await ApiClient.put(
//         '$_featurePath/$itineraryId/items/$itemId',
//         body: data,
//       );
//     } catch (e) {
//       debugPrint("Error updating itinerary item: $e");
//       throw Exception("Failed to update itinerary item");
//     }
//   }

//   // Add a new activity
//   static Future<void> addActivity(
//     int itineraryId,
//     Map<String, dynamic> itemData,
//   ) async {
//     try {
//       await ApiClient.post('$_featurePath/$itineraryId/items', body: itemData);
//     } catch (e) {
//       debugPrint("Error adding activity: $e");
//       throw Exception("Failed to add activity");
//     }
//   }

//   /// Delete an activity
//   static Future<void> deleteActivity(int itineraryId, int itemId) async {
//     try {
//       await ApiClient.delete('$_featurePath/$itineraryId/items/$itemId');
//     } catch (e) {
//       debugPrint("Error deleting activity: $e");
//       throw Exception("Failed to delete activity");
//     }
//   }

//   /// Check if user can save this itinerary
//   static bool canSaveItinerary(Itinerary itinerary) {
//     // User cannot save their own itinerary
//     final currentUserId = ApiClient.currentUserId;
//     if (currentUserId == itinerary.userId) {
//       return false;
//     }

//     // User cannot save if already saved
//     if (itinerary.isSavedByCurrentUser == true) {
//       return false;
//     }

//     return true;
//   }

//   /// Check if user can like this itinerary
//   static bool canLikeItinerary(Itinerary itinerary) {
//     // User cannot like their own itinerary
//     final currentUserId = ApiClient.currentUserId;
//     if (currentUserId == itinerary.userId) {
//       return false;
//     }

//     return true;
//   }

//   static Future<Itinerary> savePublicPlan(int itineraryId) async {
//     try {
//       final response = await ApiClient.post(
//         '$_featurePath/$itineraryId/save',
//         body: {},
//       );
//       // Parse and return the itinerary
//       final itinerary = Itinerary.fromJson(response);
//       return itinerary;
//     } catch (e) {
//       throw Exception('Failed to save public plan: $e');
//     }
//   }

//   static Future<Itinerary> unsavePublicPlan(int itineraryId) async {
//     try {
//       final response = await ApiClient.delete(
//         '$_featurePath/$itineraryId/save',
//       );

//       // Parse and return the itinerary
//       final itinerary = Itinerary.fromJson(response);
//       return itinerary;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   static Future<Itinerary> toggleLike(int itineraryId) async {
//     try {
//       final response = await ApiClient.post(
//         '$_featurePath/$itineraryId/like/toggle',
//         body: {},
//       );

//       // Parse and return the itinerary
//       final itinerary = Itinerary.fromJson(response);

//       return itinerary;
//     } catch (e) {
//       throw Exception('Failed to toggle like: $e');
//     }
//   }

//   // Update the isItinerarySaved method:
//   static Future<bool> isItinerarySaved(int itineraryId) async {
//     try {
//       // Use the dedicated endpoint from your controller
//       final response = await ApiClient.get(
//         '/api/v1/itineraries/saved/check/$itineraryId',
//       );

//       // Response should be {"isSaved": true/false}
//       final isSaved = response['isSaved'] ?? false;

//       return isSaved;
//     } catch (e) {
//       return false;
//     }
//   }
// }
