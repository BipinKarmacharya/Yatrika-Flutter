import 'package:flutter/foundation.dart';
import 'package:tour_guide/core/api/api_client.dart';

@immutable
class Destination {
  final String id;
  final String name;
  final String shortDescription; // Added
  final String? description;
  final String? district;
  final List<String> tags;
  final List<String> images;
  final double? lat;
  final double? lng;
  final double averageRating; // Added
  final double cost; // Added (using entranceFeeLocal)
  final int totalReviews; // From "totalReviews" in your JSON
  final String difficultyLevel; // For the tags
  final String bestTime;

  const Destination({
    required this.id,
    required this.name,
    required this.shortDescription,
    this.description,
    this.district,
    this.tags = const [],
    required this.images,
    this.lat,
    this.lng,
    this.averageRating = 0.0,
    this.cost = 0.0,
    this.totalReviews = 0,
    this.difficultyLevel = 'MODERATE',
    this.bestTime = 'All Year',
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      shortDescription: json['shortDescription']?.toString() ?? '',
      description: json['description']?.toString(),
      district: json['district']?.toString(),
      tags: _parseTags(json['tags']),
      images: _parseImages(json),
      lat: (json['latitude'] as num?)?.toDouble(),
      lng: (json['longitude'] as num?)?.toDouble(),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      cost: (json['entranceFeeLocal'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] ?? 0,
      difficultyLevel: json['difficultyLevel'] ?? 'EASY',
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
    List<String> result = [];

    if (json['images'] is List) {
      for (var item in json['images']) {
        String? path;
        if (item is Map) {
          path = item['imageUrl']?.toString();
        } else {
          path = item.toString();
        }

        if (path != null && path.isNotEmpty) {
          result.add(ApiClient.getFullImageUrl(path));
        }
      }
    }

    // 2. Fallback for single image fields
    if (result.isEmpty) {
      String? singleImage =
          json['imageUrl'] ?? json['image_url'] ?? json['cover_image_url'];
      if (singleImage != null && singleImage.isNotEmpty) {
        result.add(ApiClient.getFullImageUrl(singleImage));
      }
    }

    return result;
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

  // String get escription => description ?? '';
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
