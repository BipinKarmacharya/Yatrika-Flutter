import 'package:flutter/material.dart';
import '../../data/services/destination_service.dart';
import '../../data/models/destination.dart';
import '../widgets/destination_card.dart';

class DestinationListScreen extends StatefulWidget {
  const DestinationListScreen({super.key});

  @override
  State<DestinationListScreen> createState() => _DestinationListScreenState();
}

class _DestinationListScreenState extends State<DestinationListScreen> {
  List<Destination> _allDestinations = [];
  List<Destination> _filteredDestinations = [];
  bool _isLoading = true;

  // 1. APPLIED STATES (What the user actually sees on the list)
  String _searchQuery = "";
  List<String> _appliedTags = [];
  String _appliedBudget = "Any budget";
  String _sortBy = "Name";

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
    "Photography",
    "Relaxation",
    "Romantic",
    "Shopping",
    "Unique",
    "Wellness",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await DestinationService.popular();
      setState(() {
        _allDestinations = data;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredDestinations = _allDestinations.where((dest) {
        // 1. Search Logic (Already case-insensitive)
        final matchesSearch = dest.name.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );

        // 2. Updated Tag Logic (Now case-insensitive)
        final matchesTags =
            _appliedTags.isEmpty ||
            _appliedTags.any(
              (appliedTag) => dest.tags.any(
                (destTag) => destTag.toLowerCase() == appliedTag.toLowerCase(),
              ),
            );

        // 3. Budget Logic
        bool matchesBudget = true;
        if (_appliedBudget == "Under \$100") {
          matchesBudget = dest.cost < 100;
        } else if (_appliedBudget == "\$100 - \$200")
          matchesBudget = dest.cost >= 100 && dest.cost <= 200;
        else if (_appliedBudget == "Over \$200")
          matchesBudget = dest.cost > 200;

        return matchesSearch && matchesTags && matchesBudget;
      }).toList();

      // Sorting Logic
      if (_sortBy == "Name") {
        _filteredDestinations.sort((a, b) => a.name.compareTo(b.name));
      } else if (_sortBy == "Budget: Low to High") {
        _filteredDestinations.sort((a, b) => a.cost.compareTo(b.cost));
      } else if (_sortBy == "Budget: High to Low") {
        _filteredDestinations.sort((a, b) => b.cost.compareTo(a.cost));
      }
    });
  }

  // --- FILTER MODAL LOGIC ---

  void _showFilterModal() {
  List<String> tempTags = List.from(_appliedTags);
  String tempBudget = _appliedBudget;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Crucial for resizing
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            // Use constraints instead of hard height to prevent overflow
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              // Handle bottom padding for keyboards or safe areas
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Wrap to content size
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (Fixed at top)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Filter Destinations", 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          tempTags.clear();
                          tempBudget = "Any budget";
                        });
                      },
                      child: const Text("Clear All", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
                const Divider(),

                // 2. Scrollable Content Area
                // Using Expanded here forces the scroll view to take up remaining space
                // but prevents it from pushing the "Apply" button off-screen.
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text("Daily Budget", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildModalDropdown(tempBudget, (val) {
                          setModalState(() => tempBudget = val!);
                        }),
                        const SizedBox(height: 24),
                        const Text("Categories", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableTags.map((tag) {
                            final isSelected = tempTags.any((t) => t.toLowerCase() == tag.toLowerCase());
                            return FilterChip(
                              label: Text(tag),
                              selected: isSelected,
                              onSelected: (bool selected) {
                                setModalState(() {
                                  selected ? tempTags.add(tag) : tempTags.removeWhere((t) => t.toLowerCase() == tag.toLowerCase());
                                });
                              },
                              selectedColor: Colors.green.shade50,
                              checkmarkColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: isSelected ? Colors.green : Colors.grey.shade300),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // 3. Apply Button (Fixed at bottom)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          _appliedTags = List.from(tempTags);
                          _appliedBudget = tempBudget;
                        });
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      child: const Text("Apply Filters", 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Mobile optimization: 1 column if width < 600
    final int crossAxisCount = screenWidth < 600 ? 1 : 2;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Explore',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildResultCount(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: screenWidth < 600
                          ? 1.2
                          : 0.8, // Bigger cards on mobile
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredDestinations.length,
                    itemBuilder: (context, index) => DestinationCard(
                      destination: _filteredDestinations[index],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) {
                _searchQuery = v;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: "Search...",
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
          _buildSortButton(),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _showFilterModal,
            icon: const Icon(Icons.tune),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          items: ["Name", "Budget: Low to High", "Budget: High to Low"]
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
          onChanged: (v) {
            setState(() => _sortBy = v!);
            _applyFilters();
          },
        ),
      ),
    );
  }

  Widget _buildResultCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Text(
            "${_filteredDestinations.length} found",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF009688),
            ),
          ),
          if (_appliedTags.isNotEmpty || _appliedBudget != "Any budget")
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.circle, size: 8, color: Colors.orange),
            ),
        ],
      ),
    );
  }

  Widget _buildModalDropdown(String currentVal, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.shade700, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentVal,
          isExpanded: true,
          items: [
            "Any budget",
            "Under \$100",
            "\$100 - \$200",
            "Over \$200",
          ].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
