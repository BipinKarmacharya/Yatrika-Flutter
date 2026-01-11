class Review {
  final String? id;
  final String authorId;
  final String destinationId;
  final int rating;
  final String comment;
  final bool verified;

  Review({
    this.id,
    required this.authorId,
    required this.destinationId,
    required this.rating,
    required this.comment,
    this.verified = false,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id']?.toString(),
    authorId: json['authorId']?.toString() ?? '',
    destinationId: json['destinationId']?.toString() ?? '',
    rating: json['rating'] is int
        ? json['rating']
        : int.tryParse('${json['rating']}') ?? 0,
    comment: json['comment']?.toString() ?? '',
    verified: json['verified'] == true,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'authorId': authorId,
    'destinationId': destinationId,
    'rating': rating,
    'comment': comment,
    'verified': verified,
  };
}
