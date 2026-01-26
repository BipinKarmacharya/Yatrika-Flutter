import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';
import '../models/destination.dart'; // Updated import

class DestinationService {
  /// Helper to extract data from the ApiClient response and handle Pagination
  static List<Destination> _mapResponse(dynamic response) {
    if (response == null) return [];

    List<dynamic> list = [];

    // 1. Extract the list from various possible Spring Boot structures
    if (response is Map<String, dynamic>) {
      if (response.containsKey('content')) {
        // This is a Spring Data Page object (Common in paged lists)
        list = response['content'];
      } else if (response.containsKey('data')) {
        // This is your custom wrapper (if you use one)
        final dataField = response['data'];
        if (dataField is List) {
          list = dataField;
        } else if (dataField is Map && dataField.containsKey('content')) {
          list = dataField['content'];
        }
      }
    } else if (response is List) {
      // This is a direct list (Common in 'popular' or 'top' endpoints)
      list = response;
    }

    // 2. Map to objects
    try {
      return list
          .map((e) => Destination.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("MAPPING ERROR: $e");
      return [];
    }
  }

  static Future<List<Destination>> getRecommendations() async {
    try {
      final response = await ApiClient.get('/api/destinations/recommendations');
      
      // Using your existing _mapResponse helper to handle pagination/mapping
      return _mapResponse(response is Map ? response : response.data);
    } catch (e) {
      debugPrint("Error fetching recommendations: $e");
      // Fallback to popular if recommendations fail or user is guest
      return popular(); 
    }
  }

  static Future<List<Destination>> getFiltered({
    String? search,
    List<String>? tags,
    String? budget,
    String? sort,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};

      if (search != null && search.isNotEmpty) {
        queryParams['name'] = search; // Matches DestinationSearchRequest
      }

      if (tags != null && tags.isNotEmpty) {
        // Most Spring Boot @ModelAttribute setups prefer repeating the key: tags=A&tags=B
        queryParams['tags'] = tags;
      }

      // Budget Mapping
      if (budget != "Any budget") {
        if (budget == "Under \$100") {
          queryParams['maxPrice'] = 100;
        } else if (budget == "\$100 - \$200") {
          queryParams['minPrice'] = 100;
          queryParams['maxPrice'] = 200;
        } else if (budget == "Over \$200") {
          queryParams['minPrice'] = 200;
        }
      }

      final response = await ApiClient.get(
        '/api/destinations/search',
        query: queryParams,
      );

      // IMPORTANT: If ApiClient returns a Dio Response object, pass response.data
      return _mapResponse(response is Map ? response : response.data);
    } catch (e) {
      debugPrint("Error in getFiltered: $e");
      return [];
    }
  }

  static Future<List<Destination>> popular() async {
    try {
      final response = await ApiClient.get('/api/destinations');
      return _mapResponse(response); // Uses the refined helper
    } catch (e) {
      debugPrint("Error in DestinationService.popular: $e");
      return [];
    }
  }

  static Future<Destination> getById(String id) async {
    try {
      final response = await ApiClient.get('/api/destinations/$id');
      return Destination.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint("Error in DestinationService.getById: $e");
      rethrow;
    }
  }

  static Future<List<Destination>> getAll({int page = 0, int size = 20}) async {
    final response = await ApiClient.get(
      '/api/destinations',
      query: {'page': page, 'size': size},
    );
    return _mapResponse(response);
  }

  static Future<List<Destination>> search(String name) async {
    final response = await ApiClient.get(
      '/api/destinations/search',
      query: {'name': name},
    );
    return _mapResponse(response);
  }

  static Future<List<Destination>> nearby({
    required double lat,
    required double lng,
  }) async {
    final response = await ApiClient.get(
      '/api/destinations/nearby',
      query: {'lat': lat, 'lng': lng},
    );
    return _mapResponse(response);
  }

  static Future<List<Destination>> byDistrict(String district) async {
    final response = await ApiClient.get(
      '/api/destinations/district/$district',
    );
    return _mapResponse(response);
  }

  static Future<Destination> create(Map<String, dynamic> body) async {
    final response = await ApiClient.post('/api/destinations', body: body);
    return Destination.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<void> delete(String id) async {
    await ApiClient.delete('/api/destinations/$id');
  }
}
