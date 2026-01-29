import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ItineraryMapScreen extends StatefulWidget {
  final List activities;
  const ItineraryMapScreen({super.key, required this.activities});

  @override
  State<ItineraryMapScreen> createState() => _ItineraryMapScreenState();
}

class _ItineraryMapScreenState extends State<ItineraryMapScreen> {
  final MapController _mapController = MapController();
  List<LatLng> roadPoints = [];
  bool isLoading = true;
  String currentProfile = 'driving-car';
  String? travelDistance;
  String? travelDuration;

  @override
  void initState() {
    super.initState();
    _fetchFullRoute(currentProfile);
  }

  // Helper to get the correct icon for the summary card
  IconData _getProfileIcon() {
    if (currentProfile == 'foot-walking') return Icons.directions_walk;
    if (currentProfile == 'cycling-regular') return Icons.directions_bike;
    return Icons.directions_car;
  }

  Future<void> _fetchFullRoute(String profile) async {
    setState(() {
      isLoading = true;
      currentProfile = profile;
    });

    // 1. GET A KEY: Go to https://openrouteservice.org/, sign up (free),
    // and paste the key here.
    const String apiKey =
        "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImExNzIwNTdkZjc3MzRkYjE5ODllNTI3OTA2OWVhZTYwIiwiaCI6Im11cm11cjY0In0=";

    try {
      if (widget.activities.length < 2) {
        setState(() => isLoading = false);
        return;
      }

      final List<List<double>> coordinates = widget.activities.map((act) {
        final dest = act['destination'];
        return [
          (dest['longitude'] as num).toDouble(),
          (dest['latitude'] as num).toDouble(),
        ];
      }).toList();

      String orsProfile = profile == 'driving-car'
          ? 'driving-car'
          : profile == 'foot-walking'
          ? 'foot-walking'
          : 'cycling-regular';

      final url =
          'https://api.openrouteservice.org/v2/directions/$orsProfile/geojson';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: json.encode({
          "coordinates": coordinates,
          "preference": "shortest",
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List coords = data['features'][0]['geometry']['coordinates'];
        final summary = data['features'][0]['properties']['summary'];

        setState(() {
          roadPoints = coords
              .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();
          travelDistance =
              "${(summary['distance'] / 1000).toStringAsFixed(1)} km";
          int mins = (summary['duration'] / 60).round();
          travelDuration = mins > 60
              ? "${(mins / 60).toStringAsFixed(1)} hrs"
              : "$mins mins";
          isLoading = false;
        });

        // Zoom to fit
        if (roadPoints.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(roadPoints);
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
          );
        }
      } else {
        // API returned an error (likely invalid key or quota)
        debugPrint("ORS Error: ${response.statusCode} - ${response.body}");
        _handleRoutingFailure();
      }
    } catch (e) {
      debugPrint("Routing Exception: $e");
      _handleRoutingFailure();
    }
  }

  // Fallback: If API fails, show straight lines so it's not stuck loading
  void _handleRoutingFailure() {
    setState(() {
      roadPoints =
          []; // This forces the UI to use 'stopPoints' (straight lines)
      travelDistance = "Route data unavailable";
      travelDuration = "";
      isLoading = false;
    });

    // Wrap in addPostFrameCallback to prevent the lifecycle crash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Using straight lines (Check API Key/Internet)"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  void _showDestinationDetails(Map<String, dynamic> activity) {
    final dest = activity['destination'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dest['name'] ?? "Destination",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                activity['title'] ?? "Scheduled Activity",
                style: TextStyle(
                  color: Colors.teal[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              if (activity['notes'] != null)
                Text(
                  activity['notes'],
                  style: TextStyle(color: Colors.grey[600]),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stopPoints = widget.activities.map((act) {
      final dest = act['destination'];
      return LatLng(
        (dest['latitude'] as num).toDouble(),
        (dest['longitude'] as num).toDouble(),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Route Explorer"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: stopPoints.isNotEmpty
                  ? stopPoints[0]
                  : const LatLng(0, 0),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yatrika.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: roadPoints.isNotEmpty ? roadPoints : stopPoints,
                    color: const Color(0xFF009688),
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                ],
              ),
              MarkerLayer(
                markers: List.generate(stopPoints.length, (index) {
                  return Marker(
                    point: stopPoints[index],
                    width: 45,
                    height: 45,
                    child: GestureDetector(
                      onTap: () =>
                          _showDestinationDetails(widget.activities[index]),
                      child: _buildNumberedMarker(index + 1),
                    ),
                  );
                }),
              ),
            ],
          ),

          // TRANSPORT MODE TOGGLE
          Positioned(
            top: 15,
            left: 20,
            right: 20,
            child: _buildTransportToggle(),
          ),

          // TRAVEL INFO CARD
          if (travelDistance != null && !isLoading)
            Positioned(
              bottom: 25,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _getProfileIcon(),
                      color: const Color(0xFF009688),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          travelDuration!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          travelDistance!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // RECENTER BUTTON
          Positioned(
            bottom: 25,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                if (stopPoints.isNotEmpty) {
                  final bounds = LatLngBounds.fromPoints(stopPoints);
                  _mapController.fitCamera(
                    CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(50),
                    ),
                  );
                }
              },
              child: const Icon(Icons.my_location, color: Color(0xFF009688)),
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF009688)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransportToggle() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _modeIconButton(Icons.directions_car, 'driving-car'),
            const SizedBox(width: 15),
            _modeIconButton(Icons.directions_walk, 'foot-walking'),
            const SizedBox(width: 15),
            _modeIconButton(Icons.directions_bike, 'cycling-regular'),
          ],
        ),
      ),
    );
  }

  Widget _modeIconButton(IconData icon, String profile) {
    bool isSelected = currentProfile == profile;
    return GestureDetector(
      onTap: () => _fetchFullRoute(profile),
      child: Icon(
        icon,
        color: isSelected ? const Color(0xFF009688) : Colors.grey[400],
        size: 28,
      ),
    );
  }

  Widget _buildNumberedMarker(int number) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF009688),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
