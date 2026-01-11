import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/logic/auth_provider.dart';
import '../../auth/ui/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Watch the AuthProvider for changes
    final auth = context.watch<AuthProvider>();

    // 2. If not logged in, show the Guest View
    if (!auth.isLoggedIn) {
      return const _GuestProfileView();
    }

    // 3. Extract user data from provider
    final user = auth.user;
    final firstName = user?.firstName ?? 'User';
    final lastName = user?.lastName ?? '';
    final username = user?.username ?? 'username';
    final email = user?.email ?? 'Not set';
    final phone = user?.phoneNumber ?? 'Add phone';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => auth.checkSession(), // Refresh profile data
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHeader(onLogout: () => auth.logout()),
                const SizedBox(height: 16),
                _ProfileCard(
                  fullName: '$firstName $lastName',
                  username: '@$username',
                ),
                const SizedBox(height: 20),
                const _SectionLabel(title: 'Account Settings'),
                const SizedBox(height: 8),
                _SettingsGroup(
                  children: [
                    ProfileTile(
                      icon: Icons.mail_outline,
                      title: 'Email',
                      subtitle: email,
                    ),
                    ProfileTile(
                      icon: Icons.phone_outlined,
                      title: 'Phone Number',
                      subtitle: phone,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _AboutYouCard(firstName: firstName, lastName: lastName),
                const SizedBox(height: 32),
                Center(
                  child: TextButton.icon(
                    onPressed: () => auth.logout(),
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- LOGGED IN COMPONENTS ---

class _ProfileHeader extends StatelessWidget {
  final VoidCallback onLogout;
  const _ProfileHeader({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Manage your personal info', style: TextStyle(color: AppColors.subtext)),
          ],
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz),
          onSelected: (val) => val == 'logout' ? onLogout() : null,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'logout', child: Text('Logout', style: TextStyle(color: Colors.red))),
          ],
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String fullName;
  final String username;
  const _ProfileCard({required this.fullName, required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(username, style: const TextStyle(color: AppColors.subtext)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(color: AppColors.subtext, fontWeight: FontWeight.bold, fontSize: 13));
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(children: children),
    );
  }
}

class ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const ProfileTile({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}

class _AboutYouCard extends StatelessWidget {
  final String firstName;
  final String lastName;
  const _AboutYouCard({required this.firstName, required this.lastName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 24),
          Text('First Name: $firstName'),
          const SizedBox(height: 8),
          Text('Last Name: $lastName'),
        ],
      ),
    );
  }
}

// --- GUEST VIEW ---

class _GuestProfileView extends StatelessWidget {
  const _GuestProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 320,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
              child: const SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Yatrika', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Spacer(),
                      Text('Your Travel\nJournal Awaits', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.1)),
                      SizedBox(height: 10),
                      Text('Sign in to sync your trips and explore more.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const _FeatureGrid(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("Sign In / Create Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildSocialLoginSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLoginSection() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("or continue with", style: TextStyle(color: AppColors.subtext, fontSize: 12))),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialBtn(icon: Icons.g_mobiledata, color: Colors.red, label: "Google"),
            const SizedBox(width: 20),
            _SocialBtn(icon: Icons.facebook, color: Colors.blue.shade800, label: "Facebook"),
          ],
        ),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _FCard(icon: Icons.auto_awesome, title: "AI Planner"),
        _FCard(icon: Icons.favorite_border, title: "Favorites"),
        _FCard(icon: Icons.public, title: "Community"),
        _FCard(icon: Icons.history, title: "Trip History"),
      ],
    );
  }
}

class _FCard extends StatelessWidget {
  final IconData icon;
  final String title;
  const _FCard({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.stroke)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _SocialBtn({required this.icon, required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.stroke), color: Colors.white),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}