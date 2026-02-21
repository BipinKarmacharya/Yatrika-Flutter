import 'package:tour_guide/core/api/api_client.dart';
import 'package:tour_guide/features/plan/data/model/ml_models.dart';

class MLService {
  static Future<MLPredictResponse> getPrediction({
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

    if (response is Map<String, dynamic>) {
      return MLPredictResponse.fromJson(response);
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
    required DateTime startDate,
  }) async {
    return await ApiClient.post(
      '/api/v1/ml/save',
      body: {
        "city": city,
        "budget": budget,
        "interests": interests,
        "days": days,
        "startDate": startDate.toIso8601String().split('T')[0], // yyyy-MM-dd
        "itineraryData": itineraryData,
      },
    );
  }
}
