import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/auth/logic/auth_provider.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_detail_screen.dart';

class PlanScreenController {
  final BuildContext context;
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController datesController = TextEditingController();
  final TextEditingController travelersController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();

  PlanScreenController(this.context);

  void dispose() {
    destinationController.dispose();
    datesController.dispose();
    travelersController.dispose();
    budgetController.dispose();
  }

  bool _checkAuth() {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please login to start planning your trip!"),
        ),
      );
      return false;
    }
    return true;
  }

  /// Create a quick empty trip (just title)
  Future<void> createQuickTrip({
    required String destination,
  }) async {
    if (!_checkAuth()) return;

    final provider = context.read<ItineraryProvider>();
    final newTrip = await provider.createQuickTrip(
      title: "Trip to $destination",
      destination: destination,
    );

    if (newTrip != null && context.mounted) {
      _navigateToItineraryDetail(newTrip, isReadOnly: false);
    }
  }

  /// Create a detailed trip with activities
  Future<void> createDetailedTrip({
    required String title,
    required String destination,
    int? totalDays,
    int? travelers,
    double? budget,
    String? notes,
  }) async {
    if (!_checkAuth()) return;

    final provider = context.read<ItineraryProvider>();
    final newTrip = await provider.createDetailedTrip(
      title: title,
      destination: destination,
      totalDays: totalDays,
      travelers: travelers,
      budget: budget,
      notes: notes,
    );

    if (newTrip != null && context.mounted) {
      _navigateToItineraryDetail(newTrip, isReadOnly: false);
    }
  }

  void _navigateToItineraryDetail(dynamic itinerary, {bool isReadOnly = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItineraryDetailScreen(
          itinerary: itinerary,
          isReadOnly: isReadOnly,
        ),
      ),
    );
  }

  /// Clear all form fields
  void clearForm() {
    destinationController.clear();
    datesController.clear();
    travelersController.clear();
    budgetController.clear();
  }
}