class Itinerary {
  final int id;
  final String title;
  final String? description;
  final String? theme;
  final int? totalDays;
  final double? averageRating;
  final double? estimatedBudget;
  final bool isAdminCreated;
  final ItinerarySummary? summary;

  Itinerary({
    required this.id,
    required this.title,
    this.description,
    this.theme,
    this.totalDays,
    this.averageRating,
    this.estimatedBudget,
    required this.isAdminCreated,
    this.summary,
  });

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
      summary: json['summary'] != null ? ItinerarySummary.fromJson(json['summary']) : null,
    );
  }
}

class ItinerarySummary {
  final double totalEstimatedBudget;
  final int activityCount;
  final Map<String, int> activityTypeBreakdown;

  ItinerarySummary({
    required this.totalEstimatedBudget,
    required this.activityCount,
    required this.activityTypeBreakdown,
  });

  factory ItinerarySummary.fromJson(Map<String, dynamic> json) {
    return ItinerarySummary(
      totalEstimatedBudget: json['totalEstimatedBudget']?.toDouble() ?? 0.0,
      activityCount: json['activityCount'] ?? 0,
      activityTypeBreakdown: Map<String, int>.from(json['activityTypeBreakdown'] ?? {}),
    );
  }
}