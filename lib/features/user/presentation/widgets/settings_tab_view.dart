import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/profile_provider.dart';
import '../../../auth/logic/auth_provider.dart';

class SettingsTabView extends StatefulWidget {
  final String email;
  const SettingsTabView({super.key, required this.email});

  @override
  State<SettingsTabView> createState() => _SettingsTabViewState();
}

class _SettingsTabViewState extends State<SettingsTabView> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;

  final List<String> _allInterests = [
    "Adventure", "Beach", "Cultural", "Food", "Hiking",
    "Historical", "Mountains", "Nature", "Nightlife", "Wellness",
  ];

  List<String> _selectedInterests = [];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _firstNameController = TextEditingController(text: user?.firstName ?? "");
    _lastNameController = TextEditingController(text: user?.lastName ?? "");
    _usernameController = TextEditingController(text: user?.username ?? "");
    _selectedInterests = List.from(user?.interests ?? []);

    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _usernameController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  bool _isDirty() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return false;

    bool nameChanged = _firstNameController.text != (user.firstName ?? "") ||
        _lastNameController.text != (user.lastName ?? "");
    bool usernameChanged = _usernameController.text != user.username;
    bool interestsChanged = _selectedInterests.length != user.interests.length ||
        !_selectedInterests.every((i) => user.interests.contains(i));

    return nameChanged || usernameChanged || interestsChanged;
  }

  void _resetChanges() {
    final user = context.read<AuthProvider>().user;
    setState(() {
      _firstNameController.text = user?.firstName ?? "";
      _lastNameController.text = user?.lastName ?? "";
      _usernameController.text = user?.username ?? "";
      _selectedInterests = List.from(user?.interests ?? []);
    });
  }

  Future<void> _showLogoutDialog(BuildContext context, AuthProvider auth) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to log out of Yatrika?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sign Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await auth.logout();
      if (mounted) Navigator.pop(context); // Close the bottom sheet
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.person_outline, "Personal Information"),
            Row(
              children: [
                Expanded(child: _editField("First Name", _firstNameController)),
                const SizedBox(width: 12),
                Expanded(child: _editField("Last Name", _lastNameController)),
              ],
            ),
            _editField("Username", _usernameController, prefix: "@"),
            _readOnlyField("Email", widget.email),

            const SizedBox(height: 32),
            _sectionHeader(Icons.explore_outlined, "Travel Interests"),
            Wrap(
              spacing: 8,
              children: _allInterests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest, style: TextStyle(fontSize: 13, color: isSelected ? const Color(0xFF10B981) : Colors.black87)),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      selected ? _selectedInterests.add(interest) : _selectedInterests.remove(interest);
                    });
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: const Color(0xFF10B981).withOpacity(0.1),
                  checkmarkColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? const Color(0xFF10B981) : Colors.transparent)),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            _sectionHeader(Icons.settings_suggest_outlined, "Account Actions"),
            ListTile(
              onTap: () => _showLogoutDialog(context, authProvider),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              subtitle: const Text("Sign out of your current session"),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),

            const SizedBox(height: 32),
            _buildDangerZone(context, profileProvider),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: _isDirty() ? _buildActionPopup(authProvider) : null,
    );
  }

  // --- Helper Widgets ---

  Widget _buildActionPopup(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _resetChanges,
              child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleSave(auth),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave(AuthProvider auth) async {
    final success = await auth.updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      username: _usernameController.text.trim(),
      interests: _selectedInterests,
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated!"), backgroundColor: Color(0xFF10B981)),
      );
    }
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 22),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _editField(String label, TextEditingController controller, {String? prefix}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF10B981), width: 2)),
        ),
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, ProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Danger Zone", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.03),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _dangerTile("Delete All Trips", "Permanently remove your journey history", () => provider.deleteAllTrips()),
              const Divider(),
              _dangerTile("Delete Account", "This action cannot be undone", () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dangerTile(String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.red),
    );
  }
}