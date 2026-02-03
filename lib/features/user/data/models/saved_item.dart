class SavedItem {
  final String id;
  final String itemId;
  final String userId;
  final SavedItemType type;
  final DateTime savedAt;
  final Map<String, dynamic> itemData; // The actual saved content

  SavedItem({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.type,
    required this.savedAt,
    required this.itemData,
  });

  factory SavedItem.fromJson(Map<String, dynamic> json) {
    return SavedItem(
      id: json['id']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      type: SavedItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SavedItemType.destination,
      ),
      savedAt: DateTime.parse(json['savedAt']),
      itemData: json['itemData'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'userId': userId,
      'type': type.name,
      'savedAt': savedAt.toIso8601String(),
      'itemData': itemData,
    };
  }
}

enum SavedItemType {
  destination,
  itinerary,
  publicTrip,
}