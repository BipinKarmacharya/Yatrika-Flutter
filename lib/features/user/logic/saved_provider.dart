import 'package:flutter/foundation.dart';
import 'package:tour_guide/core/api/api_client.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';

class SavedProvider extends ChangeNotifier {
  List<Itinerary> _savedItems = [];
  bool _isLoading = false;
  final Map<int, bool> _savedStatusCache = {}; // itineraryId -> isSaved

  List<Itinerary> get savedItems => _savedItems;
  bool get isLoading => _isLoading;

  // Fetch all saved itineraries
  Future<void> fetchSavedItineraries() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.get('/api/v1/itineraries/saved/my-saved');
      final List<dynamic> data = response;
      
      _savedItems = data.map((json) => Itinerary.fromJson(json)).toList();
      
      // Update cache
      for (var item in _savedItems) {
        _savedStatusCache[item.id] = true;
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
      final response = await ApiClient.post('/api/v1/itineraries/$itineraryId/save');
      
      // Add to local list if not already there
      if (!_savedStatusCache.containsKey(itineraryId)) {
        // You might want to fetch the saved item details here
        // For now, we'll just update the cache
        _savedStatusCache[itineraryId] = true;
        
        // Refresh saved items list
        await fetchSavedItineraries();
      }
      
      return true;
    } catch (e) {
      debugPrint("Error saving itinerary: $e");
      return false;
    }
  }

  // Unsave an itinerary
  Future<bool> unsaveItinerary(int itineraryId) async {
    try {
      await ApiClient.delete('/api/v1/itineraries/$itineraryId/save');
      
      // Remove from cache
      _savedStatusCache.remove(itineraryId);
      
      // Remove from local list
      _savedItems.removeWhere((item) => item.id == itineraryId);
      
      notifyListeners();
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