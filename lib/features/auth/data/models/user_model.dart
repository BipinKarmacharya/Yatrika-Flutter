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
  final String? role;
  final List<String> interests;

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
    this.role,
    this.interests = const [],
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim().isEmpty
      ? username
      : '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is String ? int.parse(json['id']) : (json['id'] ?? 0),
      username: json['username'] ?? '',
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      bio: json['bio'],
      location: json['location'],
      profileImage: json['profileImage'],
      role: json['role'],
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : [],
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
      'interests': interests,
    };
  }
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
