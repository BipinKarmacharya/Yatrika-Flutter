import 'package:flutter/foundation.dart';
import 'package:tour_guide/core/api/api_client.dart';
import '../models/itinerary.dart';

class ItineraryService {
  static const String _featurePath = '/api/v1/itineraries';

  /// CREATE: Create a brand new itinerary
  static Future<Itinerary?> createNewItinerary(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await ApiClient.post(_featurePath, body: data);
      return Itinerary.fromJson(response);
    } catch (e) {
      debugPrint("Create itinerary error: $e");
      return null;
    }
  }

  /// Fetch user's own plans with pagination
  static Future<List<Itinerary>> getMyPlans({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final dynamic responseData = await ApiClient.get(
        '$_featurePath/my-plans',
        query: {'page': page, 'size': size},
      );

      // Check the response structure
      if (responseData is Map) {
        // Handle paginated response
        final List<dynamic> data =
            responseData['content'] ?? responseData['data'] ?? [];
        return data.map((json) => Itinerary.fromJson(json)).toList();
      } else if (responseData is List) {
        // Handle list response directly
        return responseData.map((json) => Itinerary.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching my plans: $e");
      throw Exception("Failed to load your trips");
    }
  }

  /// FETCH PUBLIC: Get all public trips
  static Future<List<Itinerary>> getPublicTrips() async {
    try {
      final dynamic responseData = await ApiClient.get(
        '$_featurePath/community',
      );
      final List<dynamic> data = responseData['content'] ?? [];
      return data.map((json) => Itinerary.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error fetching public trips: $e");
      throw Exception("Failed to load public trips");
    }
  }

  /// FETCH TEMPLATES: Get admin/expert templates
  static Future<List<Itinerary>> getExpertTemplates() async {
    try {
      final List<dynamic> data = await ApiClient.get(
        '$_featurePath/admin-templates',
      );
      return data.map((json) => Itinerary.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error fetching expert templates: $e");
      throw Exception("Failed to load templates");
    }
  }

  /// FETCH BY DESTINATION
  static Future<List<Itinerary>> getItinerariesByDestination(
    int destinationId,
  ) async {
    try {
      final List<dynamic> data = await ApiClient.get(
        '$_featurePath/destination/$destinationId',
      );
      return data.map((json) => Itinerary.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error fetching itineraries for destination: $e");
      return [];
    }
  }

  /// FETCH ALL DESTINATIONS
  static Future<List<Map<String, dynamic>>> getAllDestinations() async {
    try {
      final dynamic response = await ApiClient.get('/api/destinations');
      if (response is Map && response.containsKey('content')) {
        return List<Map<String, dynamic>>.from(response['content']);
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching all destinations: $e");
      return [];
    }
  }

  /// FETCH DETAILS
  static Future<Map<String, dynamic>> getItineraryDetails(int id) async {
    try {
      final dynamic response = await ApiClient.get('$_featurePath/$id');
      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error fetching itinerary details: $e");
      throw Exception("Failed to load itinerary details");
    }
  }

  /// COPY ITINERARY
  static Future<Itinerary> copyItinerary(int id) async {
    try {
      final dynamic response = await ApiClient.post('$_featurePath/$id/copy');
      return Itinerary.fromJson(response);
    } catch (e) {
      debugPrint("Error copying itinerary: $e");
      throw Exception("Failed to copy itinerary");
    }
  }

  /// UPDATE HEADERS (title + description)
  static Future<Itinerary> updateItinerary(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final dynamic response = await ApiClient.patch(
        '$_featurePath/$id',
        body: data,
      );
      return Itinerary.fromJson(response);
    } catch (e) {
      debugPrint("Error updating itinerary: $e");
      throw Exception("Failed to update itinerary");
    }
  }

  /// UPDATE FULL ITINERARY (headers + items)
  static Future<Itinerary> updateFullItinerary(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      // Backend expects ItineraryRequest format
      final Map<String, dynamic> requestData = {
        'title': data['title'] ?? '',
        'description': data['description'] ?? '',
        'items': data['items'] ?? [],
      };

      final dynamic response = await ApiClient.put(
        '$_featurePath/$id/full',
        body: requestData,
      );
      return Itinerary.fromJson(response);
    } catch (e) {
      debugPrint("Error updating full itinerary: $e");
      throw Exception("Failed to update full itinerary");
    }
  }

  /// DELETE ITINERARY
  static Future<void> deleteItinerary(int id) async {
    await ApiClient.delete('$_featurePath/$id');
  }

  /// MARK COMPLETE
  static Future<Itinerary> markAsComplete(int id) async {
    try {
      final dynamic response = await ApiClient.patch(
        '$_featurePath/$id/complete',
      );
      return Itinerary.fromJson(response);
    } catch (e) {
      debugPrint("Error completing itinerary: $e");
      throw Exception("Failed to mark itinerary complete");
    }
  }

  /// SHARE ITINERARY (make public)
  static Future<Itinerary?> shareTrip(int id) async {
    try {
      final dynamic response = await ApiClient.patch('$_featurePath/$id/share');
      return Itinerary.fromJson(response);
    } catch (e) {
      debugPrint("Error sharing itinerary: $e");
      return null;
    }
  }

  /// Make a public trip private
  static Future<Itinerary?> unshareTrip(int id) async {
    try {
      final dynamic response = await ApiClient.patch(
        '$_featurePath/$id/unshare',
      );
      return Itinerary.fromJson(response);
    } catch (e) {
      debugPrint("Error unsharing itinerary: $e");
      return null;
    }
  }

  /// TOGGLE VISITED STATUS
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

  /// UPDATE SINGLE ITEM (e.g., notes or time)
  static Future<void> updateItineraryItem(
    int itineraryId,
    int itemId,
    Map<String, dynamic> data,
  ) async {
    try {
      await ApiClient.put(
        '$_featurePath/$itineraryId/items/$itemId',
        body: data,
      );
    } catch (e) {
      debugPrint("Error updating itinerary item: $e");
      throw Exception("Failed to update itinerary item");
    }
  }

  // Add a new activity
  static Future<void> addActivity(
    int itineraryId,
    Map<String, dynamic> itemData,
  ) async {
    try {
      await ApiClient.post('$_featurePath/$itineraryId/items', body: itemData);
    } catch (e) {
      debugPrint("Error adding activity: $e");
      throw Exception("Failed to add activity");
    }
  }

  /// Delete an activity
  static Future<void> deleteActivity(int itineraryId, int itemId) async {
    try {
      await ApiClient.delete('$_featurePath/$itineraryId/items/$itemId');
    } catch (e) {
      debugPrint("Error deleting activity: $e");
      throw Exception("Failed to delete activity");
    }
  }

  // Saving Public Trips
  static Future<void> savePublicPlan(int itineraryId) async {
    try {
      await ApiClient.post('$_featurePath/$itineraryId/save', body: {});
    } catch (e) {
      debugPrint("Error saving public plan: $e");
      throw Exception('Failed to save public plan: $e');
    }
  }

  static Future<void> unsavePublicPlan(int itineraryId) async {
    try {
      await ApiClient.delete('$_featurePath/$itineraryId/save');
    } catch (e) {
      debugPrint("Error unsaving public plan: $e");
      throw Exception('Failed to unsave public plan: $e');
    }
  }

  // like/unlike trips
  static Future<void> toggleLike(int itineraryId) async {
    try {
      await ApiClient.post('$_featurePath/$itineraryId/like/toggle', body: {});
    } catch (e) {
      debugPrint("Error toggling like: $e");
      throw Exception('Failed to toggle like');
    }
  }
}




// import 'package:flutter/foundation.dart'; // For debugPrint
// import 'package:tour_guide/core/api/api_client.dart';
// import '../models/itinerary.dart';

// class ItineraryService {
//   static const String _featurePath = '/api/v1/itineraries';

//   /// CREATE: Create a brand new blank trip
//   static Future<Itinerary?> createNewItinerary(
//     Map<String, dynamic> data,
//   ) async {
//     try {
//       // Use ApiClient (capital A) and 'body' parameter
//       final response = await ApiClient.post(_featurePath, body: data);
//       return Itinerary.fromJson(response);
//     } catch (e) {
//       debugPrint("Create itinerary error: $e");
//       return null;
//     }
//   }

//   /// Fetches Admin/Expert created itineraries
//   static Future<List<Itinerary>> getExpertTemplates() async {
//     try {
//       // ApiClient.get already returns the decoded List<dynamic>
//       final List<dynamic> data = await ApiClient.get(
//         '$_featurePath/admin-templates',
//       );

//       return data.map((json) => Itinerary.fromJson(json)).toList();
//     } catch (e) {
//       // ApiClient throws ApiException if statusCode != 2xx,
//       // so any error caught here is a legitimate failure.
//       debugPrint("Error in getExpertTemplates: $e");
//       throw Exception("Failed to load templates: $e");
//     }
//   }

//   /// Fetches all available destinations
//   static Future<List<dynamic>> getAllDestinations() async {
//     try {
//       // Adjust path to match your Spring Boot controller (e.g., /api/v1/destinations)
//       final dynamic response = await ApiClient.get('/api/destinations');
//       if (response is Map && response.containsKey('content')) {
//         return response['content'] as List<dynamic>;
//       }
//       return response as List<dynamic>;
//     } catch (e) {
//       debugPrint("Error fetching all destinations: $e");
//       return [];
//     }
//   }

//   /// Fetches Public/Community trips with pagination/search
//   static Future<List<Itinerary>> getCommunityTrips({
//     String? search,
//     String? theme,
//   }) async {
//     try {
//       final Map<String, dynamic> queryParams = {};
//       if (search != null && search.isNotEmpty) {
//         queryParams['searchQuery'] = search;
//       }
//       if (theme != null && theme.isNotEmpty) queryParams['theme'] = theme;

//       // Passing query map directly to ApiClient (it handles encoding)
//       final dynamic responseData = await ApiClient.get(
//         '$_featurePath/search',
//         query: queryParams,
//       );

//       final List<dynamic> data = responseData['content'] ?? [];
//       return data.map((json) => Itinerary.fromJson(json)).toList();
//     } catch (e) {
//       debugPrint("Error in getCommunityTrips: $e");
//       throw Exception("Failed to load community trips: $e");
//     }
//   }

//   /// Fetches itineraries for a specific destination
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

//   static Future<Map<String, dynamic>> getItineraryDetails(int id) async {
//     try {
//       final dynamic response = await ApiClient.get('$_featurePath/$id');

//       return response as Map<String, dynamic>;
//     } catch (e) {
//       debugPrint("Error fetching itinerary details: $e");
//       throw Exception("Failed to load itinerary details");
//     }
//   }

//   /// COPY: Creates an independent copy of a template for the user
//   static Future<Itinerary> copyItinerary(int id) async {
//     try {
//       final dynamic response = await ApiClient.post('$_featurePath/$id/copy');
//       return Itinerary.fromJson(response);
//     } catch (e) {
//       debugPrint("Error copying itinerary: $e");
//       throw Exception("Failed to copy trip: $e");
//     }
//   }

//   /// PROGRESS: Mark an activity as visited/completed
//   static Future<void> toggleItemVisited(
//     int itineraryId,
//     int itemId,
//     bool isVisited,
//   ) async {
//     debugPrint(
//       "📡 Calling: PATCH /itineraries/$itineraryId/items/$itemId/toggle-visited?visited=$isVisited",
//     );

//     try {
//       // ✅ Use query parameter as shown in backend: @RequestParam Boolean visited
//       await ApiClient.patch(
//         '$_featurePath/$itineraryId/items/$itemId/toggle-visited',
//         query: {'visited': isVisited}, // This becomes ?visited=true/false
//       );

//       debugPrint("✅ Visited status toggled to: $isVisited");
//     } catch (e) {
//       debugPrint("❌ Toggle failed: $e");
//       throw Exception("Could not update visited status: $e");
//     }
//   }

//   /// UPDATE: Update itinerary item details (e.g., notes, time)
//   static Future<void> updateItineraryItem(
//     int itineraryId,
//     int itemId,
//     Map<String, dynamic> data,
//   ) async {
//     try {
//       debugPrint("Updating item: $itineraryId/$itemId");
//       debugPrint("Data: $data");

//       final response = await ApiClient.put(
//         '$_featurePath/$itineraryId/items/$itemId',
//         body: data,
//       );

//       debugPrint("Update response: $response");
//     } catch (e) {
//       debugPrint("Update error: $e");
//       throw Exception("Could not update activity");
//     }
//   }

//   /// FETCH PERSONAL: Get user's own independent plans
//   static Future<List<Itinerary>> getMyPlans() async {
//     try {
//       final dynamic responseData = await ApiClient.get(
//         '$_featurePath/my-plans',
//       );
//       final List<dynamic> data = responseData['content'] ?? [];
//       return data.map((json) => Itinerary.fromJson(json)).toList();
//     } catch (e) {
//       debugPrint("Error fetching my plans: $e");
//       throw Exception("Failed to load your trips");
//     }
//   }

//   //Update personal itinerary details
//   static Future<Itinerary> updateItinerary(
//     int id,
//     Map<String, dynamic> data,
//   ) async {
//     try {
//       // Calling PUT /api/v1/itineraries/{id}
//       final dynamic response = await ApiClient.put(
//         '$_featurePath/$id',
//         body: data,
//       );
//       return Itinerary.fromJson(response);
//     } catch (e) {
//       debugPrint("Error updating itinerary: $e");
//       throw Exception("Failed to update trip details");
//     }
//   }

//   // Update full itinerary including items
//   static Future<Itinerary> updateFullItinerary(
//     int id,
//     Map<String, dynamic> data,
//   ) async {
//     // This endpoint should handle syncing the child itinerary_items
//     final dynamic response = await ApiClient.put(
//       '$_featurePath/$id/full',
//       body: data,
//     );
//     return Itinerary.fromJson(response);
//   }

//   // Delete trip
//   static Future<void> deleteItinerary(int id) async {
//     await ApiClient.delete('$_featurePath/$id');
//   }

//   // Mark as completed
//   static Future<Itinerary> markAsComplete(int id) async {
//     try {
//       // Hits @PatchMapping("/{id}/complete")
//       final dynamic response = await ApiClient.patch(
//         '$_featurePath/$id/complete',
//       );
//       return Itinerary.fromJson(response);
//     } catch (e) {
//       debugPrint("Error completing itinerary: $e");
//       throw Exception("Failed to mark trip as finished");
//     }
//   }

//   /// SHARE: Make a private trip public for the community
//   static Future<Itinerary?> shareTrip(int id) async {
//     try {
//       // Calls PATCH /api/v1/itineraries/{id}/share
//       final dynamic response = await ApiClient.patch('$_featurePath/$id/share');
//       return Itinerary.fromJson(response);
//     } catch (e) {
//       debugPrint("Error sharing itinerary: $e");
//       return null;
//     }
//   }

//   /// Get all public trips
//   /// Get all public trips (Used by Tab 3)
//   static Future<List<Itinerary>> getPublicTrips() async {
//     try {
//       // Use your actual ApiClient and the correct endpoint from your Java Controller
//       final dynamic responseData = await ApiClient.get('$_featurePath/community');

//       // Since Java returns Page<ItineraryResponse>, we extract the 'content' list
//       final List<dynamic> data = responseData['content'] ?? [];
//       return data.map((json) => Itinerary.fromJson(json)).toList();
//     } catch (e) {
//       debugPrint("Error in getPublicTrips: $e");
//       throw Exception("Failed to load community trips: $e");
//     }
//   }

  

//   // Test All APIs
//   // Add this to itinerary_service.dart
//   static Future<void> testAllApis(int itineraryId, int itemId) async {
//     debugPrint("🧪 TESTING ALL APIS");

//     // Test 1: Toggle visited
//     try {
//       await toggleItemVisited(itineraryId, itemId, true);
//       debugPrint("✅ Test 1: toggle-visited PASSED");
//     } catch (e) {
//       debugPrint("❌ Test 1: toggle-visited FAILED: $e");
//     }

//     // Test 2: Update notes
//     try {
//       await updateItineraryItem(itineraryId, itemId, {
//         'notes': 'Test note ${DateTime.now().toIso8601String()}',
//       });
//       debugPrint("✅ Test 2: update-item PASSED");
//     } catch (e) {
//       debugPrint("❌ Test 2: update-item FAILED: $e");
//     }

//     // Test 3: Get details (should always work)
//     try {
//       await getItineraryDetails(itineraryId);
//       debugPrint("✅ Test 3: get-details PASSED");
//     } catch (e) {
//       debugPrint("❌ Test 3: get-details FAILED: $e");
//     }
//   }
// }
