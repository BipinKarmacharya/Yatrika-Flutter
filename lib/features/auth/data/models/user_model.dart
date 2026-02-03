class UserModel {
  final String id;
  final String username;
  final String? email;
  final String? firstName; 
  final String? lastName; 
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
    this.phoneNumber,
    this.profileImage,
    this.role,
    this.interests = const [],
  });

  // Getter for convenience
  String get fullName =>
      '$firstName $lastName'.trim().isEmpty ? username : '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',      
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'], // Matches Spring Boot JSON key
      lastName: json['lastName'], // Matches Spring Boot JSON key
      phoneNumber: json['phoneNumber'], // Matches Spring Boot JSON key
      profileImage: json['profileImage'],
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
