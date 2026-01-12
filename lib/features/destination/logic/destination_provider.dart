// lib/features/destination/logic/destination_provider.dart
import 'package:flutter/material.dart';
import 'package:tour_guide/features/destination/data/models/destination.dart';
import '../data/repositories/destination_repository.dart';

class DestinationProvider with ChangeNotifier {
  final DestinationRepository _repository;
  List<Destination> _destinations = [];
  bool _isLoading = false;
  
  DestinationProvider(this._repository);
  
  List<Destination> get destinations => _destinations;
  bool get isLoading => _isLoading;
  
  Future<void> loadDestinations() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _destinations = await _repository.getPopularDestinations();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}