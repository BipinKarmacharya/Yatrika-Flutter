import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';
import '../models/destination.dart'; // Updated import

class DestinationService {

  /// Helper to extract data from the ApiClient response and handle Pagination
  static List<Destination> _mapResponse(dynamic response) {
    // 1. Safety check
    if (response == null) return [];

    List<dynamic> list = [];

    // 2. Extract the list based on Spring Boot's response structure
    if (response is Map<String, dynamic>) {
      if (response.containsKey('content')) {
        list = response['content']; // Standard Spring Pageable
      } else if (response.containsKey('data')) {
        list = response['data']; // Generic wrapper
      }
    } else if (response is List) {
      list = response; // Direct list
    }

    // 3. Map to objects (The Model handles the Image URL logic now!)
    return list
        .map((e) => Destination.fromJson(e as Map<String, dynamic>))
        .toList();
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
