import 'package:flutter/cupertino.dart';

class ItineraryItem {
  final int? id;
  final String title;
  final String? notes;
  final String startTime;
  final String? endTime;
  final int dayNumber;
  final int orderInDay;
  final String activityType;
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
    this.activityType = "VISIT",
    this.isVisited = false,
    this.destinationId,
    this.destination,
  });

  ItineraryItem copyWith({
    int? id,
    String? title,
    String? notes,
    String? startTime,
    String? endTime,
    int? dayNumber,
    int? orderInDay,
    String? activityType,
    bool? isVisited,
    int? destinationId,
    Map<String, dynamic>? destination,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      dayNumber: dayNumber ?? this.dayNumber,
      orderInDay: orderInDay ?? this.orderInDay,
      activityType: activityType ?? this.activityType,
      isVisited: isVisited ?? this.isVisited,
      destinationId: destinationId ?? this.destinationId,
      destination: destination ?? this.destination,
    );
  }

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'] is int ? json['id'] : null,
      title: json['title']?.toString() ?? '', // Safe string conversion
      notes: json['notes']?.toString(),
      startTime: json['startTime']?.toString() ?? '09:00:00',
      endTime: json['endTime']?.toString(),
      dayNumber: json['dayNumber'] is int ? json['dayNumber'] : 1,
      orderInDay: json['orderInDay'] is int ? json['orderInDay'] : 0,
      activityType: json['activityType']?.toString() ?? "VISIT",
      // Force boolean check
      isVisited: (json['isVisited'] == true), 
      destinationId: json['destinationId'] is int ? json['destinationId'] : null,
      destination: json['destination'] is Map<String, dynamic> ? json['destination'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'notes': notes,
      'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      'dayNumber': dayNumber,
      'orderInDay': orderInDay,
      'isVisited': isVisited,
      if (destinationId != null) 'destinationId': destinationId,
      if (destination != null) 'destination': destination,
    };
  }
}