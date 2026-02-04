import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/data/services/itinerary_service.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_detail_screen.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/public_trip_card.dart';
import 'package:tour_guide/features/user/logic/saved_provider.dart';

// Service Imports
import '../../data/services/destination_service.dart';

// Model Imports
import '../../data/models/destination.dart';

// Widget Imports
import '../widgets/destination_card.dart';

// 1. Define the Enum outside the class
enum ExploreTab { destinations, expertPlans, community }

class DestinationListScreen extends StatefulWidget {
  const DestinationListScreen({super.key});

  @override
  State<DestinationListScreen> createState() => _DestinationListScreenState();
}

class _DestinationListScreenState extends State<DestinationListScreen> {
  // 1. Data Lists
  List<Destination> _destinations = [];
  List<Itinerary> _itineraries = [];

  // 2. UI States
  bool _isLoading = true;
  ExploreTab _selectedTab = ExploreTab.destinations;
  Timer? _debounce;

  // 3. Filter States
  String _searchQuery = "";
  List<String> _appliedTags = [];
  String _appliedBudget = "Any budget";
  // final String _sortBy = "Name";

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

  // In DestinationListScreen.dart, update the _refreshData method:

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<ItineraryProvider>();

      switch (_selectedTab) {
        case ExploreTab.destinations:
          final data = (_searchQuery.isEmpty && _appliedTags.isEmpty)
              ? await DestinationService.popular()
              : await DestinationService.getFiltered(
                  search: _searchQuery,
                  tags: _appliedTags,
                );
          setState(() {
            _destinations = data.map((map) {
              return map;
            }).toList();
          });
          break;

        case ExploreTab.expertPlans:
          // Fetch expert plans
          final data = await ItineraryService.getExpertTemplates();

          // Add them to provider so likes/saves can be tracked
          for (final itinerary in data) {
            if (!provider.publicPlans.any((it) => it.id == itinerary.id)) {
              provider.updateItineraryInAllLists(itinerary);
            }
          }

          // Store in local state
          setState(() => _itineraries = data);
          break;

        case ExploreTab.community:
          await provider.fetchPublicPlans();
          if (mounted) {
            setState(() {
              _itineraries = provider.publicPlans;
            });
          }
          break;
      }

      // Also refresh saved status
      final savedProvider = context.read<SavedProvider>();
      await savedProvider.fetchSavedItineraries();
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

  /// Sync Expert Plans with the latest state from provider
  void _syncExpertPlansWithProvider(ItineraryProvider provider) {
    for (int i = 0; i < _itineraries.length; i++) {
      final itinerary = _itineraries[i];

      // Check if this itinerary exists in provider with updated state
      final updatedItinerary = provider.publicPlans.firstWhere(
        (it) => it.id == itinerary.id,
        orElse: () => itinerary,
      );

      // If different, update local state
      if (updatedItinerary.isLikedByCurrentUser !=
              itinerary.isLikedByCurrentUser ||
          updatedItinerary.likeCount != itinerary.likeCount ||
          updatedItinerary.isSavedByCurrentUser !=
              itinerary.isSavedByCurrentUser) {
        _itineraries[i] = updatedItinerary;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ItineraryProvider>(
      builder: (context, provider, child) {
        // Sync expert plans whenever provider changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_selectedTab == ExploreTab.expertPlans &&
              _itineraries.isNotEmpty) {
            _syncExpertPlansWithProvider(provider);
          }
        });

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Explore',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
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
                        child: CircularProgressIndicator(
                          color: Color(0xFF009688),
                        ),
                      )
                    : _buildGrid(),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- HELPER WIDGETS ---
  // In DestinationListScreen.dart, modify the _buildGrid method:

  Widget _buildGrid() {
    final bool isDest = _selectedTab == ExploreTab.destinations;
    final screenWidth = MediaQuery.of(context).size.width;

    // Add Consumer to listen to ItineraryProvider changes
    return Consumer<ItineraryProvider>(
      builder: (context, provider, child) {
        // When in expert or community tabs, use data from provider or local state
        List<Itinerary> displayedItineraries = _itineraries;

        // If we're on community tab, always use provider's public plans
        if (_selectedTab == ExploreTab.community) {
          displayedItineraries = provider.publicPlans;
        }

        // Responsive grid configuration... (keep existing code)
        int crossAxisCount;
        double childAspectRatio;
        double crossAxisSpacing;
        double mainAxisSpacing;

        if (screenWidth < 600) {
          crossAxisCount = 1;
          childAspectRatio = isDest ? 0.7 : 1.3;
          crossAxisSpacing = 16;
          mainAxisSpacing = 16;
        } else if (screenWidth < 900) {
          crossAxisCount = 2;
          childAspectRatio = isDest ? 0.65 : 1.2;
          crossAxisSpacing = 20;
          mainAxisSpacing = 20;
        } else {
          crossAxisCount = 3;
          childAspectRatio = isDest ? 0.6 : 1.1;
          crossAxisSpacing = 24;
          mainAxisSpacing = 24;
        }

        return GridView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth < 600 ? 16 : 24,
            vertical: 16,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
          ),
          itemCount: isDest
              ? _destinations.length
              : displayedItineraries.length,
          itemBuilder: (context, index) {
            if (isDest) {
              return DestinationCard(destination: _destinations[index]);
            } else {
              final itinerary = displayedItineraries[index];

              // ALWAYS get the latest from provider (this fixes the issue)
              final latestItinerary = provider.publicPlans.firstWhere(
                (it) => it.id == itinerary.id,
                orElse: () {
                  // If not in public plans, check if we need to add it (for Expert Plans)
                  if (_selectedTab == ExploreTab.expertPlans &&
                      !provider.publicPlans.any(
                        (it) => it.id == itinerary.id,
                      )) {
                    // Add this expert plan to provider so likes are tracked
                    provider.updateItineraryInAllLists(itinerary);
                  }
                  return itinerary;
                },
              );

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItineraryDetailScreen(
                        itinerary: latestItinerary,
                        isReadOnly: _selectedTab == ExploreTab.expertPlans,
                      ),
                    ),
                  );
                },
                child: PublicTripCard(itinerary: latestItinerary),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    final bool isDest = _selectedTab == ExploreTab.destinations;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: isDest ? "Search destinations..." : "Search trips...",
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
          if (isDest) _buildIconButton(Icons.tune, _showFilterModal),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _toggleButton("Destinations", ExploreTab.destinations),
          const SizedBox(width: 8),
          _toggleButton("Expert Plans", ExploreTab.expertPlans),
          const SizedBox(width: 8),
          _toggleButton(
            "Public Trips",
            ExploreTab.community,
            count: _selectedTab == ExploreTab.community
                ? _itineraries.length
                : null,
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, ExploreTab tab, {int? count}) {
    final bool isSelected = _selectedTab == tab;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() => _selectedTab = tab);
        if (tab == ExploreTab.expertPlans) {
          // Sync with provider when switching to Expert Plans
          final provider = context.read<ItineraryProvider>();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _syncExpertPlansWithProvider(provider);
          });
        }
        _refreshData();
      },
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
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF009688) : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    final bool isDest = _selectedTab == ExploreTab.destinations;
    int count = isDest ? _destinations.length : _itineraries.length;
    String type = isDest ? 'destinations' : 'trips';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "$count $type found",
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

  // Widget _buildPublicTripsTab() {
  //   return Consumer<ItineraryProvider>(
  //     builder: (context, provider, child) {
  //       if (provider.isPublicLoading) {
  //         return const Center(child: CircularProgressIndicator());
  //       }

  //       if (provider.publicPlans.isEmpty) {
  //         return _buildEmptyState(
  //           icon: Icons.public_off,
  //           message: "No public trips yet. Be the first to share one!",
  //         );
  //       }

  //       return RefreshIndicator(
  //         onRefresh: () => provider.fetchPublicPlans(),
  //         child: ListView.builder(
  //           padding: const EdgeInsets.all(16),
  //           itemCount: provider.publicPlans.length,
  //           itemBuilder: (context, index) {
  //             final trip = provider.publicPlans[index];
  //             return PublicTripCard(
  //               itinerary: trip,
  //             ); // We will build this card next
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

  // Widget _buildEmptyState({required IconData icon, required String message}) {
  //   return Center(
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Icon(icon, size: 64, color: Colors.grey.shade300),
  //         const SizedBox(height: 16),
  //         Text(
  //           message,
  //           textAlign: TextAlign.center,
  //           style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
  //         ),
  //       ],
  //     ),
  //   );
  // }
} // End of class
