import 'package:tour_guide/core/api/api_client.dart';

class MLService {
  /// Calls FastAPI through Spring Boot to get the itinerary preview
  static Future<Map<String, List<String>>> getPrediction({
    required String city,
    required String budget,
    required List<String> interests,
    required int days,
  }) async {
    final response = await ApiClient.post(
      '/api/v1/ml/predict',
      body: {
        "city": city,
        "budget": budget,
        "interests": interests,
        "days": days,
      },
    );

    // Casting the dynamic response to the required Map structure
    if (response is Map) {
      return response.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      );
    }
    throw Exception("Invalid response format");
  }

  /// Saves the generated plan to the user's permanent itineraries
  static Future<dynamic> savePlan({
    required String city,
    required String budget,
    required List<String> interests,
    required int days,
    required Map<String, List<String>> itineraryData,
  }) async {
    return await ApiClient.post(
      '/api/v1/ml/save',
      body: {
        "metadata": {
          "city": city,
          "budget": budget,
          "interests": interests,
          "days": days,
        },
        "itineraryData": itineraryData,
      },
    );
  }
}