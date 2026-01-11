import 'package:flutter/material.dart';
import 'package:tour_guide/features/community/presentation/widgets/community_post_feed_card.dart';

class AppRoutes {
  static const String home = '/home';
  static const String discover = '/discover';
  static const String plan = '/plan';
  static const String planAi = '/plan/ai';
  static const String planItinerary = '/plan/itinerary';
  static const String posts = '/posts';
  static const String profile = '/profile';
  static const String destinations = '/destinations';
  static const String packages = '/packages';
  static const String packageDetail = '/packages/detail';
  static const String login = '/login';
  static const String register = '/register';
  static const String communityPost = '/community/post';
}

class LoginScreenArgs {
  const LoginScreenArgs({this.onLoginSuccess, this.onGuestContinue});

  final VoidCallback? onLoginSuccess;
  final VoidCallback? onGuestContinue;
}

class RegisterScreenArgs {
  const RegisterScreenArgs({this.onRegisterSuccess});

  final VoidCallback? onRegisterSuccess;
}

class PackageDetailsArgs {
  const PackageDetailsArgs({
    required this.packageTitle,
    required this.packagePrice,
    required this.isLoggedIn,
    this.itineraryId,
  });

  final String packageTitle;
  final int packagePrice;
  final bool isLoggedIn;
  final String? itineraryId;
}

class CommunityPostDetailArgs {
  const CommunityPostDetailArgs({required this.feed});

  final CommunityPostFeedCard feed;
}