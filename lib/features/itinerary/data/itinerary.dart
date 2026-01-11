class Itinerary {
  final String id;
  final String title;
  final String? authorId;
  final List<Map<String, dynamic>>
  items; // items can be simple maps (destination references)
  final String? status;
  final String? coverImageUrl;
  final int? totalDays;
  final double? estimatedTotalCost;
  final int? totalViews;
  final int? totalLikes;
  final bool? isPublic;

  Itinerary({
    required this.id,
    required this.title,
    this.authorId,
    required this.items,
    this.status,
    this.coverImageUrl,
    this.totalDays,
    this.estimatedTotalCost,
    this.totalViews,
    this.totalLikes,
    this.isPublic,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) => Itinerary(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    authorId: json['user'] != null
        ? (json['user']['id']?.toString())
        : json['authorId']?.toString(),
    items:
        (json['items'] as List?)
            ?.map((e) => (e as Map).cast<String, dynamic>())
            .toList() ??
        [],
    status: json['status']?.toString(),
    coverImageUrl: json['coverImageUrl']?.toString(),
    totalDays: json['totalDays'] is int
        ? json['totalDays']
        : int.tryParse('${json['totalDays']}'),
    estimatedTotalCost: json['estimatedTotalCost'] is num
        ? (json['estimatedTotalCost'] as num).toDouble()
        : double.tryParse('${json['estimatedTotalCost']}'),
    totalViews: json['totalViews'] is int
        ? json['totalViews']
        : int.tryParse('${json['totalViews']}'),
    totalLikes: json['totalLikes'] is int
        ? json['totalLikes']
        : int.tryParse('${json['totalLikes']}'),
    isPublic: json['isPublic'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (authorId != null) 'authorId': authorId,
    'items': items,
    if (status != null) 'status': status,
    if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
    if (totalDays != null) 'totalDays': totalDays,
    if (estimatedTotalCost != null) 'estimatedTotalCost': estimatedTotalCost,
    if (totalViews != null) 'totalViews': totalViews,
    if (totalLikes != null) 'totalLikes': totalLikes,
    if (isPublic != null) 'isPublic': isPublic,
  };
}
