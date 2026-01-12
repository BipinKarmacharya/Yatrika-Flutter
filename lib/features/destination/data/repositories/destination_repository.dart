// lib/features/destination/data/repositories/destination_repository.dart
import '../models/destination.dart';
import '../services/destination_service.dart';

abstract class IDestinationRepository {
  Future<List<Destination>> getPopularDestinations();
  Future<Destination> getDestinationById(String id);
  Future<List<Destination>> getAllDestinations({int page, int size});
  Future<List<Destination>> searchDestinations(String query);
  Future<List<Destination>> getNearbyDestinations({required double lat, required double lng});
  Future<List<Destination>> getDestinationsByDistrict(String district);
}

class DestinationRepository implements IDestinationRepository {
  final DestinationService _service;

  DestinationRepository(this._service);

  @override
  Future<List<Destination>> getPopularDestinations() async {
    return await DestinationService.popular();
  }

  @override
  Future<Destination> getDestinationById(String id) async {
    return await DestinationService.getById(id);
  }

  @override
  Future<List<Destination>> getAllDestinations({int page = 0, int size = 20}) async {
    return await DestinationService.getAll(page: page, size: size);
  }

  @override
  Future<List<Destination>> searchDestinations(String query) async {
    return await DestinationService.search(query);
  }

  @override
  Future<List<Destination>> getNearbyDestinations({required double lat, required double lng}) async {
    return await DestinationService.nearby(lat: lat, lng: lng);
  }

  @override
  Future<List<Destination>> getDestinationsByDistrict(String district) async {
    return await DestinationService.byDistrict(district);
  }
}