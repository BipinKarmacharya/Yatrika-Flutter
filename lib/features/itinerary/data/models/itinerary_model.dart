class ItineraryResponse {
  final int id;
  final String title;
  final String description;
  final String theme;
  final bool active;
  final List<ItineraryItem> items;

  ItineraryResponse({
    required this.id,
    required this.title,
    required this.description,
    required this.theme,
    required this.active,
    required this.items,
  });

  factory ItineraryResponse.fromJson(Map<String, dynamic> json) {
    return ItineraryResponse(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      theme: json['theme'] ?? '',
      active: json['active'] ?? false,
      items: (json['items'] as List)
          .map((item) => ItineraryItem.fromJson(item))
          .toList(),
    );
  }
}

class ItineraryItem {
  final int id;
  final int dayNumber;
  final int orderInDay;
  final String startTime;
  final String title;
  final String? description;
  final int destinationId;

  ItineraryItem({
    required this.id,
    required this.dayNumber,
    required this.orderInDay,
    required this.startTime,
    required this.title,
    this.description,
    required this.destinationId,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'],
      dayNumber: json['dayNumber'],
      orderInDay: json['orderInDay'],
      startTime: json['startTime'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      destinationId: json['destinationId'],
    );
  }
}