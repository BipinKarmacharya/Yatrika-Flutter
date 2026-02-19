import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/interest/logic/interest_provider.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
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

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final interestProvider = context.read<InterestProvider>();

    _firstNameController = TextEditingController(
      text: auth.user?.firstName ?? "",
    );
    _lastNameController = TextEditingController(
      text: auth.user?.lastName ?? "",
    );
    _usernameController = TextEditingController(
      text: auth.user?.username ?? "",
    );

    // ✅ correct call
    interestProvider.load(preselectedIds: auth.user?.interestIds ?? []);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  bool _isDirty() {
    final auth = context.read<AuthProvider>();
    final interestProvider = context.read<InterestProvider>();
    final user = auth.user;

    if (user == null) return false;

    final nameChanged =
        _firstNameController.text != (user.firstName ?? "") ||
        _lastNameController.text != (user.lastName ?? "");

    final usernameChanged = _usernameController.text != user.username;

    final interestsChanged =
        !Set.from(user.interestIds).containsAll(interestProvider.selectedIds) ||
        !Set.from(interestProvider.selectedIds).containsAll(user.interestIds);

    return nameChanged || usernameChanged || interestsChanged;
  }

  void _resetChanges() {
    final auth = context.read<AuthProvider>();
    final interestProvider = context.read<InterestProvider>();
    final user = auth.user;

    if (user == null) return;

    setState(() {
      _firstNameController.text = user.firstName ?? "";
      _lastNameController.text = user.lastName ?? "";
      _usernameController.text = user.username;
    });

    interestProvider.reset(user.interestIds);
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.watch<AuthProvider>();
    final interestProvider = context.watch<InterestProvider>();

    if (!authProvider.isLoggedIn) return const SizedBox.shrink();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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

            // 🔥 Interests from backend (NO hardcoding)
            Wrap(
              spacing: 8,
              children: interestProvider.all.map((interest) {
                final isSelected = interestProvider.selectedIds.contains(
                  interest.id,
                );

                return FilterChip(
                  label: Text(
                    interest.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? const Color(0xFF10B981)
                          : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => interestProvider.toggle(interest.id),
                  backgroundColor: Colors.grey[100],
                  selectedColor: const Color(0xFF10B981).withOpacity(0.1),
                  checkmarkColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF10B981)
                          : Colors.transparent,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            _sectionHeader(Icons.settings_suggest_outlined, "Account Actions"),
            ListTile(
              onTap: () async {
                await authProvider.logout(context);
                if (mounted) Navigator.pop(context);
              },
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                "Sign Out",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
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

  Widget _buildActionPopup(AuthProvider auth) {
    final interestProvider = context.read<InterestProvider>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
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
              onPressed: () async {
                final success = await auth.updateProfile(
                  firstName: _firstNameController.text.trim(),
                  lastName: _lastNameController.text.trim(),
                  username: _usernameController.text.trim(),
                  interestIds: interestProvider.selectedIds,
                );

                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Profile updated"),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Save Changes"),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- helpers ----------

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF10B981)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
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
        decoration: InputDecoration(labelText: label, prefixText: prefix),
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
          Text(value, style: TextStyle(fontSize: 15, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, ProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Danger Zone",
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: ListTile(
            title: const Text(
              "Delete All Trips",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text("This action cannot be undone."),
            leading: provider.isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.red,
                    ),
                  )
                : const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () => _confirmDeleteAll(context, provider),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteAll(BuildContext context, ProfileProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Consumer<ProfileProvider>(
        // ✅ Add Consumer here
        builder: (context, profileProvider, child) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 10),
                Text("Delete All Trips?"),
              ],
            ),
            content: const Text(
              "This action is permanent and will remove every trip from your 'My Trips' list. Expert plans and community trips you've copied will also be lost.",
            ),
            actions: [
              TextButton(
                onPressed: profileProvider.isDeleting
                    ? null
                    : () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: profileProvider.isDeleting
                    ? null
                    : () async {
                        final success = await profileProvider.deleteAllTrips();

                        if (ctx.mounted) Navigator.pop(ctx);

                        if (success && context.mounted) {
                          context.read<ItineraryProvider>().fetchMyPlans();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("All trips have been wiped clean."),
                              backgroundColor: Colors.black87,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: profileProvider.isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Delete All",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
