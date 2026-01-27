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

  /// Fetches Public/Community trips with pagination/search
  static Future<List<Itinerary>> getCommunityTrips({
    String? search,
    String? theme,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (search != null && search.isNotEmpty)
        queryParams['searchQuery'] = search;
      if (theme != null && theme.isNotEmpty) queryParams['theme'] = theme;

      // Passing query map directly to ApiClient (it handles encoding)
      final dynamic responseData = await ApiClient.get(
        '$_featurePath/search',
        query: queryParams,
      );

      // Spring Boot 'Page' objects wrap data in a 'content' field
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
      // This now matches the new endpoint: GET /api/v1/itineraries/1
      final dynamic response = await ApiClient.get('$_featurePath/$id');

      // ApiClient already decoded this into a Map<String, dynamic>
      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error fetching itinerary details: $e");
      throw Exception("Failed to load itinerary details");
    }
  }
}
