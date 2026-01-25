class CommunityPost {
  final int? id;
  final PostUser? user;
  final String title;
  final String? destination;
  final List<String> tags;
  final String content;
  final int tripDurationDays;
  final double estimatedCost;
  final String coverImageUrl;
  final bool isPublic;
  final bool isLiked;
  final int totalLikes;
  final int totalViews;
  final List<PostMedia> media;
  final List<PostDay> days;
  final String authorName;
  final String? authorAvatar;
  final String? createdAt;

  CommunityPost({
    this.id,
    this.user,
    required this.title,
    this.destination,
    this.tags = const [],
    required this.content,
    required this.tripDurationDays,
    required this.estimatedCost,
    required this.coverImageUrl,
    this.isPublic = true,
    this.isLiked = false,
    this.totalLikes = 0,
    this.totalViews = 0,
    required this.media,
    required this.days,
    required this.authorName,
    this.authorAvatar,
    this.createdAt,
  });

  CommunityPost copyWith({
    int? id,
    PostUser? user,
    String? title,
    String? destination,
    List<String>? tags,
    String? content,
    int? tripDurationDays,
    double? estimatedCost,
    String? coverImageUrl,
    bool? isPublic,
    bool? isLiked,
    int? totalLikes,
    int? totalViews,
    List<PostMedia>? media,
    List<PostDay>? days,
    String? authorName,
    String? authorAvatar,
    String? createdAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      user: user ?? this.user,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      tags: tags ?? this.tags,
      content: content ?? this.content,
      tripDurationDays: tripDurationDays ?? this.tripDurationDays,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isPublic: isPublic ?? this.isPublic,
      isLiked: isLiked ?? this.isLiked,
      totalLikes: totalLikes ?? this.totalLikes,
      totalViews: totalViews ?? this.totalViews,
      media: media ?? this.media,
      days: days ?? this.days,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Inside CommunityPost.fromJson
  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    // 1. Correctly map the User
    final userObj = json['user'] != null
        ? PostUser.fromJson(json['user'])
        : null;

    return CommunityPost(
      id: json['id'],
      user: userObj,
      title: json['title'] ?? 'Untitled Trip',
      // Handle the case where destination might be null in JSON
      destination: json['destination'] as String?,
      // Safely parse tags list
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      content: json['content'] ?? '',
      tripDurationDays: json['tripDurationDays'] ?? 1,
      estimatedCost: (json['estimatedCost'] ?? 0).toDouble(),
      // We prepend the base URL later in the UI or here
      coverImageUrl: json['coverImageUrl'] ?? '',
      isPublic: json['isPublic'] ?? true,
      isLiked: json['isLikedByCurrentUser'] ?? false, // Matches your JSON key
      totalLikes: json['totalLikes'] ?? 0,
      totalViews: json['totalViews'] ?? 0,
      // Safely parse nested lists
      media:
          (json['media'] as List?)
              ?.map((m) => PostMedia.fromJson(m))
              .toList() ??
          [],
      days:
          (json['days'] as List?)?.map((d) => PostDay.fromJson(d)).toList() ??
          [],
      authorName: userObj?.fullName ?? 'Traveler',
      authorAvatar: userObj?.profileImage,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    "title": title,
    "destination": destination,
    "tags": tags,
    "content": content,
    "tripDurationDays": tripDurationDays,
    "estimatedCost": estimatedCost,
    "coverImageUrl": coverImageUrl,
    "isPublic": isPublic,
    "media": media.map((m) => m.toJson()).toList(),
    "days": days.map((d) => d.toJson()).toList(),
  };
}

// --- RESTORED HELPER CLASSES ---

class PostUser {
  final String username;
  final String fullName;
  final String? profileImage;

  PostUser({required this.username, required this.fullName, this.profileImage});

  factory PostUser.fromJson(Map<String, dynamic> json) {
    return PostUser(
      username: json['username'] ?? 'Traveler',
      fullName: json['fullName'] ?? 'Guest',
      // FIX: Match the 'profileImageUrl' key from your JSON response
      profileImage: json['profileImageUrl'] ?? json['profileImage'], 
    );
  }
}

class PostMedia {
  final String mediaUrl;
  final String mediaType;
  final String? caption;
  final int dayNumber;

  PostMedia({required this.mediaUrl, this.mediaType = "IMAGE", this.caption, this.dayNumber = 1});

  factory PostMedia.fromJson(Map<String, dynamic> json) => PostMedia(
    // Ensure mediaUrl isn't null
    mediaUrl: json['mediaUrl'] ?? '',
    mediaType: json['mediaType'] ?? "IMAGE",
    caption: json['caption'] as String?,
    dayNumber: json['dayNumber'] ?? 1,
  );


  Map<String, dynamic> toJson() => {
    "mediaUrl": mediaUrl,
    "mediaType": mediaType,
    "caption": caption,
    "dayNumber": dayNumber,
  };
}

class PostDay {
  final int dayNumber;
  final String description;
  final String activities;
  final String? accommodation;
  final String? food;
  final String? transportation;

  PostDay({
    required this.dayNumber,
    required this.description,
    required this.activities,
    this.accommodation,
    this.food,
    this.transportation,
  });

  factory PostDay.fromJson(Map<String, dynamic> json) => PostDay(
    dayNumber: json['dayNumber'] ?? 1,
    description: json['description'] ?? '',
    activities: json['activities'] ?? '',
    accommodation: json['accommodation'],
    food: json['food'],
    transportation: json['transportation'],
  );

  Map<String, dynamic> toJson() => {
    "dayNumber": dayNumber,
    "description": description,
    "activities": activities,
    "accommodation": accommodation ?? "Standard",
    "food": food ?? "Local",
    "transportation": transportation ?? "Public",
  };
}
