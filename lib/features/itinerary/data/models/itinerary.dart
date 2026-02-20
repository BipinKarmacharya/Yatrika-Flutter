import 'package:tour_guide/features/auth/data/models/user_model.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';

class Itinerary {
  final int id;
  final String title;
  final String? description;
  final String? theme;
  final double? averageRating;
  final double? estimatedBudget;
  final bool isAdminCreated;
  final bool isPublic;
  final int? userId;
  final int? sourceId; // This determines if it's copied
  final String status; // e.g., 'DRAFT', 'ONGOING', 'COMPLETED'
  final DateTime? createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? totalDays;
  final ItinerarySummary? summary;
  final List<ItineraryItem>? items;
  final UserModel? user;
  final int? copyCount;
  final int? likeCount;
  final String? country;
  final List<String>? tags;
  final bool? isLikedByCurrentUser;
  final bool? isSavedByCurrentUser;
  final List<String>? images;

  Itinerary({
    required this.id,
    required this.title,
    this.description,
    this.theme,
    this.averageRating,
    this.estimatedBudget,
    required this.isAdminCreated,
    required this.isPublic,
    this.userId,
    this.sourceId,
    this.status = 'DRAFT', // Default status
    this.createdAt,
    this.startDate,
    this.endDate,
    this.totalDays,
    this.summary,
    this.items,
    this.user,
    this.copyCount,
    this.likeCount = 0,
    this.country,
    this.tags,
    this.isLikedByCurrentUser = false,
    this.isSavedByCurrentUser = false,
    this.images,
  });

  // Computed property - trip is copied if sourceId is not null
  bool get isCopied => sourceId != null;

  // Computed property - trip is original if sourceId is null
  bool get isOriginal => sourceId == null;

  Itinerary copyWith({
    String? title,
    String? description,
    String? status,
    bool? isPublic,
    ItinerarySummary? summary,
    List<ItineraryItem>? items,
    int? likeCount,
    int? copyCount,
    bool? isLikedByCurrentUser,
    bool? isSavedByCurrentUser,
    List<String>? images,
    DateTime? startDate, 
    DateTime? endDate,   
    int? totalDays,
  }) {
    return Itinerary(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      theme: theme,
      totalDays: totalDays ?? this.totalDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      averageRating: averageRating,
      estimatedBudget: estimatedBudget,
      isAdminCreated: isAdminCreated,
      isPublic: isPublic ?? this.isPublic,
      userId: userId,
      sourceId: sourceId,
      status: status ?? this.status,
      createdAt: createdAt,
      summary: summary ?? this.summary,
      items: items ?? this.items,
      user: user,
      copyCount: copyCount ?? this.copyCount,
      likeCount: likeCount ?? this.likeCount,
      country: country,
      tags: tags,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isSavedByCurrentUser: isSavedByCurrentUser ?? this.isSavedByCurrentUser,
      images: images ?? this.images,
    );
  }

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      theme: json['theme'] as String?,
      averageRating: json['averageRating']?.toDouble(),
      estimatedBudget: json['estimatedBudget']?.toDouble(),
      isAdminCreated: json['isAdminCreated'] ?? false,
      isPublic: json['isPublic'] ?? false,
      userId:
          json['userId'] ??
          json['user_id'] ??
          (json['user'] != null ? json['user']['id'] : null),
      sourceId: json['sourceId'] as int?,
      status: json['status'] as String? ?? 'DRAFT',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null 
          ? DateTime.tryParse(json['endDate'].toString()) 
          : null,
      totalDays: json['totalDays'] as int?,
      summary: json['summary'] != null
          ? ItinerarySummary.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
      items: json['items'] != null
        ? (json['items'] as List)
            .map((i) => ItineraryItem.fromJson(i as Map<String, dynamic>))
            .toList()
        : null,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      copyCount: json['copyCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      country: json['countryCode'] as String?, // API returns countryCode
      tags: json['tags'] != null 
        ? (json['tags'] as List).map((e) => e.toString()).toList() 
        : null,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] ?? false,
      isSavedByCurrentUser: json['isSavedByCurrentUser'] ?? false,
      images: json['images'] != null
    ? (json['images'] as List).map((img) {
        if (img is Map) {
          return (img['url'] ?? img['imageUrl'] ?? "").toString();
        }
        return img.toString();
      }).where((s) => s.isNotEmpty).toList()
    : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'isPublic': isPublic,
      'sourceId': sourceId,
      'items': items?.map((i) => i.toJson()).toList(),
      'isLikedByCurrentUser': isLikedByCurrentUser,
      'isSavedByCurrentUser': isSavedByCurrentUser,
      'startDate': startDate?.toIso8601String().split('T')[0], // YYYY-MM-DD
      'endDate': endDate?.toIso8601String().split('T')[0],
      'totalDays': totalDays,
    };
  }
}

class ItinerarySummary {
  final double totalEstimatedBudget;
  final int activityCount;
  final int? completedActivities;
  final Map<String, int> activityTypeBreakdown;

  ItinerarySummary({
    required this.totalEstimatedBudget,
    required this.activityCount,
    this.completedActivities,
    required this.activityTypeBreakdown,
  });

  ItinerarySummary copyWith({int? completedActivities}) {
    return ItinerarySummary(
      totalEstimatedBudget: totalEstimatedBudget,
      activityCount: activityCount,
      completedActivities: completedActivities ?? this.completedActivities,
      activityTypeBreakdown: activityTypeBreakdown,
    );
  }

  factory ItinerarySummary.fromJson(Map<String, dynamic> json) {
    return ItinerarySummary(
      totalEstimatedBudget: json['totalEstimatedBudget']?.toDouble() ?? 0.0,
      activityCount: json['activityCount'] ?? 0,
      completedActivities: json['completedActivities'] ?? 0,
      activityTypeBreakdown: Map<String, int>.from(
        json['activityTypeBreakdown'] ?? {},
      ),
    );
  }
}
