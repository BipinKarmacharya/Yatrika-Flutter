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
  // Controllers for editable fields
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;

  final List<String> _allInterests = [
    "Adventure",
    "Beach",
    "Cultural",
    "Food",
    "Hiking",
    "Historical",
    "Mountains",
    "Nature",
    "Nightlife",
    "Wellness",
  ];

  List<String> _selectedInterests = [];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;

    // Initialize controllers with current data
    _firstNameController = TextEditingController(text: user?.firstName ?? "");
    _lastNameController = TextEditingController(text: user?.lastName ?? "");
    _usernameController = TextEditingController(text: user?.username ?? "");
    _selectedInterests = List.from(user?.interests ?? []);

    // Listen for changes to trigger UI updates for Save/Cancel buttons
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

    bool nameChanged =
        _firstNameController.text != (user.firstName ?? "") ||
        _lastNameController.text != (user.lastName ?? "");
    bool usernameChanged = _usernameController.text != user.username;
    bool interestsChanged =
        _selectedInterests.length != user.interests.length ||
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

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
              runSpacing: 0,
              children: _allInterests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      selected
                          ? _selectedInterests.add(interest)
                          : _selectedInterests.remove(interest);
                    });
                  },
                  selectedColor: const Color(0xFF10B981).withOpacity(0.1),
                  checkmarkColor: const Color(0xFF10B981),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            _sectionHeader(Icons.lock_outline, "Security"),
            _arrowTile("Change Password", "Secure your account"),

            const SizedBox(height: 32),
            _buildDangerZone(context, profileProvider),
            const SizedBox(height: 120),
          ],
        ),
      ),
      // Sticky Action Buttons
      bottomSheet: _isDirty() ? _buildActionPopup(authProvider) : null,
    );
  }

  Widget _buildActionPopup(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _resetChanges,
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleSave(auth),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: const Text(
                "Save Changes",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave(AuthProvider auth) async {
    // Show a loading indicator if you want, or let the provider handle it
    final success = await auth.updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      username: _usernameController.text.trim(),
      interests: _selectedInterests,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully!"),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Update failed: ${auth.errorMessage}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _editField(
    String label,
    TextEditingController controller, {
    String? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF10B981)),
          ),
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
          Text(
            value,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // (Keep your _sectionHeader, _arrowTile, and _buildDangerZone methods from the previous code)

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _switchTile(String t, String s, bool v, Function(bool) onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        t,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(
        s,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Switch(
        value: v,
        onChanged: onChanged,
        activeColor: const Color(0xFF10B981),
      ),
    );
  }

  Widget _arrowTile(String t, String s) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        t,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(
        s,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
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
          const Text(
            "Danger Zone",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => provider.deleteAllTrips(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text(
                    "Delete All Trips",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    elevation: 0,
                  ),
                  child: const Text(
                    "Delete Account",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
