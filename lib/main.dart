import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:tour_guide/features/explore/presentation/screens/explore_screen.dart';
import 'package:tour_guide/features/home/logic/home_provider.dart';
import 'package:tour_guide/features/user/logic/saved_provider.dart';
import 'package:tour_guide/features/destination/logic/destination_provider.dart';
import 'package:tour_guide/features/home/presentation/screens/home_screen.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:tour_guide/features/plan/logic/trip_creator_provider.dart';
import 'package:tour_guide/features/user/logic/profile_provider.dart';

// Core & Auth Imports
import 'core/theme/app_colors.dart';
import 'core/api/api_client.dart';
import 'core/services/local_notification_service.dart';
import 'features/auth/logic/auth_provider.dart';
import 'features/auth/ui/auth_wrapper.dart'; // ✅ Added this

// Feature Providers
import 'features/community/logic/community_provider.dart';

// Screen Imports
import 'features/community/presentation/screens/community_screen.dart';
import 'features/user/presentation/screens/profile_screen.dart';
import 'features/plan/presentation/screens/plan_screen.dart';
// import 'features/explore/presentation/screens/destination_list_screen.dart';
import 'shared/ui/screens/animated_splash_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Skipping .env load: $e');
  }

  HttpOverrides.global = MyHttpOverrides();

  await ApiClient.init();
  await LocalNotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkSession()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => DestinationProvider()),
        ChangeNotifierProvider(create: (_) => ItineraryProvider()),
        ChangeNotifierProvider(create: (_) => TripCreatorProvider()),
        ChangeNotifierProvider(create: (_) => SavedProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   HttpOverrides.global = MyHttpOverrides();

//   // Initialize ApiClient (Loads token from SharedPreferences)
//   await ApiClient.init();

//   Future<void> main() async {
//     await dotenv.load(fileName: ".env"); // Load the .env file
//     runApp(MyApp());
//   }

//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider<AuthProvider>(
//           create: (_) {
//             final auth = AuthProvider();
//             auth.checkSession(); // Call it explicitly
//             return auth;
//           },
//         ),

//         ChangeNotifierProvider(create: (_) => HomeProvider()),

//         ChangeNotifierProvider(create: (_) => ProfileProvider()),

//         ChangeNotifierProvider<CommunityProvider>(
//           create: (_) => CommunityProvider(),
//         ),

//         ChangeNotifierProvider(create: (_) => DestinationProvider()),

//         ChangeNotifierProvider(create: (_) => ItineraryProvider()),

//         ChangeNotifierProvider(create: (_) => TripCreatorProvider()),

//         ChangeNotifierProvider(create: (_) => SavedProvider()),

//       ],
//       child: const MyApp(),
//     ),
//   );
// }

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yatrika',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        primaryColor: AppColors.primary,
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
        textTheme: GoogleFonts.ubuntuTextTheme(),
        useMaterial3: true,
      ),
      // ✅ Now showing animated splash screen first
      home: const AnimatedSplashScreen(
        duration: Duration(seconds: 3),
        child: AuthWrapper(),
      ),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    TourBookHome(
      onProfileTap: () => setState(() => _currentIndex = 4),
      // onNavigateToDiscover: () => setState(() => _currentIndex = 1),
    ),
    const ExploreScreen(),
    PlanScreen(
      onBack: () => setState(() => _currentIndex = 0),
      onNavigateToDiscover: () => setState(() => _currentIndex = 1),
    ),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: const Color.fromARGB(0, 8, 2, 2),
        color: Colors.white,
        buttonBackgroundColor: AppColors.primary,
        height: 70,
        index: _currentIndex,
        animationDuration: const Duration(milliseconds: 300),
        items: const [
          CurvedNavigationBarItem(
            child: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.add_circle_outline),
            label: 'Plan',
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.article_outlined),
            label: 'Posts',
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
