// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:tour_guide/features/destination/logic/destination_provider.dart';
// import '../widgets/destination_card.dart';
// import '../widgets/explore_grid_delegate.dart';

// class DestinationTab extends StatefulWidget {
//   const DestinationTab({super.key});

//   @override
//   State<DestinationTab> createState() => _DestinationTabState();
// }

// class _DestinationTabState extends State<DestinationTab>
//     with AutomaticKeepAliveClientMixin {
//   @override
//   bool get wantKeepAlive => true;

//   String _searchQuery = "";
//   List<String> _appliedTags = [];
//   String _appliedBudget = "Any budget";
//   Timer? _debounce;

//   // The list of tags used in the filter modal
//   final List<String> _availableTags = [
//     "Adventure", "Beach", "Cultural", "Food", "Hiking",
//     "Historical", "Mountains", "Nature", "Nightlife", "Wellness",
//   ];

//   @override
//   void initState() {
//     super.initState();
//     // Initial fetch
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<DestinationProvider>().fetchDestinations();
//     });
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   void _onSearchChanged(String query) {
//     if (_debounce?.isActive ?? false) _debounce!.cancel();
//     _debounce = Timer(const Duration(milliseconds: 500), () {
//       _searchQuery = query;
//       _triggerFetch();
//     });
//   }

//   void _triggerFetch() {
//     context.read<DestinationProvider>().fetchDestinations(
//       search: _searchQuery,
//       tags: _appliedTags,
//       budget: _appliedBudget,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     super.build(context); // Required by AutomaticKeepAliveClientMixin

//     return Consumer<DestinationProvider>(
//       builder: (context, provider, child) {
//         return Column(
//           children: [
//             _buildSearchBar(),
//             _buildResultHeader(provider.destinations.length),
//             Expanded(
//               child: _buildBody(provider),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildBody(DestinationProvider provider) {
//     if (provider.isLoading) {
//       return const Center(
//         child: CircularProgressIndicator(color: Color(0xFF009688)),
//       );
//     }

//     if (provider.errorMessage != null) {
//       return _buildErrorWidget(provider.errorMessage!);
//     }

//     if (provider.destinations.isEmpty) {
//       return const Center(child: Text("No destinations found."));
//     }

//     return RefreshIndicator(
//       onRefresh: () => provider.fetchDestinations(
//         search: _searchQuery,
//         tags: _appliedTags,
//         budget: _appliedBudget,
//       ),
//       child: GridView.builder(
//         padding: const EdgeInsets.all(16),
//         gridDelegate: ExploreGridDelegate.getDelegate(context, true),
//         itemCount: provider.destinations.length,
//         itemBuilder: (context, index) => DestinationCard(
//           destination: provider.destinations[index],
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               onChanged: _onSearchChanged,
//               decoration: InputDecoration(
//                 hintText: "Search destinations...",
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.grey.shade100,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.grey.shade100,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: IconButton(
//               icon: const Icon(Icons.tune, color: Colors.black54),
//               onPressed: _showFilterModal,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildResultHeader(int count) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
//       child: Align(
//         alignment: Alignment.centerLeft,
//         child: Text(
//           "$count destinations found",
//           style: TextStyle(
//             color: Colors.grey.shade600,
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorWidget(String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
//           const SizedBox(height: 16),
//           Text(message),
//           TextButton(
//             onPressed: _triggerFetch,
//             child: const Text("Retry", style: TextStyle(color: Color(0xFF009688))),
//           )
//         ],
//       ),
//     );
//   }

//   void _showFilterModal() {
//     List<String> tempTags = List.from(_appliedTags);
//     String tempBudget = _appliedBudget;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setModalState) {
//             return Container(
//               constraints: BoxConstraints(
//                 maxHeight: MediaQuery.of(context).size.height * 0.8,
//               ),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//               ),
//               padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: 40,
//                     height: 4,
//                     margin: const EdgeInsets.only(bottom: 20),
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade300,
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         "Filters",
//                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                       ),
//                       TextButton(
//                         onPressed: () => setModalState(() {
//                           tempTags.clear();
//                           tempBudget = "Any budget";
//                         }),
//                         child: const Text("Clear All", style: TextStyle(color: Colors.red)),
//                       ),
//                     ],
//                   ),
//                   const Divider(),
//                   Expanded(
//                     child: SingleChildScrollView(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const SizedBox(height: 16),
//                           const Text(
//                             "Categories",
//                             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                           ),
//                           const SizedBox(height: 12),
//                           Wrap(
//                             spacing: 8,
//                             runSpacing: 4,
//                             children: _availableTags.map((tag) {
//                               final isSelected = tempTags.contains(tag);
//                               return FilterChip(
//                                 label: Text(tag),
//                                 selected: isSelected,
//                                 onSelected: (selected) {
//                                   setModalState(() {
//                                     selected ? tempTags.add(tag) : tempTags.remove(tag);
//                                   });
//                                 },
//                                 selectedColor: const Color(0xFF009688).withOpacity(0.1),
//                                 checkmarkColor: const Color(0xFF009688),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               );
//                             }).toList(),
//                           ),
//                           const SizedBox(height: 24),
//                           const Text(
//                             "Budget Range",
//                             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                           ),
//                           const SizedBox(height: 12),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 12),
//                             decoration: BoxDecoration(
//                               color: Colors.grey.shade100,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: DropdownButtonHideUnderline(
//                               child: DropdownButton<String>(
//                                 value: tempBudget,
//                                 isExpanded: true,
//                                 items: ["Any budget", "Under \$100", "\$100 - \$200", "Over \$200"]
//                                     .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//                                     .toList(),
//                                 onChanged: (v) => setModalState(() => tempBudget = v!),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 32),
//                         ],
//                       ),
//                     ),
//                   ),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 50,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF009688),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _appliedTags = tempTags;
//                           _appliedBudget = tempBudget;
//                         });
//                         _triggerFetch(); // Updated this call
//                         Navigator.pop(context);
//                       },
//                       child: const Text(
//                         "Apply Filters",
//                         style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }



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

  // Responsive layout detection
  bool get _isMobile => MediaQuery.of(context).size.width < 600;

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
    if (provider.isLoading && provider.destinations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF009688)),
      );
    }

    if (provider.errorMessage != null && provider.destinations.isEmpty) {
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
      child: _isMobile
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.destinations.length,
              itemBuilder: (context, index) {
                final destination = provider.destinations[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DestinationCard(
                    key: ValueKey(destination.id),
                    destination: destination,
                    isGrid: false, // List view mode
                  ),
                );
              },
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: ExploreGridDelegate.getDelegate(context, false), // false = grid mode
              itemCount: provider.destinations.length,
              itemBuilder: (context, index) {
                final destination = provider.destinations[index];
                return DestinationCard(
                  key: ValueKey(destination.id),
                  destination: destination,
                  isGrid: true, // Grid view mode
                );
              },
            ),
    );
  }

  Widget _buildSearchBar() {
    final isMobile = _isMobile;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24,
        isMobile ? 16 : 24,
        isMobile ? 16 : 24,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search destinations...",
                hintStyle: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.grey.shade500,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: isMobile ? 20 : 24,
                  color: Colors.grey.shade600,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 20,
                  vertical: isMobile ? 12 : 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF009688), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: _appliedTags.isNotEmpty || _appliedBudget != "Any budget"
                  ? const Color(0xFF009688).withOpacity(0.1)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _appliedTags.isNotEmpty || _appliedBudget != "Any budget"
                    ? const Color(0xFF009688)
                    : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: _appliedTags.isNotEmpty || _appliedBudget != "Any budget"
                        ? const Color(0xFF009688)
                        : Colors.grey.shade600,
                    size: isMobile ? 20 : 24,
                  ),
                  if (_appliedTags.isNotEmpty || _appliedBudget != "Any budget")
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF009688),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _showFilterModal,
              tooltip: 'Filter destinations',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(int count) {
    final isMobile = _isMobile;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$count ${count == 1 ? 'destination' : 'destinations'} found",
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.grid_view_rounded,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Grid View',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: TextStyle(
                fontSize: _isMobile ? 20 : 24,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _isMobile ? 14 : 15,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _triggerFetch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
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
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                _isMobile ? 20 : 24,
                8,
                _isMobile ? 20 : 24,
                24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filters",
                        style: TextStyle(
                          fontSize: _isMobile ? 20 : 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setModalState(() {
                          tempTags.clear();
                          tempBudget = "Any budget";
                        }),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                        ),
                        child: const Text("Clear All"),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  
                  // Filter content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Categories section
                          Text(
                            "Categories",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: _isMobile ? 15 : 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableTags.map((tag) {
                              final isSelected = tempTags.contains(tag);
                              return FilterChip(
                                label: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: _isMobile ? 13 : 14,
                                    color: isSelected 
                                        ? const Color(0xFF009688)
                                        : Colors.grey.shade700,
                                    fontWeight: isSelected 
                                        ? FontWeight.w600 
                                        : FontWeight.w400,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setModalState(() {
                                    selected 
                                        ? tempTags.add(tag) 
                                        : tempTags.remove(tag);
                                  });
                                },
                                backgroundColor: Colors.grey.shade50,
                                selectedColor: const Color(0xFF009688).withOpacity(0.1),
                                checkmarkColor: const Color(0xFF009688),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF009688)
                                      : Colors.grey.shade200,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              );
                            }).toList(),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Budget section
                          Text(
                            "Budget Range",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: _isMobile ? 15 : 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: tempBudget,
                                isExpanded: true,
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey.shade600,
                                ),
                                style: TextStyle(
                                  fontSize: _isMobile ? 14 : 15,
                                  color: Colors.grey.shade800,
                                ),
                                items: [
                                  "Any budget", 
                                  "Under \$100", 
                                  "\$100 - \$200", 
                                  "Over \$200"
                                ].map((e) => DropdownMenuItem(
                                  value: e, 
                                  child: Text(e),
                                )).toList(),
                                onChanged: (v) => setModalState(() => tempBudget = v!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  
                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        foregroundColor: Colors.white,
                        elevation: 0,
                                                shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _appliedTags = tempTags;
                          _appliedBudget = tempBudget;
                        });
                        _triggerFetch();
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Apply Filters",
                        style: TextStyle(
                          fontSize: _isMobile ? 15 : 16,
                          fontWeight: FontWeight.w600,
                        ),
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