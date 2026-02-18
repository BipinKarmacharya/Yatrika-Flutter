import 'package:flutter/material.dart';
import 'package:tour_guide/features/interest/data/models/interest.dart';
import 'package:tour_guide/features/interest/data/services/interest_service.dart';

class InterestProvider extends ChangeNotifier {
  List<Interest> _all = [];
  Set<int> _selected = {};

  List<Interest> get all => _all;
  Set<int> get selected => _selected;
  List<int> get selectedIds => _selected.toList();

  /// Load interests from backend
  Future<void> load({List<int> preselectedIds = const []}) async {
    _all = await InterestService.getAll();
    _selected = preselectedIds.toSet();
    notifyListeners();
  }

  void toggle(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  /// Used when user presses "Cancel"
  void reset(List<int> ids) {
    _selected = ids.toSet();
    notifyListeners();
  }
}
