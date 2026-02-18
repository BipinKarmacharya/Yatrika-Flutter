import 'package:tour_guide/features/interest/data/models/interest.dart';

class UserModel {
  final int id;
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final String? location;
  final String? phoneNumber;
  final String? profileImage;
  final int followerCount;
  final int followingCount;
  final String? role;
  final List<Interest> interests;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.bio,
    this.location,
    this.phoneNumber,
    this.profileImage,
    required this.followerCount,
    required this.followingCount,
    this.role,
    required this.interests,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim().isEmpty
      ? username
      : '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is String ? int.parse(json['id']) : (json['id'] ?? 0),
      username: json['username'] ?? '',
      email: json['email']?.toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      bio: json['bio']?.toString(),
      location: json['location']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      profileImage: json['profileImage']?.toString(),
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      role: json['role']?.toString() ?? 'USER',
      interests: (json['interests'] as List? ?? [])
          .map((e) => Interest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'interests': interests,
    };
  }

  /// ✅ use this when calling update profile API
  List<int> get interestIds => interests.map((e) => e.id).toList();
}

class AuthResponse {
  final String token;
  final UserModel user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    token: json['token'] ?? '',
    user: UserModel.fromJson(json['user'] ?? {}),
  );
}
