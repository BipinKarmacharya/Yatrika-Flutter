import 'package:flutter/material.dart';
import '../data/models/destination.dart';
import '../data/services/destination_service.dart';

class DestinationProvider with ChangeNotifier {
  List<Destination> _destinations = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Destination> get destinations => _destinations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch initial popular destinations or search/filter results
  Future<void> fetchDestinations({
    String? search,
    List<String>? tags,
    String? budget,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Logic check: If search/filters are empty, get popular. Else, get filtered.
      final bool isSearchEmpty = (search == null || search.isEmpty);
      final bool isTagsEmpty = (tags == null || tags.isEmpty);
      final bool isBudgetAny = (budget == null || budget == "Any budget");

      if (isSearchEmpty && isTagsEmpty && isBudgetAny) {
        _destinations = await DestinationService.popular();
      } else {
        _destinations = await DestinationService.getFiltered(
          search: search,
          tags: tags,
          budget: budget,
        );
      }
    } catch (e) {
      _errorMessage = "Failed to load destinations. Please try again.";
      debugPrint("DestinationProvider Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Optional: Clear state on logout
  void clear() {
    _destinations = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}

// // lib/features/destination/logic/destination_provider.dart
// import 'package:flutter/material.dart';
// import 'package:tour_guide/features/explore/data/models/destination.dart';
// import '../data/repositories/destination_repository.dart';

// class DestinationProvider with ChangeNotifier {
//   final DestinationRepository _repository;
//   List<Destination> _destinations = [];
//   bool _isLoading = false;
  
//   DestinationProvider(this._repository);
  
//   List<Destination> get destinations => _destinations;
//   bool get isLoading => _isLoading;
  
//   Future<void> loadDestinations() async {
//     _isLoading = true;
//     notifyListeners();
    
//     try {
//       _destinations = await _repository.getPopularDestinations();
//     } catch (e) {
//       // Handle error
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
// }