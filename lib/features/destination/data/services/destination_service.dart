// import 'package:flutter/foundation.dart';
// import '../../../../core/api/api_client.dart';
// import '../destination.dart';

// class DestinationService {
//   /// Helper to extract data from the ApiClient response and handle Pagination
//   static List<Destination> _mapResponse(dynamic response) {
//     // DEBUG: Check what the ApiClient is actually giving us
//     debugPrint("API Response Type: ${response.runtimeType}");

//     // If response is the custom ApiClient wrapper, get the data.
//     // If response is already the Map/List from Dio, use it directly.
//     final dynamic data = (response is Map) ? response : response.data;

//     if (data == null) {
//       debugPrint("DestinationService: Data is null");
//       return [];
//     }

//     List<dynamic> list = [];

//     // 1. Handle Spring Boot PageImpl (The 'content' key)
//     if (data is Map<String, dynamic> && data.containsKey('content')) {
//       list = data['content'];
//     }
//     // 2. Handle direct List structure
//     else if (data is List) {
//       list = data;
//     }
//     // 3. Fallback: maybe 'data' is the list inside a wrapper
//     else if (data is Map<String, dynamic> && data.containsKey('data')) {
//       list = data['data'];
//     }

//     debugPrint("DestinationService: Found ${list.length} items");

//     return list
//         .map((e) => Destination.fromJson(e as Map<String, dynamic>))
//         .toList();
//   }

//   static Future<List<Destination>> popular() async {
//     try {
//       final response = await ApiClient.get('/api/destinations');
//       return _mapResponse(response); // Uses the refined helper
//     } catch (e) {
//       debugPrint("Error in DestinationService.popular: $e");
//       return [];
//     }
//   }

//   static Future<Destination> getById(String id) async {
//     try {
//       final response = await ApiClient.get('/api/destinations/$id');
//       return Destination.fromJson(response.data as Map<String, dynamic>);
//     } catch (e) {
//       debugPrint("Error in DestinationService.getById: $e");
//       rethrow;
//     }
//   }

//   static Future<List<Destination>> getAll({int page = 0, int size = 20}) async {
//     final response = await ApiClient.get(
//       '/api/destinations',
//       query: {'page': page, 'size': size},
//     );
//     return _mapResponse(response);
//   }

//   static Future<List<Destination>> search(String name) async {
//     final response = await ApiClient.get(
//       '/api/destinations/search',
//       query: {'name': name},
//     );
//     return _mapResponse(response);
//   }

//   static Future<List<Destination>> nearby({
//     required double lat,
//     required double lng,
//   }) async {
//     final response = await ApiClient.get(
//       '/api/destinations/nearby',
//       query: {'lat': lat, 'lng': lng},
//     );
//     return _mapResponse(response);
//   }

//   static Future<List<Destination>> byDistrict(String district) async {
//     final response = await ApiClient.get(
//       '/api/destinations/district/$district',
//     );
//     return _mapResponse(response);
//   }

//   static Future<Destination> create(Map<String, dynamic> body) async {
//     final response = await ApiClient.post('/api/destinations', body: body);
//     return Destination.fromJson(response.data as Map<String, dynamic>);
//   }

//   static Future<void> delete(String id) async {
//     await ApiClient.delete('/api/destinations/$id');
//   }
// }


// lib/features/destination/data/services/destination_service.dart
import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';
import '../models/destination.dart';  // Updated import

class DestinationService {
  /// Helper to extract data from the ApiClient response and handle Pagination
  static List<Destination> _mapResponse(dynamic response) {
    // DEBUG: Check what the ApiClient is actually giving us
    debugPrint("API Response Type: ${response.runtimeType}");

    // If response is the custom ApiClient wrapper, get the data.
    // If response is already the Map/List from Dio, use it directly.
    final dynamic data = (response is Map) ? response : response.data;

    if (data == null) {
      debugPrint("DestinationService: Data is null");
      return [];
    }

    List<dynamic> list = [];

    // 1. Handle Spring Boot PageImpl (The 'content' key)
    if (data is Map<String, dynamic> && data.containsKey('content')) {
      list = data['content'];
    }
    // 2. Handle direct List structure
    else if (data is List) {
      list = data;
    }
    // 3. Fallback: maybe 'data' is the list inside a wrapper
    else if (data is Map<String, dynamic> && data.containsKey('data')) {
      list = data['data'];
    }

    debugPrint("DestinationService: Found ${list.length} items");

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