class DailyPlan {
  final int day;
  final List<String> places;

  DailyPlan({required this.day, required this.places});

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    return DailyPlan(
      day: json['day'],
      places: List<String>.from(json['places']),
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'places': places,
      };
}

class MLPredictResponse {
  final String city;
  final int days;
  final int totalPois;
  final List<DailyPlan> dailyPlans;
  final String message;

  MLPredictResponse({
    required this.city,
    required this.days,
    required this.totalPois,
    required this.dailyPlans,
    required this.message,
  });

  factory MLPredictResponse.fromJson(Map<String, dynamic> json) {
    return MLPredictResponse(
      city: json['city'],
      days: json['days'],
      totalPois: json['total_pois'],
      dailyPlans: (json['daily_plans'] as List)
          .map((e) => DailyPlan.fromJson(e))
          .toList(),
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'city': city,
        'days': days,
        'total_pois': totalPois,
        'daily_plans': dailyPlans.map((e) => e.toJson()).toList(),
        'message': message,
      };
}