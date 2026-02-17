import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/user/logic/saved_provider.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_detail_screen.dart';
import 'package:tour_guide/core/theme/app_colors.dart';

class SavedTabView extends StatefulWidget {
  const SavedTabView({super.key});

  @override
  State<SavedTabView> createState() => _SavedTabViewState();
}

class _SavedTabViewState extends State<SavedTabView> {
  final List<String> _tabs = ['All', 'Destinations', 'Plans', 'Public Trips'];
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    // Load saved items when tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedItems();
    });
  }

  Future<void> _loadSavedItems() async {
    final savedProvider = context.read<SavedProvider>();
    if (savedProvider.savedItems.isEmpty) {
      await savedProvider.fetchSavedItineraries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedProvider = context.watch<SavedProvider>();
    final itineraries = savedProvider.savedItems;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Tab Filter Bar
          _buildTabFilter(),
          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => savedProvider.fetchSavedItineraries(),
              child: _buildContent(savedProvider, itineraries),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabFilter() {
    return Container(
      height: 55,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedTab = index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Text(
                _tabs[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(SavedProvider savedProvider, List<Itinerary> items) {
    if (savedProvider.isLoading) {
      return _buildLoadingState();
    }

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    // Filter items based on selected tab
    final filteredItems = _filterItems(items, _selectedTab);

    if (filteredItems.isEmpty) {
      return _buildEmptyTabState(_tabs[_selectedTab]);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final itinerary = filteredItems[index];
        return _buildSavedItemCard(itinerary, context);
      },
    );
  }

  List<Itinerary> _filterItems(List<Itinerary> items, int tabIndex) {
    // tabIndex: 0=All, 1=Destinations, 2=Plans, 3=Public Trips
    
    if (tabIndex == 0) return items; // All
    
    return items.where((itinerary) {
      switch (tabIndex) {
        case 1: // Destinations
          // You'll need to implement this when you have destination saving
          return false;
        case 2: // Plans (itineraries that are not public)
          return itinerary.isPublic == false;
        case 3: // Public Trips
          return itinerary.isPublic == true;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildSavedItemCard(Itinerary itinerary, BuildContext context) {
    // Get first destination image for the cover
    final String? coverImageUrl = _getCoverImageUrl(itinerary);
    
    return Dismissible(
      key: Key('saved_${itinerary.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        return await _showUnsaveDialog(itinerary.id);
      },
      onDismissed: (direction) async {
        await context.read<SavedProvider>().unsaveItinerary(itinerary.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${itinerary.title}" from saved'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                await context.read<SavedProvider>().saveItinerary(itinerary.id);
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItineraryDetailScreen(
                itinerary: itinerary,
                isReadOnly: true,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with Save Badge
              Stack(
                children: [
                  // Trip Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: coverImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: coverImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey.shade200,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                  size: 50,
                                ),
                              ),
                            )
                          : Container(
                              color: _getTypeColor(itinerary).withOpacity(0.2),
                              child: Icon(
                                _getTypeIcon(itinerary),
                                size: 60,
                                color: _getTypeColor(itinerary),
                              ),
                            ),
                    ),
                  ),
                  
                  // Save Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bookmark,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Saved',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Type Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(itinerary).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getTypeLabel(itinerary),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Save Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            itinerary.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.bookmark,
                            color: Colors.red,
                          ),
                          onPressed: () => _unsaveItem(itinerary.id),
                        ),
                      ],
                    ),

                    // Description
                    if (itinerary.description != null && itinerary.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          itinerary.description!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Stats Row
                    Row(
                      children: [
                        // Duration
                        if (itinerary.totalDays != null && itinerary.totalDays! > 0)
                          _buildStatItem(
                            Icons.calendar_today,
                            '${itinerary.totalDays} day${itinerary.totalDays! > 1 ? 's' : ''}',
                          ),
                        if (itinerary.totalDays != null && itinerary.totalDays! > 0)
                          const SizedBox(width: 16),

                        // Likes
                        _buildStatItem(
                          Icons.favorite_border,
                          '${itinerary.likeCount ?? 0}',
                        ),
                        const SizedBox(width: 16),

                        // Copy Count
                        if (itinerary.copyCount != null && itinerary.copyCount! > 0)
                          _buildStatItem(
                            Icons.copy,
                            '${itinerary.copyCount}',
                          ),
                        if (itinerary.copyCount != null && itinerary.copyCount! > 0)
                          const SizedBox(width: 16),

                        // Budget
                        if (itinerary.estimatedBudget != null)
                          _buildStatItem(
                            Icons.attach_money,
                            '\$${itinerary.estimatedBudget!.toStringAsFixed(0)}',
                          ),
                      ],
                    ),

                    // Tags (if available)
                    if (itinerary.tags != null && itinerary.tags!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: itinerary.tags!
                              .take(3)
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),

                    // Footer with date and action
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Copy button for public trips
                        if (itinerary.isPublic == true && itinerary.sourceId == null)
                          ElevatedButton.icon(
                            onPressed: () => _copyItinerary(itinerary.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy to My Plans'),
                          ),
                        const Spacer(),
                        if (itinerary.createdAt != null)
                          Text(
                            'Saved ${_formatRelativeDate(itinerary.createdAt!)}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to get cover image from first destination
  String? _getCoverImageUrl(Itinerary itinerary) {
    if (itinerary.items != null && itinerary.items!.isNotEmpty) {
      final firstItem = itinerary.items!.first;
      return null; 
    }
    return null;
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Future<bool> _showUnsaveDialog(int itineraryId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Saved?'),
        content: const Text('This item will be removed from your saved list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _unsaveItem(int itineraryId) async {
    final confirmed = await _showUnsaveDialog(itineraryId);
    if (confirmed) {
      await context.read<SavedProvider>().unsaveItinerary(itineraryId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from saved items'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _copyItinerary(int itineraryId) async {
    try {
      final itineraryProvider = context.read<ItineraryProvider>();
      await itineraryProvider.copyTrip(itineraryId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip copied to your plans!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to copy: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loading image
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
              // Loading content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 20,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 16,
                      width: MediaQuery.of(context).size.width * 0.7,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          height: 20,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          height: 20,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bookmark_border,
                  size: 80,
                  color: AppColors.primary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'No Saved Items Yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // Description
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Save interesting destinations, itineraries, and public trips to find them here later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Explore Button
              ElevatedButton(
                onPressed: () {
                  // Navigate to Explore screen
                  // You might want to use your app's navigation system
                  Navigator.pushNamed(context, '/explore');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Explore Content',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTabState(String tabName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getTabIcon(tabName),
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No $tabName saved',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start exploring and save your favorite $tabName',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTabIcon(String tabName) {
    switch (tabName.toLowerCase()) {
      case 'destinations':
        return Icons.location_on;
      case 'plans':
        return Icons.assignment;
      case 'public trips':
        return Icons.public;
      default:
        return Icons.bookmark_border;
    }
  }

  IconData _getTypeIcon(Itinerary itinerary) {
    if (itinerary.isAdminCreated) {
      return Icons.auto_awesome;
    } else if (itinerary.isPublic) {
      return Icons.public;
    } else {
      return Icons.person;
    }
  }

  Color _getTypeColor(Itinerary itinerary) {
    if (itinerary.isAdminCreated) {
      return AppColors.primary; // Expert Plan
    } else if (itinerary.isPublic) {
      return Colors.green; // Public Trip
    } else {
      return Colors.orange; // Personal Plan
    }
  }

  String _getTypeLabel(Itinerary itinerary) {
    if (itinerary.isAdminCreated) {
      return 'Expert Plan';
    } else if (itinerary.isPublic) {
      return 'Public Trip';
    } else {
      return 'Personal';
    }
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
