import 'package:flutter/material.dart';
import 'package:tour_guide/core/api/api_client.dart';
import '../data/models/user_stats.dart';

class ProfileProvider extends ChangeNotifier {
  final UserStats _stats = UserStats.mock();
  UserStats get stats => _stats;

  bool tripReminders = true;
  bool newFollowers = true;
  bool recommendations = true;
  bool weeklyDigest = true;

  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  void toggleNotification(String type, bool value) {
    switch (type) {
      case 'reminders':
        tripReminders = value;
        break;
      case 'followers':
        newFollowers = value;
        break;
      case 'recommendations':
        recommendations = value;
        break;
      case 'digest':
        weeklyDigest = value;
        break;
    }
    notifyListeners();
  }

  Future<bool> deleteAllTrips() async {
    _isDeleting = true;
    notifyListeners();

    try {
      await ApiClient.delete('/api/v1/itineraries/my-plans/all');

      return true;
    } catch (e) {
      debugPrint("Error deleting trips: $e");
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
}
