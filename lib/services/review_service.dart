import '../core/api/api_client.dart';
import '../features/destination/data/review.dart';

class ReviewService {
  static Future<Review> getById(String id) async {
    final data = await ApiClient.get('/api/reviews/$id');
    return Review.fromJson(data as Map<String, dynamic>);
  }

  static Future<Review> create(Review review) async {
    final data = await ApiClient.post('/api/reviews', body: review.toJson());
    return Review.fromJson(data as Map<String, dynamic>);
  }

  static Future<Review> update(String id, Review review) async {
    final data = await ApiClient.put('/api/reviews/$id', body: review.toJson());
    return Review.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> delete(String id) async {
    await ApiClient.delete('/api/reviews/$id');
  }

  static Future<List<Review>> getMyReviews() async {
    final data = await ApiClient.get('/api/reviews/my');
    return (data as List)
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Review>> forDestination(String destinationId) async {
    final data = await ApiClient.get('/api/reviews/destination/$destinationId');
    return (data as List)
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
