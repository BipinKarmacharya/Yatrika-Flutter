import 'package:tour_guide/core/api/api_client.dart';
import 'package:tour_guide/features/interest/data/models/interest.dart';

class InterestService {
  static Future<List<Interest>> getAll() async {
    final response = await ApiClient.get('/api/v1/interests');
    return (response as List)
        .map((e) => Interest.fromJson(e))
        .toList();
  }
}
