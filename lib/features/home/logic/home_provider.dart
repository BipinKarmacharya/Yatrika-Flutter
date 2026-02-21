import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/interest/logic/interest_provider.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/data/services/itinerary_service.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_screen.dart';
import 'package:tour_guide/features/plan/data/model/ml_models.dart';
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
    DateTime startDate = DateTime.now();
    final text = rawText.toLowerCase();

    // Extract city, days, budget
    String city = _extractCity(text);
    int days = _extractDays(text);
    String budget = _extractBudget(text);
    if (text.contains("tomorrow")) startDate = startDate.add(const Duration(days: 1));

    // Get user-selected interests
    final interestProv = Provider.of<InterestProvider>(context, listen: false);
    List<String> userInterests = interestProv.all
        .where((i) => interestProv.selectedIds.contains(i.id))
        .map((i) => i.name)
        .toList();
    if (userInterests.isEmpty) userInterests = ["Sightseeing", "Adventure"];

    // 1️⃣ Call ML Service to get prediction
    final MLPredictResponse mlResponse = await MLService.getPrediction(
      city: city,
      budget: budget,
      interests: userInterests,
      days: days,
    );

    if (!context.mounted) return;

    // 2️⃣ Convert MLPredictResponse -> Map<String, List<String>> for the timeline UI
    final Map<String, List<String>> itineraryMap = {
      for (var daily in mlResponse.dailyPlans)
        'Day ${daily.day}': daily.places,
    };

    // 3️⃣ Navigate to ItineraryScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItineraryScreen(
          itinerary: mlResponse,
          startDate: startDate,
          budget: budget,
          selectedVibes: userInterests,
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