import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:tour_guide/core/api/api_client.dart';

class SavedService {
  static const String _basePath = '/api/v1/itineraries';

  /// Save an itinerary
  static Future<Map<String, dynamic>> saveItinerary(int itineraryId) async {
    try {
      final response = await ApiClient.post('$_basePath/$itineraryId/save');
      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error saving itinerary: $e");
      throw Exception('Failed to save itinerary: $e');
    }
  }

  /// Unsave an itinerary
  static Future<Map<String, dynamic>> unsaveItinerary(int itineraryId) async {
    try {
      final response = await ApiClient.delete('$_basePath/$itineraryId/save');
      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error unsaving itinerary: $e");
      throw Exception('Failed to unsave itinerary: $e');
    }
  }

  /// Check if an itinerary is saved
  static Future<bool> isItinerarySaved(int itineraryId) async {
    try {
      // Note: You'll need to create this endpoint in backend
      // For now, we'll rely on the provider's cache
      return false;
    } catch (e) {
      debugPrint("Error checking saved status: $e");
      return false;
    }
  }

  /// Get all saved itineraries for current user
  static Future<List<Map<String, dynamic>>> getMySavedItineraries() async {
    try {
      // You need to create this endpoint in backend
      // For now, we'll fetch from /api/v1/saved or similar
      final response = await ApiClient.get('/api/v1/saved/my-saved');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching saved itineraries: $e");
      return [];
    }
  }

  /// Get saved items by type (if you have multiple types: destinations, itineraries, etc.)
  static Future<List<Map<String, dynamic>>> getSavedByType(String type) async {
    try {
      final response = await ApiClient.get('/api/v1/saved/by-type/$type');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching saved items by type: $e");
      return [];
    }
  }
}