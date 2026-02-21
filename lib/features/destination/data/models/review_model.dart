class Review {
  final int id;
  final ReviewUser user;
  final int destinationId;
  final double rating;
  final String comment;
  final DateTime visitedDate;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.user,
    required this.destinationId,
    required this.rating,
    required this.comment,
    required this.visitedDate,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'],
        user: ReviewUser.fromJson(json['user']),
        destinationId: json['destinationId'],
        rating: (json['rating'] as num).toDouble(),
        comment: json['comment'] ?? '',
        visitedDate: DateTime.parse(json['visitedDate']),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class ReviewUser {
  final String fullName;
  final String? profileImage;
  final String username;

  ReviewUser({required this.fullName, this.profileImage, required this.username});

  factory ReviewUser.fromJson(Map<String, dynamic> json) => ReviewUser(
        fullName: json['fullName'] ?? 'Anonymous',
        profileImage: json['profileImage'],
        username: json['username'] ?? '',
      );
}