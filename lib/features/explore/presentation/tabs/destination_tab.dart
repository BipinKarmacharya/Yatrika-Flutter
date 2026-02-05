import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/destination/logic/destination_provider.dart';
import '../widgets/destination_card.dart';
import '../widgets/explore_grid_delegate.dart';

class DestinationTab extends StatefulWidget {
  const DestinationTab({super.key});

  @override
  State<DestinationTab> createState() => _DestinationTabState();
}

class _DestinationTabState extends State<DestinationTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _searchQuery = "";
  List<String> _appliedTags = [];
  String _appliedBudget = "Any budget";
  Timer? _debounce;

  // The list of tags used in the filter modal
  final List<String> _availableTags = [
    "Adventure", "Beach", "Cultural", "Food", "Hiking",
    "Historical", "Mountains", "Nature", "Nightlife", "Wellness",
  ];

  @override
  void initState() {
    super.initState();
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DestinationProvider>().fetchDestinations();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchQuery = query;
      _triggerFetch();
    });
  }

  void _triggerFetch() {
    context.read<DestinationProvider>().fetchDestinations(
      search: _searchQuery,
      tags: _appliedTags,
      budget: _appliedBudget,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    return Consumer<DestinationProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            _buildSearchBar(),
            _buildResultHeader(provider.destinations.length),
            Expanded(
              child: _buildBody(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(DestinationProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF009688)),
      );
    }

    if (provider.errorMessage != null) {
      return _buildErrorWidget(provider.errorMessage!);
    }

    if (provider.destinations.isEmpty) {
      return const Center(child: Text("No destinations found."));
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchDestinations(
        search: _searchQuery,
        tags: _appliedTags,
        budget: _appliedBudget,
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: ExploreGridDelegate.getDelegate(context, true),
        itemCount: provider.destinations.length,
        itemBuilder: (context, index) => DestinationCard(
          destination: provider.destinations[index],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search destinations...",
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
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Colors.black54),
              onPressed: _showFilterModal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "$count destinations found",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(message),
          TextButton(
            onPressed: _triggerFetch,
            child: const Text("Retry", style: TextStyle(color: Color(0xFF009688))),
          )
        ],
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
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filters",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () => setModalState(() {
                          tempTags.clear();
                          tempBudget = "Any budget";
                        }),
                        child: const Text("Clear All", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            "Categories",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _availableTags.map((tag) {
                              final isSelected = tempTags.contains(tag);
                              return FilterChip(
                                label: Text(tag),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setModalState(() {
                                    selected ? tempTags.add(tag) : tempTags.remove(tag);
                                  });
                                },
                                selectedColor: const Color(0xFF009688).withOpacity(0.1),
                                checkmarkColor: const Color(0xFF009688),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Budget Range",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: tempBudget,
                                isExpanded: true,
                                items: ["Any budget", "Under \$100", "\$100 - \$200", "Over \$200"]
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (v) => setModalState(() => tempBudget = v!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          _appliedTags = tempTags;
                          _appliedBudget = tempBudget;
                        });
                        _triggerFetch(); // Updated this call
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Apply Filters",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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