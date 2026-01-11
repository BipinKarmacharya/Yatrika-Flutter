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
      // Check 'short_description' first as seen in your logs
      description:
          json['short_description']?.toString() ??
          json['description']?.toString() ??
          '',
      tags: _parseTags(json['tags']),
      // Use the helper to check 'images' list AND 'cover_image_url'
      images: _parseImages(json),
      district: json['district']?.toString(),
      // Logic: Hibernate uses 'latitude'/'longitude', Flutter uses 'lat'/'lng'
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

  // FIXED: Logic moved to this helper method
  static List<String> _parseImages(Map<String, dynamic> json) {
    if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      return (json['images'] as List).map((e) => e.toString()).toList();
    }
    // Checking backend variants found in your logs
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
