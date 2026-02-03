import 'package:tour_guide/features/auth/data/models/user_model.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary_item.dart';

class Itinerary {
  final int id;
  final String title;
  final String? description;
  final String? theme;
  final int? totalDays;
  final double? averageRating;
  final double? estimatedBudget;
  final bool isAdminCreated;
  final bool isPublic;
  final int? userId;
  final int? sourceId; // This determines if it's copied
  final String status; // e.g., 'DRAFT', 'ONGOING', 'COMPLETED'
  final DateTime? createdAt;
  final DateTime? endDate;
  final ItinerarySummary? summary;
  final List<ItineraryItem>? items;
  final UserModel? user;
  final int? copyCount;
  final int? likeCount;
  final String? country;
  final List<String>? tags;
  final bool? isLikedByCurrentUser;
  final bool? isSavedByCurrentUser;

  Itinerary({
    required this.id,
    required this.title,
    this.description,
    this.theme,
    this.totalDays,
    this.averageRating,
    this.estimatedBudget,
    required this.isAdminCreated,
    required this.isPublic,
    this.userId,
    this.sourceId,
    this.status = 'DRAFT', // Default status
    this.createdAt,
    this.endDate,
    this.summary,
    this.items,
    this.user, 
    this.copyCount,
    this.likeCount = 0,
    this.country,
    this.tags,
    this.isLikedByCurrentUser = false,
    this.isSavedByCurrentUser = false,
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
    bool? isLikedByCurrentUser,
    bool? isSavedByCurrentUser,
  }) {
    return Itinerary(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      theme: theme,
      totalDays: totalDays,
      averageRating: averageRating,
      estimatedBudget: estimatedBudget,
      isAdminCreated: isAdminCreated,
      isPublic: isPublic ?? this.isPublic,
      userId: userId,
      sourceId: sourceId,
      status: status ?? this.status,
      createdAt: createdAt,
      endDate: endDate,
      summary: summary ?? this.summary,
      items: items ?? this.items,
      user: user,
      copyCount: copyCount,
      likeCount: likeCount ?? this.likeCount,
      country: country,
      tags: tags,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isSavedByCurrentUser: isSavedByCurrentUser ?? this.isSavedByCurrentUser,
    );
  }

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      theme: json['theme'] as String?,
      totalDays: json['totalDays'] as int?,
      averageRating: json['averageRating']?.toDouble(),
      estimatedBudget: json['estimatedBudget']?.toDouble(),
      isAdminCreated: json['isAdminCreated'] ?? false,
      isPublic: json['isPublic'] ?? false,
      userId: json['userId'] as int?,
      sourceId: json['sourceId'] as int?,
      status: json['status'] as String? ?? 'DRAFT',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      summary: json['summary'] != null
          ? ItinerarySummary.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
      items: json['items'] != null
          ? (json['items'] as List<dynamic>)
                .map((i) => ItineraryItem.fromJson(i as Map<String, dynamic>))
                .toList()
          : null,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      copyCount: json['copyCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      country: json['countryCode'] as String?, // API returns countryCode
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] ?? false,
      isSavedByCurrentUser: json['isSavedByCurrentUser'] ?? false,
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