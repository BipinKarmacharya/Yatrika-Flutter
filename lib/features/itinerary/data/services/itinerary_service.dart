import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:tour_guide/core/api/api_client.dart';
import '../models/itinerary.dart';

class ItineraryService {
  static const String _featurePath = '/api/v1/itineraries';

  /// Fetches Admin/Expert created itineraries
  static Future<List<Itinerary>> getExpertTemplates() async {
    try {
      // ApiClient.get already returns the decoded List<dynamic>
      final List<dynamic> data = await ApiClient.get(
        '$_featurePath/admin-templates',
      );

      return data.map((json) => Itinerary.fromJson(json)).toList();
    } catch (e) {
      // ApiClient throws ApiException if statusCode != 2xx,
      // so any error caught here is a legitimate failure.
      debugPrint("Error in getExpertTemplates: $e");
      throw Exception("Failed to load templates: $e");
    }
  }

  /// Fetches all available destinations
  static Future<List<dynamic>> getAllDestinations() async {
    try {
      // Adjust path to match your Spring Boot controller (e.g., /api/v1/destinations)
      final dynamic response = await ApiClient.get('/api/destinations');
      if (response is Map && response.containsKey('content')) {
        return response['content'] as List<dynamic>;
      }
      return response as List<dynamic>;
    } catch (e) {
      debugPrint("Error fetching all destinations: $e");
      return [];
    }
  }

  /// Fetches Public/Community trips with pagination/search
  static Future<List<Itinerary>> getCommunityTrips({
    String? search,
    String? theme,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (search != null && search.isNotEmpty) {
        queryParams['searchQuery'] = search;
      }
      if (theme != null && theme.isNotEmpty) queryParams['theme'] = theme;

      // Passing query map directly to ApiClient (it handles encoding)
      final dynamic responseData = await ApiClient.get(
        '$_featurePath/search',
        query: queryParams,
      );

      final List<dynamic> data = responseData['content'] ?? [];
      return data.map((json) => Itinerary.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error in getCommunityTrips: $e");
      throw Exception("Failed to load community trips: $e");
    }
  }

  /// Fetches itineraries for a specific destination
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

  static Future<Map<String, dynamic>> getItineraryDetails(int id) async {
    try {
      final dynamic response = await ApiClient.get('$_featurePath/$id');

      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error fetching itinerary details: $e");
      throw Exception("Failed to load itinerary details");
    }
  }

  /// COPY: Creates an independent copy of a template for the user
  static Future<Itinerary> copyItinerary(int id) async {
    try {
      final dynamic response = await ApiClient.post('$_featurePath/$id/copy');
      return Itinerary.fromJson(response);
    } catch (e) {
      debugPrint("Error copying itinerary: $e");
      throw Exception("Failed to copy trip: $e");
    }
  }

  /// PROGRESS: Mark an activity as visited/completed
  static Future<void> toggleItemVisited(
    int itineraryId,
    int itemId,
    bool isVisited,
  ) async {
    debugPrint(
      "📡 Calling: PATCH /itineraries/$itineraryId/items/$itemId/toggle-visited?visited=$isVisited",
    );

    try {
      // ✅ Use query parameter as shown in backend: @RequestParam Boolean visited
      await ApiClient.patch(
        '$_featurePath/$itineraryId/items/$itemId/toggle-visited',
        query: {'visited': isVisited}, // This becomes ?visited=true/false
      );

      debugPrint("✅ Visited status toggled to: $isVisited");
    } catch (e) {
      debugPrint("❌ Toggle failed: $e");
      throw Exception("Could not update visited status: $e");
    }
  }

  /// UPDATE: Update itinerary item details (e.g., notes, time)
  static Future<void> updateItineraryItem(
    int itineraryId,
    int itemId,
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint("Updating item: $itineraryId/$itemId");
      debugPrint("Data: $data");

      final response = await ApiClient.put(
        '$_featurePath/$itineraryId/items/$itemId',
        body: data,
      );

      debugPrint("Update response: $response");
    } catch (e) {
      debugPrint("Update error: $e");
      throw Exception("Could not update activity");
    }
  }

  /// FETCH PERSONAL: Get user's own independent plans
  static Future<List<Itinerary>> getMyPlans() async {
    try {
      final dynamic responseData = await ApiClient.get(
        '$_featurePath/my-plans',
      );
      final List<dynamic> data = responseData['content'] ?? [];
      return data.map((json) => Itinerary.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error fetching my plans: $e");
      throw Exception("Failed to load your trips");
    }
  }

  //Update personal itinerary details
  static Future<Itinerary> updateItinerary(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      // Calling PUT /api/v1/itineraries/{id}
      final dynamic response = await ApiClient.put(
        '$_featurePath/$id',
        body: data,
      );
      return Itinerary.fromJson(response);
    } catch (e) {
      debugPrint("Error updating itinerary: $e");
      throw Exception("Failed to update trip details");
    }
  }

  // Update full itinerary including items
  static Future<Itinerary> updateFullItinerary(
    int id,
    Map<String, dynamic> data,
  ) async {
    // This endpoint should handle syncing the child itinerary_items
    final dynamic response = await ApiClient.put(
      '$_featurePath/$id/full',
      body: data,
    );
    return Itinerary.fromJson(response);
  }

  // Delete trip
  static Future<void> deleteItinerary(int id) async {
    await ApiClient.delete('$_featurePath/$id');
  }

  // Test All APIs
  // Add this to itinerary_service.dart
  static Future<void> testAllApis(int itineraryId, int itemId) async {
    debugPrint("🧪 TESTING ALL APIS");

    // Test 1: Toggle visited
    try {
      await toggleItemVisited(itineraryId, itemId, true);
      debugPrint("✅ Test 1: toggle-visited PASSED");
    } catch (e) {
      debugPrint("❌ Test 1: toggle-visited FAILED: $e");
    }

    // Test 2: Update notes
    try {
      await updateItineraryItem(itineraryId, itemId, {
        'notes': 'Test note ${DateTime.now().toIso8601String()}',
      });
      debugPrint("✅ Test 2: update-item PASSED");
    } catch (e) {
      debugPrint("❌ Test 2: update-item FAILED: $e");
    }

    // Test 3: Get details (should always work)
    try {
      await getItineraryDetails(itineraryId);
      debugPrint("✅ Test 3: get-details PASSED");
    } catch (e) {
      debugPrint("❌ Test 3: get-details FAILED: $e");
    }
  }
}
