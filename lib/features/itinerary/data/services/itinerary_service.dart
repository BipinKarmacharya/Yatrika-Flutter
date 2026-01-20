import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/itinerary_model.dart';

class ItineraryService {
  final String baseUrl = "http://localhost:8080/api/public/itineraries";

  Future<List<ItineraryResponse>> getItinerariesByDestination(int destId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/destination/$destId'),
        headers: {"ngrok-skip-browser-warning": "true"},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => ItineraryResponse.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load itineraries");
      }
    } catch (e) {
      print("Error fetching itineraries: $e");
      return [];
    }
  }
}