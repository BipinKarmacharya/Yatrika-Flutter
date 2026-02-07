import 'package:intl/intl.dart';
import 'package:tour_guide/core/api/api_client.dart';

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
  final int totalComments;
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
    this.totalComments = 0,
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
      media: media ?? this.media,
      days: days ?? this.days,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final userObj = json['user'] != null
        ? PostUser.fromJson(json['user'])
        : null;

    return CommunityPost(
      // Backend returns 'id' as an integer
      id: json['id'],
      user: userObj,
      title: json['title'] ?? 'Untitled Trip',
      destination: json['destination'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      content: json['content'] ?? '',
      tripDurationDays: json['tripDurationDays'] ?? 1,
      estimatedCost: (json['estimatedCost'] ?? 0).toDouble(),
      // Logic: Use the Cloudinary URL directly if it's already a full URL
      coverImageUrl: ApiClient.getFullImageUrl(json['coverImageUrl']),
      isPublic: json['isPublic'] ?? true,
      isLiked: json['isLikedByCurrentUser'] ?? false,
      totalLikes: json['totalLikes'] ?? 0,
      totalComments: json['totalComments'] ?? 0,
      media:
          (json['media'] as List?)
              ?.map((m) => PostMedia.fromJson(m))
              .toList() ??
          [],
      days:
          (json['days'] as List?)?.map((d) => PostDay.fromJson(d)).toList() ??
          [],
      authorName: userObj?.username ?? 'Traveler',
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
    "isPublic": isPublic,
    // We don't send coverImageUrl here if we are uploading a NEW file
    "media": media.map((m) => m.toJson()).toList(),
    "days": days.map((d) => d.toJson()).toList(),
  };

  // Helper to get formatted date
  String get formattedDate {
    if (createdAt == null) return "";
    try {
      DateTime dt = DateTime.parse(createdAt!);
      return DateFormat('MMM d, yyyy').format(dt); // e.g. Jan 28, 2026
    } catch (e) {
      return "";
    }
  }
}

// --- HELPER CLASSES ---

class PostUser {
  final int id;
  final String username;
  final String fullName;
  final String? profileImage;
  final bool isFollowing;

  PostUser({
    required this.id,
    required this.username,
    required this.fullName,
    this.profileImage,
    this.isFollowing = false,
  });

  // ADD THIS METHOD:
  PostUser copyWith({
    int? id,
    String? username,
    String? fullName,
    String? profileImage,
    bool? isFollowing,
  }) {
    return PostUser(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      profileImage: profileImage ?? this.profileImage,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  factory PostUser.fromJson(Map<String, dynamic> json) {
    String? rawImg = json['profileImageUrl'] ?? json['profileImage'];

    return PostUser(
      id: json['id'] ?? 0,
      username: json['username'] ?? 'Traveler',
      fullName: json['fullName'] ?? json['username'] ?? 'Guest',
      profileImage: ApiClient.getFullImageUrl(rawImg),
      isFollowing: json['isFollowing'] ?? false,
    );
  }
}

class PostMedia {
  final String mediaUrl;
  final String mediaType;
  final String? caption;
  final int dayNumber;

  PostMedia({
    required this.mediaUrl,
    this.mediaType = "IMAGE",
    this.caption,
    this.dayNumber = 1,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) => PostMedia(
    mediaUrl: ApiClient.getFullImageUrl(json['mediaUrl'] ?? json['url']),
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
