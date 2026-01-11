import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/main.dart';
import '../logic/auth_provider.dart';
import 'login_screen.dart'; // Ensure this import is correct

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the auth provider for state changes
    final auth = context.watch<AuthProvider>();

    // 1. Show a loader while we are checking the session/token on startup
    if (auth.isLoading && auth.user == null && !auth.isGuest) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. If user is logged in OR has chosen to continue as guest, show the app
    if (auth.isLoggedIn || auth.isGuest) {
      return const MainNavigator();
    }

    // 3. Otherwise, show the Login Screen
    return const LoginScreen();
  }
}