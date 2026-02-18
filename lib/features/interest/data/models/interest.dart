class Interest {
  final int id;
  final String name;
  final String? icon;

  Interest({
    required this.id,
    required this.name,
    this.icon,
  });

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'General',
      icon: json['icon'],
    );
  }
}
