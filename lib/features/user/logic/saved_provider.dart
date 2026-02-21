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
      final response = await ApiClient.get(
        '/api/v1/itineraries/saved/my-saved',
      );
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
    _savedStatusCache[itineraryId] = true;
    notifyListeners();

    try {
      // The backend returns the ItineraryResponse here
      final response = await ApiClient.post('/api/v1/itineraries/$itineraryId/save');
      
      // Instead of fetchSavedItineraries() (which triggers loading state),
      // just add the returned object to the list manually.
      final newSavedItem = Itinerary.fromJson(response);
      
      // Check if it already exists to avoid duplicates
      if (!_savedItems.any((item) => item.id == newSavedItem.id)) {
        _savedItems.add(newSavedItem);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _savedStatusCache.remove(itineraryId);
      notifyListeners();
      return false;
    }
  }

  // Unsave an itinerary
  Future<bool> unsaveItinerary(int itineraryId) async {
    // 1. Store the item in case we need to revert
    final index = _savedItems.indexWhere((item) => item.id == itineraryId);
    final Itinerary? removedItem = index != -1 ? _savedItems[index] : null;

    // 2. Optimistic update: Remove immediately from UI
    _savedItems.removeWhere((item) => item.id == itineraryId);
    _savedStatusCache[itineraryId] = false; // Set to false instead of removing
    notifyListeners();

    try {
      // 3. Call API
      await ApiClient.delete('/api/v1/itineraries/$itineraryId/save');
      return true;
    } catch (e) {
      // 4. Revert if API fails
      if (removedItem != null) {
        _savedItems.insert(index, removedItem);
      }
      _savedStatusCache[itineraryId] = true;
      notifyListeners();
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
