import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ItineraryMapScreen extends StatelessWidget {
  final List activities;
  const ItineraryMapScreen({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    // Convert your activity data to LatLng points
    final points = activities.map((act) {
      final dest = act['destination'];
      return LatLng(
        (dest['latitude'] as num).toDouble(),
        (dest['longitude'] as num).toDouble(),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Travel Route")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: points.isNotEmpty ? points[0] : const LatLng(0, 0),
          initialZoom: 13.0,
        ),
        children: [
          // 1. The Map Tiles (OpenStreetMap)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.your.app',
          ),

          // 2. The Path (Polylines)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                color: const Color(0xFF009688),
                strokeWidth: 4,
              ),
            ],
          ),

          // 3. Numbered Markers
          MarkerLayer(
            markers: List.generate(points.length, (index) {
              return Marker(
                point: points[index],
                width: 40,
                height: 40,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF009688),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
