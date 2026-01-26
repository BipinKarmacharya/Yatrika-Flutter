import 'dart:async';
import 'package:flutter/material.dart';

// Service Imports
import '../../data/services/destination_service.dart';
import 'package:tour_guide/features/trips/date/services/trip_service.dart';

// Model Imports
import '../../data/models/destination.dart';
import 'package:tour_guide/features/trips/date/models/trip.dart';

// Widget Imports
import '../widgets/destination_card.dart';
import 'package:tour_guide/features/trips/presentation/widgets/public_trip_card.dart';

class DestinationListScreen extends StatefulWidget {
  const DestinationListScreen({super.key});

  @override
  State<DestinationListScreen> createState() => _DestinationListScreenState();
}

class _DestinationListScreenState extends State<DestinationListScreen> {
  // 1. Data Lists
  List<Destination> _destinations = [];
  List<Trip> _publicTrips = []; // Now uses the Trip model

  // 2. UI States
  bool _isLoading = true;
  bool _isDestinationView = true;
  Timer? _debounce;

  // 3. Filter States (Synced with Backend)
  String _searchQuery = "";
  List<String> _appliedTags = [];
  String _appliedBudget = "Any budget";
  final String _sortBy = "Name";

  final List<String> _availableTags = [
    "Adventure",
    "Beach",
    "Cultural",
    "Food",
    "Hiking",
    "Historical",
    "Mountains",
    "Nature",
    "Nightlife",
    "Wellness",
  ];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Unified fetch method that calls the backend based on current filters
  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      if (_isDestinationView) {
        List<Destination> data;
        // If no filters are active, get the default popular list
        if (_searchQuery.isEmpty &&
            _appliedTags.isEmpty &&
            _appliedBudget == "Any budget") {
          data = await DestinationService.popular();
        } else {
          data = await DestinationService.getFiltered(
            search: _searchQuery,
            tags: _appliedTags,
            budget: _appliedBudget,
            sort: _sortBy,
          );
        }
        setState(() => _destinations = data);
      } else {
        final data = await TripService.getPublicTrips(search: _searchQuery);
        setState(() => _publicTrips = data);
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchQuery = query;
      _refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth < 600 ? 1 : 2;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Explore',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabToggle(),
          _buildResultHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF009688)),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      // Adjusted aspect ratio for the new Trip cards
                      childAspectRatio: _isDestinationView ? 0.65 : 0.82,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _isDestinationView
                        ? _destinations.length
                        : _publicTrips.length,
                    itemBuilder: (context, index) {
                      return _isDestinationView
                          ? DestinationCard(destination: _destinations[index])
                          : PublicTripCard(trip: _publicTrips[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: _isDestinationView
                    ? "Search destinations..."
                    : "Search trips...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_isDestinationView) // Filters only apply to Destinations in this logic
            _buildIconButton(Icons.tune, _showFilterModal),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black54),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildTabToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _toggleButton("Destinations", _isDestinationView, () {
            setState(() => _isDestinationView = true);
            _refreshData();
          }),
          const SizedBox(width: 12),
          _toggleButton("Public Trips", !_isDestinationView, () {
            setState(() => _isDestinationView = false);
            _refreshData();
          }, count: _publicTrips.length),
        ],
      ),
    );
  }

  Widget _toggleButton(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    int? count,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF009688).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF009688) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            if (label == "Public Trips")
              const Icon(
                Icons.explore_outlined,
                size: 18,
                color: Colors.black87,
              ),
            if (label == "Public Trips") const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF009688) : Colors.black87,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF009688)
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    int count = _isDestinationView ? _destinations.length : _publicTrips.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "$count ${_isDestinationView ? 'destinations' : 'public trips'} found",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showFilterModal() {
    List<String> tempTags = List.from(_appliedTags);
    String tempBudget = _appliedBudget;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filters",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setModalState(() {
                          tempTags.clear();
                          tempBudget = "Any budget";
                        }),
                        child: const Text(
                          "Clear All",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Categories",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: _availableTags.map((tag) {
                              final isSelected = tempTags.contains(tag);
                              return FilterChip(
                                label: Text(tag),
                                selected: isSelected,
                                onSelected: (s) => setModalState(
                                  () => s
                                      ? tempTags.add(tag)
                                      : tempTags.remove(tag),
                                ),
                                selectedColor: const Color(
                                  0xFF009688,
                                ).withOpacity(0.1),
                                checkmarkColor: const Color(0xFF009688),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Budget",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          DropdownButton<String>(
                            value: tempBudget,
                            isExpanded: true,
                            items:
                                [
                                      "Any budget",
                                      "Under \$100",
                                      "\$100 - \$200",
                                      "Over \$200",
                                    ]
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) =>
                                setModalState(() => tempBudget = v!),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                      ),
                      onPressed: () {
                        setState(() {
                          _appliedTags = tempTags;
                          _appliedBudget = tempBudget;
                        });
                        _refreshData();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Apply Filters",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
