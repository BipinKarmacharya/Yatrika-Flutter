import 'package:flutter/widgets.dart';

class ItineraryItem {
  final int? id; // Nullable for new activities added by the user
  final String title;
  final String? notes;
  final String startTime;
  final String? endTime;
  final int dayNumber;
  final int orderInDay;
  final bool isVisited;
  final int? destinationId;
  final Map<String, dynamic>? destination;

  ItineraryItem({
    this.id,
    required this.title,
    this.notes,
    required this.startTime,
    this.endTime,
    required this.dayNumber,
    required this.orderInDay,
    this.isVisited = false,
    this.destinationId,
    this.destination,
  });

  // copyWith is essential for updating time/notes locally
  ItineraryItem copyWith({
    String? startTime,
    int? orderInDay,
    bool? isVisited,
    Map<String, dynamic>? destination,
    String? notes,
  }) {
    return ItineraryItem(
      id: id,
      title: title,
      notes: notes ?? this.notes,
      startTime: startTime ?? this.startTime,
      endTime: endTime,
      dayNumber: dayNumber,
      orderInDay: orderInDay ?? this.orderInDay,
      isVisited: isVisited ?? this.isVisited,
      destinationId: destinationId,
      destination: destination ?? this.destination,
    );
  }

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    debugPrint("🔍 Parsing ItineraryItem JSON: ${json.keys.toList()}");
    debugPrint(
      "   isVisited field: ${json['isVisited']}, visited: ${json['visited']}, is_visited: ${json['is_visited']}",
    );
    return ItineraryItem(
      id: json['id'],
      title: json['title'] ?? '',
      notes: json['notes'],
      startTime: json['startTime'] ?? '09:00:00',
      endTime: json['endTime'],
      dayNumber: json['dayNumber'] ?? 1,
      orderInDay: json['orderInDay'] ?? 0,
      isVisited: json['is_visited'] ?? json['is_visited'] ?? json['isVisited'] ?? false,
      destinationId:
          json['destinationId'] ??
          (json['destination'] != null ? json['destination']['id'] : null),
      destination: json['destination'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'notes': notes,
      'startTime': startTime,
      'dayNumber': dayNumber,
      'orderInDay': orderInDay,
      'isVisited': isVisited,
      'destinationId':
          destinationId ?? (destination != null ? destination!['id'] : null),
      'destination': destination,
    };
  }
}
