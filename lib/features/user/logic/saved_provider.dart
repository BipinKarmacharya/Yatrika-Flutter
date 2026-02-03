import 'package:flutter/foundation.dart';
import 'package:tour_guide/features/user/data/services/saved_service.dart';

class SavedProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _savedItems = [];
  bool _isLoading = false;
  Map<int, bool> _savedStatusCache = {}; // itineraryId -> isSaved

  List<Map<String, dynamic>> get savedItems => _savedItems;
  bool get isLoading => _isLoading;

  // Fetch all saved itineraries
  Future<void> fetchSavedItineraries() async {
    _isLoading = true;
    notifyListeners();

    try {
      _savedItems = await SavedService.getMySavedItineraries();
      // Update cache
      for (var item in _savedItems) {
        final id = item['id'] as int;
        _savedStatusCache[id] = true;
      }
    } catch (e) {
      debugPrint("Error fetching saved itineraries: $e");
      _savedItems = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save an itinerary
  Future<bool> saveItinerary(int itineraryId) async {
    try {
      await SavedService.saveItinerary(itineraryId);
      _savedStatusCache[itineraryId] = true;
      // Refresh saved items list
      await fetchSavedItineraries();
      return true;
    } catch (e) {
      debugPrint("Error saving itinerary: $e");
      return false;
    }
  }

  // Unsave an itinerary
  Future<bool> unsaveItinerary(int itineraryId) async {
    try {
      await SavedService.unsaveItinerary(itineraryId);
      _savedStatusCache.remove(itineraryId);
      // Refresh saved items list
      await fetchSavedItineraries();
      return true;
    } catch (e) {
      debugPrint("Error unsaving itinerary: $e");
      return false;
    }
  }

  // Check if itinerary is saved
  bool isItinerarySaved(int itineraryId) {
    return _savedStatusCache[itineraryId] ?? false;
  }

  // Toggle save status
  Future<bool> toggleSaveStatus(int itineraryId) async {
    final isCurrentlySaved = isItinerarySaved(itineraryId);
    
    if (isCurrentlySaved) {
      return await unsaveItinerary(itineraryId);
    } else {
      return await saveItinerary(itineraryId);
    }
  }

  // Clear saved items (on logout)
  void clear() {
    _savedItems.clear();
    _savedStatusCache.clear();
    notifyListeners();
  }
}