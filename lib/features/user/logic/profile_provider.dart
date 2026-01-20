import 'package:flutter/material.dart';
import '../data/models/user_stats.dart';

class ProfileProvider extends ChangeNotifier {
  final UserStats _stats = UserStats.mock();
  UserStats get stats => _stats;

  bool tripReminders = true;
  bool newFollowers = true;
  bool recommendations = true;
  bool weeklyDigest = true;

  void toggleNotification(String type, bool value) {
    switch (type) {
      case 'reminders': tripReminders = value; break;
      case 'followers': newFollowers = value; break;
      case 'recommendations': recommendations = value; break;
      case 'digest': weeklyDigest = value; break;
    }
    notifyListeners();
  }

  Future<void> deleteAllTrips() async {
    // API call logic here
    notifyListeners();
  }
}