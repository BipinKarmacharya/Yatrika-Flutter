// lib/features/destination/data/mappers/destination_mapper.dart
import 'package:tour_guide/features/destination/data/models/destination.dart';

class DestinationMapper {
  static Destination fromApiResponse(Map<String, dynamic> json) {
    // Custom mapping logic if API response differs from your model
    return Destination.fromJson(json);
  }
}