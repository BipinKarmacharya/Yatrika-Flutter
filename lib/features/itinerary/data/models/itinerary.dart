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
  final int? sourceId;
  final ItinerarySummary? summary;
  final List<ItineraryItem>? items; 

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
    this.summary,
    this.items, // Initialize it
  });

  // 2. Update copyWith to include items
  Itinerary copyWith({
    String? title,
    String? description,
    ItinerarySummary? summary,
    List<ItineraryItem>? items,
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
      isPublic: isPublic,
      userId: userId,
      sourceId: sourceId,
      summary: summary ?? this.summary,
      items: items ?? this.items,
    );
  }

  // 3. Update fromJson to parse items
  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      theme: json['theme'],
      totalDays: json['totalDays'],
      averageRating: json['averageRating']?.toDouble(),
      estimatedBudget: json['estimatedBudget']?.toDouble(),
      isAdminCreated: json['isAdminCreated'] ?? false,
      isPublic: json['isPublic'] ?? false,
      userId: json['userId'],
      sourceId: json['sourceId'],
      summary: json['summary'] != null
          ? ItinerarySummary.fromJson(json['summary'])
          : null,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => ItineraryItem.fromJson(i)).toList()
          : [],
    );
  }

  // 4. Add toJson for the "Full Save" feature
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'items': items?.map((i) => i.toJson()).toList(),
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
