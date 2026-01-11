// import '../../../core/api/api_client.dart';
// import 'itinerary.dart';

// class ItineraryService {
//   static Future<Itinerary> getById(String id) async {
//     final data = await ApiClient.get('/api/itineraries/$id');
//     return Itinerary.fromJson(data as Map<String, dynamic>);
//   }

//   static Future<Itinerary> create(Map<String, dynamic> body) async {
//     final data = await ApiClient.post('/api/itineraries', body: body);
//     return Itinerary.fromJson(data as Map<String, dynamic>);
//   }

//   static Future<void> delete(String id) async {
//     await ApiClient.delete('/api/itineraries/$id');
//   }

//   static Future<Itinerary> update(String id, Map<String, dynamic> body) async {
//     final data = await ApiClient.put('/api/itineraries/$id', body: body);
//     return Itinerary.fromJson(data as Map<String, dynamic>);
//   }

//   static Future<void> addItem(String id, Map<String, dynamic> body) async {
//     await ApiClient.post('/api/itineraries/$id/items', body: body);
//   }

//   static Future<void> changeStatus(String id, String status) async {
//     await ApiClient.patch('/api/itineraries/$id/status/$status');
//   }

//   static Future<Itinerary> duplicate(String id) async {
//     final data = await ApiClient.get('/api/itineraries/$id/duplicate');
//     return Itinerary.fromJson(data as Map<String, dynamic>);
//   }

//   static Future<List<Itinerary>> publicList() async {
//     final data = await ApiClient.get('/api/itineraries/public');
//     return (data as List)
//         .map((e) => Itinerary.fromJson(e as Map<String, dynamic>))
//         .toList();
//   }

//   static Future<List<Itinerary>> myItineraries() async {
//     final data = await ApiClient.get('/api/itineraries/my');
//     return (data as List)
//         .map((e) => Itinerary.fromJson(e as Map<String, dynamic>))
//         .toList();
//   }
// }
