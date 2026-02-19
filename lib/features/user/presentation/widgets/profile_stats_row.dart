import 'package:flutter/material.dart';

class ProfileStatsRow extends StatelessWidget {
  final int postCount;
  final int totalLikes;
  final int followersCount;

  const ProfileStatsRow({
    super.key,
    required this.postCount,
    required this.totalLikes,
    required this.followersCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("Posts", postCount.toString()),
          _buildDivider(),
          _buildStatItem("Likes", totalLikes.toString()),
          _buildDivider(),
          _buildStatItem("Followers", followersCount.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[300]);
  }
}
