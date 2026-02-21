import 'package:flutter/foundation.dart';
import 'package:tour_guide/core/api/api_client.dart';

@immutable
class Destination {
  final String id;
  final String name;
  final String shortDescription;
  final String? description;
  final String? district;
  final List<String> tags;
  final List<String> images;
  final double? lat;
  final double? lng;
  final double averageRating; 
  final double cost; 
  final int totalReviews; 
  final String difficultyLevel; 
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
      images: _parseImages(json), // Use the refined parser below
      lat: (json['latitude'] as num?)?.toDouble(),
      lng: (json['longitude'] as num?)?.toDouble(),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      cost: (json['entranceFeeLocal'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      difficultyLevel: json['difficultyLevel']?.toString() ?? 'MODERATE',
      bestTime: json['bestTime']?.toString() ?? 'All Year',
    );
  }

  static List<String> _parseImages(Map<String, dynamic> json) {
    List<String> result = [];

    // 1. Handle the "images" list from your DestinationResponse DTO
    if (json['images'] is List) {
      for (var item in json['images']) {
        if (item is Map<String, dynamic> && item.containsKey('imageUrl')) {
          result.add(ApiClient.getFullImageUrl(item['imageUrl']));
        }
      }
    }

    // 2. Fallback for the simpler "popular" endpoint format
    if (result.isEmpty && json['imageUrl'] != null) {
      result.add(ApiClient.getFullImageUrl(json['imageUrl']));
    }

    return result;
  }

  static List<String> _parseTags(dynamic tagsJson) {
    if (tagsJson == null) return [];
    if (tagsJson is List) {
      // This is what Spring Boot sends for String[] tags
      return tagsJson.map((e) => e.toString()).toList();
    }
    if (tagsJson is String) {
      if (tagsJson.startsWith('{') && tagsJson.endsWith('}')) {
        // Handles raw Postgres array format if necessary
        return tagsJson.substring(1, tagsJson.length - 1).split(',');
      }
      return tagsJson.split(',').map((e) => e.trim()).toList();
    }
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

}