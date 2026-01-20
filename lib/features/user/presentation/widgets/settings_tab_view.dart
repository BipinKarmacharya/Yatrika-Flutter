import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/profile_provider.dart';

class SettingsTabView extends StatelessWidget {
  final String email;
  const SettingsTabView({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.notifications_none, "Notifications"),
          _switchTile("Trip Reminders", "Get notified before your trips", provider.tripReminders, (v) => provider.toggleNotification('reminders', v)),
          _switchTile("New Followers", "When someone follows you", provider.newFollowers, (v) => provider.toggleNotification('followers', v)),
          _switchTile("Trip Recommendations", "Personalized destination suggestions", provider.recommendations, (v) => provider.toggleNotification('recommendations', v)),
          _switchTile("Weekly Digest", "Summary of trending trips", provider.weeklyDigest, (v) => provider.toggleNotification('digest', v)),
          
          const SizedBox(height: 32),
          _sectionHeader(Icons.shield_outlined, "Account & Privacy"),
          _arrowTile("Change Email", email),
          _arrowTile("Change Password", "Last changed 30 days ago"),
          _arrowTile("Privacy Settings", "Control who sees your trips"),
          _arrowTile("Download My Data", "Export all your trip data"),

          const SizedBox(height: 32),
          _buildDangerZone(context, provider),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 22),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _switchTile(String t, String s, bool v, Function(bool) onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text(s, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch(value: v, onChanged: onChanged, activeThumbColor: const Color(0xFF10B981)),
    );
  }

  Widget _arrowTile(String t, String s) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text(s, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
    );
  }

  Widget _buildDangerZone(BuildContext context, ProfileProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Danger Zone", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
          const Text("Irreversible actions for your account", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => provider.deleteAllTrips(),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                  child: const Text("Delete All Trips", style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
                  child: const Text("Delete Account", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}