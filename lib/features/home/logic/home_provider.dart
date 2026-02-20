import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/interest/logic/interest_provider.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/data/services/itinerary_service.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_screen.dart';
import 'package:tour_guide/features/plan/data/service/ml_service.dart';
import '../../destination/data/models/destination.dart' as MD;
import '../../destination/data/services/destination_service.dart';
import '../../community/data/models/community_post.dart' as CP;
import '../../community/data/services/community_service.dart';

class HomeProvider with ChangeNotifier {
  List<MD.Destination> featured = [];
  List<Itinerary> recommended = [];
  List<CP.CommunityPost> communityPosts = [];

  Itinerary? activeTrip;
  bool isLoading = true;
  bool isAiPlanning = false;
  String? error;

  // Essential for the Hero Card UI logic
  final Set<int> _dismissedTripIds = {};

  // --- RESTORED: UI Logic for TourBookHome ---

  List<Itinerary> getVisibleTrips(List<Itinerary> myPlans) {
    // Filter out dismissed cards
    List<Itinerary> filtered = myPlans
        .where((trip) => !_dismissedTripIds.contains(trip.id))
        .toList();

    // Sort: Ongoing first, then by date
    filtered.sort((a, b) {
      if (a.status == 'ONGOING' && b.status != 'ONGOING') return -1;
      if (b.status == 'ONGOING' && a.status != 'ONGOING') return 1;

      if (a.startDate != null && b.startDate != null) {
        return a.startDate!.compareTo(b.startDate!);
      }
      return 0;
    });

    return filtered;
  }

  void updateActiveTrip(List<Itinerary> myPlans) {
    if (myPlans.isEmpty) {
      if (activeTrip != null) {
        activeTrip = null;
        notifyListeners();
      }
      return;
    }

    // Logic to pick the primary trip for display
    Itinerary? bestTrip;
    try {
      bestTrip = myPlans.firstWhere((t) => t.status == 'ONGOING');
    } catch (_) {
      try {
        final upcoming = myPlans
            .where((t) => t.startDate != null && t.startDate!.isAfter(DateTime.now()))
            .toList();
        if (upcoming.isNotEmpty) {
          upcoming.sort((a, b) => a.startDate!.compareTo(b.startDate!));
          bestTrip = upcoming.first;
        } else {
          bestTrip = myPlans.firstWhere((t) => t.status == 'DRAFT', orElse: () => myPlans.first);
        }
      } catch (_) {
        bestTrip = myPlans.first;
      }
    }

    if (activeTrip?.id != bestTrip.id || activeTrip?.status != bestTrip.status) {
      activeTrip = bestTrip;
      notifyListeners();
    }
  }

  void dismissTrip(int id) {
    _dismissedTripIds.add(id);
    notifyListeners();
  }

  // --- CORE DATA LOADING ---

  Future<void> loadHomeData(BuildContext context) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        DestinationService.popular(),
        ItineraryService.getRecommended(),
        CommunityService.trending(),
      ]);

      featured = results[0] as List<MD.Destination>;
      recommended = results[1] as List<Itinerary>;
      communityPosts = results[2] as List<CP.CommunityPost>;

      final itProv = Provider.of<ItineraryProvider>(context, listen: false);
      await itProv.fetchMyPlans();
      updateActiveTrip(itProv.myPlans);
    } catch (e) {
      error = "Connection issues.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- UPDATED: SMART AI PLANNING (PREVIEW FLOW) ---

  Future<void> planWithSmartAI(BuildContext context, String rawText) async {
    if (rawText.isEmpty) return;
    isAiPlanning = true;
    notifyListeners();

    try {
      final text = rawText.toLowerCase();
      DateTime startDate = DateTime.now();

      // Extraction
      String city = _extractCity(text);
      int days = _extractDays(text);
      String budget = _extractBudget(text);
      if (text.contains("tomorrow")) {
        startDate = DateTime.now().add(const Duration(days: 1));
      }

      final interestProv = Provider.of<InterestProvider>(context, listen: false);
      List<String> userInterests = interestProv.all
          .where((i) => interestProv.selectedIds.contains(i.id))
          .map((i) => i.name)
          .toList();

      if (userInterests.isEmpty) userInterests = ["Sightseeing", "Adventure"];

      // 1. Get prediction from ML
      final prediction = await MLService.getPrediction(
        city: city,
        budget: budget,
        interests: userInterests,
        days: days,
      );

      if (!context.mounted) return;

      // 2. Push to the PREVIEW screen (ItineraryScreen)
      // Note: We don't save to DB yet. That happens in ItineraryScreen!
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ItineraryScreen(
            itineraryData: prediction,
            city: city,
            days: days,
            budget: budget,
            interests: userInterests,
            startDate: startDate,
          ),
        ),
      );

    } catch (e) {
      error = "Could not generate plan.";
      debugPrint("AI Error: $e");
    } finally {
      isAiPlanning = false;
      notifyListeners();
    }
  }

  // Parsing Helpers
  String _extractCity(String text) {
    if (text.contains("pokhara")) return "Pokhara";
    if (text.contains("chitwan")) return "Chitwan";
    if (text.contains("butwal")) return "Butwal";
    return "Kathmandu";
  }

  int _extractDays(String text) {
    final match = RegExp(r'(\d+)\s*day').firstMatch(text);
    return match != null ? int.parse(match.group(1)!) : 3;
  }

  String _extractBudget(String text) {
    if (text.contains("cheap") || text.contains("low")) return "Low";
    if (text.contains("luxury") || text.contains("high")) return "High";
    return "Medium";
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:tour_guide/features/interest/logic/interest_provider.dart';
// import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
// import 'package:tour_guide/features/itinerary/data/services/itinerary_service.dart';
// import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
// import 'package:tour_guide/features/plan/data/service/ml_service.dart';
// import 'package:tour_guide/features/plan/logic/trip_creator_provider.dart';
// import '../../destination/data/models/destination.dart' as MD;
// import '../../destination/data/services/destination_service.dart';
// import '../../community/data/models/community_post.dart' as CP;
// import '../../community/data/services/community_service.dart';

// class HomeProvider with ChangeNotifier {
//   // Data Lists
//   List<MD.Destination> featured = [];
//   List<Itinerary> recommended = [];
//   List<CP.CommunityPost> communityPosts = [];

//   // New: Smart Trip State
//   Itinerary? activeTrip; // For the 'ONGOING' status
//   bool isLoading = true;
//   bool isAiPlanning = false; // Separate loader for the search bar
//   String? error;

//   final Set<int> _dismissedTripIds = {};

//   // This is what the UI will actually show
//   List<Itinerary> getVisibleTrips(List<Itinerary> myPlans) {
//     // 1. Filter
//     List<Itinerary> filtered = myPlans
//         .where((trip) => !_dismissedTripIds.contains(trip.id))
//         .toList();

//     // 2. Sort
//     filtered.sort((a, b) {
//       if (a.status == 'ONGOING' && b.status != 'ONGOING') return -1;
//       if (b.status == 'ONGOING' && a.status != 'ONGOING') return 1;

//       if (a.startDate != null && b.startDate != null) {
//         return a.startDate!.compareTo(b.startDate!);
//       }
//       return 0;
//     });

//     return filtered;
//   }

//   void dismissTrip(int id) {
//     _dismissedTripIds.add(id);
//     notifyListeners();
//   }

//   void resetDismissals() {
//     _dismissedTripIds.clear();
//     notifyListeners();
//   }

//   Future<void> loadHomeData(BuildContext context) async {
//     _dismissedTripIds.clear();
//     isLoading = true;
//     error = null;
//     notifyListeners();

//     try {
//       final results = await Future.wait([
//         DestinationService.popular(),
//         ItineraryService.getRecommended(),
//         CommunityService.trending(),
//       ]);

//       featured = results[0] as List<MD.Destination>;
//       recommended = results[1] as List<Itinerary>;
//       communityPosts = results[2] as List<CP.CommunityPost>;

//       // logic to find YOUR personal trips
//       final itProv = Provider.of<ItineraryProvider>(context, listen: false);

//       // Ensure we have the latest private plans
//       await itProv.fetchMyPlans();

//       // Prioritize showing an ONGOING trip, then the nearest UPCOMING trip
//       final myTrips = itProv.myPlans;
//       if (myTrips.isNotEmpty) {
//         activeTrip = myTrips.firstWhere(
//           (t) => t.status == 'ONGOING',
//           orElse: () => myTrips.firstWhere(
//             (t) => t.status == 'DRAFT' || t.status == 'UPCOMING',
//             orElse: () => myTrips.first,
//           ),
//         );
//       } else {
//         activeTrip = null;
//       }
//     } catch (e) {
//       error = "Connection issues.";
//       debugPrint("Home Data Error: $e");
//     } finally {
//       isLoading = false;
//       notifyListeners();
//     }
//   }

//   Itinerary? _findBestUserTrip(List<Itinerary> trips) {
//     if (trips.isEmpty) return null;

//     try {
//       // Find Ongoing
//       return trips.firstWhere((t) => t.status == 'ONGOING');
//     } catch (_) {
//       try {
//         // Find Upcoming (trips starting in the future)
//         final upcoming = trips
//             .where(
//               (t) =>
//                   t.startDate != null && t.startDate!.isAfter(DateTime.now()),
//             )
//             .toList();

//         if (upcoming.isNotEmpty) {
//           upcoming.sort((a, b) => a.startDate!.compareTo(b.startDate!));
//           return upcoming.first;
//         }

//         // Fallback to latest Draft
//         return trips.firstWhere((t) => t.status == 'DRAFT');
//       } catch (_) {
//         return null;
//       }
//     }
//   }

//   Future<void> planWithAI(BuildContext context, String prompt) async {
//     if (prompt.isEmpty) return;

//     isAiPlanning = true;
//     notifyListeners();

//     try {
//       // 1. Simulate AI Processing (You'll replace this with your Gemini/OpenAI API call later)
//       await Future.delayed(const Duration(seconds: 2));
//       debugPrint("AI is generating plan for: $prompt");

//       // 2. Access the Trip Creator to save this as a real trip
//       final tripCreator = Provider.of<TripCreatorProvider>(
//         context,
//         listen: false,
//       );

//       // We initialize a new trip based on the prompt
//       tripCreator.initNewTrip(
//         title:
//             "Trip to ${prompt.split(' ').last}", // Simple logic: take last word as destination
//         totalDays: 3,
//       );

//       // 3. Refresh data so the Hero Card sees the new Draft
//       await loadHomeData(context);

//       // Optional: Show a success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("AI Trip Draft created! Check your hero card."),
//         ),
//       );
//     } catch (e) {
//       error = "AI failed to generate plan.";
//       debugPrint("AI Error: $e");
//     } finally {
//       isAiPlanning = false;
//       notifyListeners();
//     }
//   }

//   // Add this method inside your HomeProvider class
//   void updateActiveTrip(List<Itinerary> myPlans) {
//     if (myPlans.isEmpty) {
//       if (activeTrip != null) {
//         activeTrip = null;
//         notifyListeners();
//       }
//       return;
//     }

//     // Use your existing _findBestUserTrip logic to pick the right one
//     final bestTrip = _findBestUserTrip(myPlans);

//     // Only notify if the trip object has actually changed to prevent infinite loops
//     if (activeTrip?.id != bestTrip?.id ||
//         activeTrip?.status != bestTrip?.status) {
//       activeTrip = bestTrip;
//       notifyListeners();
//     }
//   }

//   // Inside HomeProvider.dart

//   Future<void> planWithSmartAI(BuildContext context, String rawText) async {
//     if (rawText.isEmpty) return;
//     isAiPlanning = true;
//     notifyListeners();
//     DateTime startDate = DateTime.now();

//     try {
//       // 1. EXTRACTION LOGIC (The "Bridge")
//       final text = rawText.toLowerCase();

//       // Extract City (Matches your supported 4 cities)
//       String city = "Kathmandu"; // Default
//       if (text.contains("pokhara")) city = "Pokhara";
//       if (text.contains("chitwan")) city = "Chitwan";
//       if (text.contains("butwal")) city = "Butwal";

//       if (text.contains("tomorrow")) {
//         startDate = DateTime.now().add(const Duration(days: 1));
//       }

//       // Extract Days (Looks for "X days" or just a number)
//       int days = 3; // Default
//       final dayMatch = RegExp(r'(\d+)\s*day').firstMatch(text);
//       if (dayMatch != null) days = int.parse(dayMatch.group(1)!);

//       // Extract Budget
//       String budget = "Medium"; // Default
//       if (text.contains("cheap") || text.contains("low")) budget = "Low";
//       if (text.contains("luxury") || text.contains("high")) budget = "High";

//       // 2. INTEREST INJECTION (The "Vibe" from Profile)
//       // We grab interest names from your InterestProvider
//       final interestProv = Provider.of<InterestProvider>(
//         context,
//         listen: false,
//       );
//       List<String> userInterests = interestProv.all
//           .where((i) => interestProv.selectedIds.contains(i.id))
//           .map((i) => i.name)
//           .toList();

//       // Fallback if user has no interests selected
//       if (userInterests.isEmpty) userInterests = ["Sightseeing", "Adventure"];

//       // 3. CALL ML SERVICE
//       final prediction = await MLService.getPrediction(
//         city: city,
//         budget: budget,
//         interests: userInterests,
//         days: days,
//       );

//       // 4. SAVE & NAVIGATE
//       // This calls your Spring Boot 'save' endpoint which creates the Itinerary in DB
//       final savedTrip = await MLService.savePlan(
//         city: city,
//         budget: budget,
//         interests: userInterests,
//         days: days,
//         itineraryData: prediction,
//         startDate: startDate,
//       );

//       // 5. Refresh Home & Notify User
//       await loadHomeData(
//         context,
//       ); // This will now show the new trip in DynamicHero!

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Generated a $days-day $budget trip to $city!")),
//       );
//     } catch (e) {
//       error = "Could not generate plan.";
//       debugPrint("AI Search Error: $e");
//     } finally {
//       isAiPlanning = false;
//       notifyListeners();
//     }
//   }
// }
