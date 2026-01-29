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
    bool visited,
  ) async {
    try {
      await ApiClient.patch(
        '$_featurePath/$itineraryId/items/$itemId/toggle-visited',
        query: {'visited': visited.toString()},
      );
    } catch (e) {
      debugPrint("Error toggling visited status: $e");
      throw Exception("Failed to update activity status");
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

  static Future<void> updateItineraryItem(int itineraryId, int itemId, Map<String, dynamic> data) async {
  // Change 'data: data' to 'body: data'
  await ApiClient.patch(
    '$_featurePath/$itineraryId/items/$itemId', 
    body: data, 
  );
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
}
