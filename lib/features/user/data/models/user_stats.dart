class UserStats {
  final int tripsCount;
  final int savedCount;
  final int daysTraveled;
  final int countriesCount;

  UserStats({
    required this.tripsCount,
    required this.savedCount,
    required this.daysTraveled,
    required this.countriesCount,
  });

  // Mock data for initial UI testing
  factory UserStats.mock() => UserStats(
    tripsCount: 12,
    savedCount: 45,
    daysTraveled: 156,
    countriesCount: 8,
  );
}