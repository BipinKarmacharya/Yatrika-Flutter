import 'package:tour_guide/core/api/api_client.dart';
import 'package:tour_guide/features/destination/data/models/review_model.dart';

class ReviewService {
  static Future<List<Review>> getReviewsByDestination(String destId) async {
    try {
      final response = await ApiClient.get(
        '/api/reviews/destination/$destId?page=0&size=10',
      );

      // Check if the response is successful and contains the 'content' key
      if (response != null && response['content'] != null) {
        final List<dynamic> list = response['content'];
        return list.map((json) => Review.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching reviews: $e");
      return [];
    }
  }

  static Future<bool> postReview({
    required int destinationId,
    required double rating,
    required String comment,
    required String visitedDate,
  }) async {
    try {
      final response = await ApiClient.post(
        '/api/reviews',
        body: {
          "destinationId": destinationId,
          "rating": rating,
          "comment": comment,
          "visitedDate": visitedDate,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
