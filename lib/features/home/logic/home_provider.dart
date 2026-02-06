import 'package:flutter/material.dart';
import '../../destination/data/models/destination.dart' as MD;
import '../../destination/data/services/destination_service.dart';
import '../../community/data/models/community_post.dart' as CP;
import '../../community/data/services/community_service.dart';

class HomeProvider with ChangeNotifier {
  List<MD.Destination> featured = [];
  List<MD.Destination> recommended = [];
  List<CP.CommunityPost> communityPosts = [];
  bool isLoading = true;
  String? error;

  Future<void> loadHomeData() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        DestinationService.popular(),
        DestinationService.getRecommendations(),
        CommunityService.trending(),
      ]);
      featured = results[0] as List<MD.Destination>;
      recommended = results[1] as List<MD.Destination>;
      communityPosts = results[2] as List<CP.CommunityPost>;
    } catch (e) {
      error = "Connection issues. Please try again.";
      debugPrint("Home Data Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}