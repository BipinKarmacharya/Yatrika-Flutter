class UserModel {
  final String id;
  final String username;
  final String? email;
  final String? firstName; 
  final String? lastName; 
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? role;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profileImageUrl,
    this.role,
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
      profileImageUrl: json['profileImageUrl'],
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
      'profileImageUrl': profileImageUrl,
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
