// class Trip {
//   final String id;
//   final String title;
//   final String location;
//   final String imageUrl;
//   final String userName;
//   final String userImage;
//   final int days;
//   final double budget;
//   final int likes;
//   final List<String> tags;

//   Trip({
//     required this.id,
//     required this.title,
//     required this.location,
//     required this.imageUrl,
//     required this.userName,
//     required this.userImage,
//     required this.days,
//     required this.budget,
//     required this.likes,
//     required this.tags,
//   });

//   // This converts the JSON from your Spring Boot backend into this Trip object
//   factory Trip.fromJson(Map<String, dynamic> json) {
//     return Trip(
//       id: json['id']?.toString() ?? '',
//       title: json['title'] ?? 'Untitled Trip',
//       location: json['location'] ?? 'Unknown Location',
//       imageUrl: json['imageUrl'] ?? '',
//       userName: json['userName'] ?? 'User',
//       userImage: json['userImage'] ?? '',
//       days: json['days'] ?? 0,
//       budget: (json['budget'] ?? 0).toDouble(),
//       likes: json['likes'] ?? 0,
//       // Safely handle list of tags
//       tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
//     );
//   }
// }