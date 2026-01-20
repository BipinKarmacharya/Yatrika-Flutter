import 'package:flutter/material.dart';
import '../../data/models/user_stats.dart';

class ProfileStatsRow extends StatelessWidget {
  // 1. Change to optional (UserStats?) and remove 'required'
  final UserStats? stats;
  
  const ProfileStatsRow({super.key, this.stats});

  @override
  Widget build(BuildContext context) {
    // 2. Use the passed stats, or the mock if none were provided
    final displayStats = stats ?? UserStats.mock();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 3. Use 'displayStats' here instead of 'stats'
          _buildStat(displayStats.tripsCount.toString(), "Trips", Icons.location_on_outlined),
          _buildStat(displayStats.savedCount.toString(), "Saved", Icons.bookmark_border),
          _buildStat(displayStats.daysTraveled.toString(), "Days Traveled", Icons.calendar_today_outlined),
          _buildStat(displayStats.countriesCount.toString(), "Countries", Icons.public_outlined),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}