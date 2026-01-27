// import 'package:flutter/foundation.dart';
// import '../../../../core/api/api_client.dart';
// import '../models/trip.dart';

// class TripService {
//   /// Maps the raw API response to a List of Trip objects
//   static List<Trip> _mapResponse(dynamic response) {
//     if (response == null) return [];
    
//     List<dynamic> list = [];

//     // Handling different common Spring Boot response wrappers
//     if (response is Map<String, dynamic>) {
//       list = response['content'] ?? response['data'] ?? [];
//     } else if (response is List) {
//       list = response;
//     }

//     return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
//   }

//   /// Fetches public trips from the backend with an optional search query
//   static Future<List<Trip>> getPublicTrips({String? search}) async {
//     try {
//       final response = await ApiClient.get(
//         '/api/public-trips', // Ensure this matches your Spring Boot @RequestMapping
//         query: {
//           if (search != null && search.isNotEmpty) 'search': search,
//         },
//       );
      
//       return _mapResponse(response);
//     } catch (e) {
//       debugPrint("Error in TripService.getPublicTrips: $e");
//       return [];
//     }
//   }
// }