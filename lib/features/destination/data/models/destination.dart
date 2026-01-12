// class Destination {
//   final String id;
//   final String name;
//   final String? description;
//   final List<String> tags;
//   final List<String> images;
//   final String? district;
//   final double? lat;
//   final double? lng;

//   Destination({
//     required this.id,
//     required this.name,
//     this.description,
//     this.tags = const [],
//     required this.images,
//     this.district,
//     this.lat,
//     this.lng,
//   });

//   factory Destination.fromJson(Map<String, dynamic> json) {
//     return Destination(
//       id: json['id']?.toString() ?? '',
//       name: json['name']?.toString() ?? 'Unknown Destination',
//       // Check 'short_description' first as seen in your logs
//       description:
//           json['short_description']?.toString() ??
//           json['description']?.toString() ??
//           '',
//       tags: _parseTags(json['tags']),
//       // Use the helper to check 'images' list AND 'cover_image_url'
//       images: _parseImages(json),
//       district: json['district']?.toString(),
//       // Logic: Hibernate uses 'latitude'/'longitude', Flutter uses 'lat'/'lng'
//       lat: (json['latitude'] as num?)?.toDouble(),
//       lng: (json['longitude'] as num?)?.toDouble(),
//     );
//   }

//   static List<String> _parseTags(dynamic tagsJson) {
//     if (tagsJson == null) return [];
//     if (tagsJson is String) {
//       return tagsJson.split(',').map((e) => e.trim()).toList();
//     }
//     if (tagsJson is List) {
//       return tagsJson.map((e) => e.toString()).toList();
//     }
//     return [];
//   }

//   // FIXED: Logic moved to this helper method
//   static List<String> _parseImages(Map<String, dynamic> json) {
//     if (json['images'] is List && (json['images'] as List).isNotEmpty) {
//       return (json['images'] as List).map((e) => e.toString()).toList();
//     }
//     // Checking backend variants found in your logs
//     if (json['cover_image_url'] != null) {
//       return [json['cover_image_url'].toString()];
//     }
//     if (json['image_url'] != null) return [json['image_url'].toString()];
//     return [];
//   }

//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'name': name,
//     if (description != null) 'description': description,
//     'tags': tags,
//     'images': images,
//     if (district != null) 'district': district,
//     if (lat != null) 'lat': lat,
//     if (lng != null) 'lng': lng,
//   };

//   String get shortDescription => description ?? '';
// }


// lib/features/destination/data/models/destination.dart
import 'package:flutter/foundation.dart';

@immutable
class Destination {
  final String id;
  final String name;
  final String? description;
  final List<String> tags;
  final List<String> images;
  final String? district;
  final double? lat;
  final double? lng;

  Destination({
    required this.id,
    required this.name,
    this.description,
    this.tags = const [],
    required this.images,
    this.district,
    this.lat,
    this.lng,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Destination',
      description:
          json['short_description']?.toString() ??
          json['description']?.toString() ??
          '',
      tags: _parseTags(json['tags']),
      images: _parseImages(json),
      district: json['district']?.toString(),
      lat: (json['latitude'] as num?)?.toDouble(),
      lng: (json['longitude'] as num?)?.toDouble(),
    );
  }

  static List<String> _parseTags(dynamic tagsJson) {
    if (tagsJson == null) return [];
    if (tagsJson is String) {
      return tagsJson.split(',').map((e) => e.trim()).toList();
    }
    if (tagsJson is List) {
      return tagsJson.map((e) => e.toString()).toList();
    }
    return [];
  }

  static List<String> _parseImages(Map<String, dynamic> json) {
    if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      return (json['images'] as List).map((e) => e.toString()).toList();
    }
    if (json['cover_image_url'] != null) {
      return [json['cover_image_url'].toString()];
    }
    if (json['image_url'] != null) return [json['image_url'].toString()];
    return [];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'tags': tags,
    'images': images,
    if (district != null) 'district': district,
    if (lat != null) 'lat': lat,
    if (lng != null) 'lng': lng,
  };

  String get shortDescription => description ?? '';
}

class Review {
  final String? id;
  final String authorId;
  final String destinationId;
  final int rating;
  final String comment;
  final bool verified;

  Review({
    this.id,
    required this.authorId,
    required this.destinationId,
    required this.rating,
    required this.comment,
    this.verified = false,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id']?.toString(),
    authorId: json['authorId']?.toString() ?? '',
    destinationId: json['destinationId']?.toString() ?? '',
    rating: json['rating'] is int
        ? json['rating']
        : int.tryParse('${json['rating']}') ?? 0,
    comment: json['comment']?.toString() ?? '',
    verified: json['verified'] == true,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'authorId': authorId,
    'destinationId': destinationId,
    'rating': rating,
    'comment': comment,
    'verified': verified,
  };
}