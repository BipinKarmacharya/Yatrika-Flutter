import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_detail_screen.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/progress_stats.dart';

class MyTripsTabView extends StatelessWidget {
  const MyTripsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final itineraryProvider = context.watch<ItineraryProvider>();
    final List<Itinerary> myTrips = itineraryProvider.myPlans;

    if (itineraryProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF009688)),
      );
    }

    if (myTrips.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      color: const Color(0xFF009688),
      onRefresh: () async {
        await itineraryProvider.fetchMyPlans();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myTrips.length,
        itemBuilder: (context, index) {
          return _buildTripCard(context, myTrips[index]);
        },
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Itinerary trip) {
    final bool isCompleted = trip.status == 'COMPLETED';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItineraryDetailScreen(
                  itinerary: trip,
                  isReadOnly: false, // Explicitly allow editing for My Trips
                ),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTripImage(trip, isCompleted),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(
                            context,
                            trip,
                            context.read<ItineraryProvider>(),
                          ),
                          const SizedBox(height: 8),
                          _buildMetaInfo(trip),
                          const Spacer(),
                          const SizedBox(height: 12),
                          ProgressStats.forTripCard(itinerary: trip),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripImage(Itinerary trip, bool isCompleted) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFE6F6EE) : const Color(0xFFF0F7F7),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Icon
          Icon(
            isCompleted ? Icons.verified : Icons.event_available,
            size: 40,
            color: isCompleted
                ? Colors.green.withOpacity(0.2)
                : Colors.teal.withOpacity(0.2),
          ),

          // Date Badge
          if (trip.startDate != null)
            Positioned(
              top: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF009688),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        _getMonth(trip.startDate!.month),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        "${trip.startDate!.day}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                trip.status,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo(Itinerary trip) {
    final bool isPublic = trip.isPublic;
    final bool isCopied = trip.isCopied;
    String dateRange;
    if (trip.startDate != null && trip.endDate != null) {
      dateRange =
          "${_formatShortDate(trip.startDate!)} - ${_formatShortDate(trip.endDate!)}";
    } else if (trip.startDate != null) {
      dateRange = "Starts: ${_formatShortDate(trip.startDate!)}";
    } else {
      dateRange = "Flexible Dates"; // Replaces "Dates not set"
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 12, color: Colors.teal[700]),
            const SizedBox(width: 4),
            Text(
              dateRange,
              style: TextStyle(
                fontSize: 12,
                color: Colors.teal[900],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "• ${trip.totalDays ?? 1} ${trip.totalDays == 1 ? 'Day' : 'Days'}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              isCopied ? Icons.copy_all : Icons.person_outline,
              size: 14,
              color: AppColors.subtext,
            ),
            const SizedBox(width: 4),
            Text(
              isCopied ? "Copied" : "Original",
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
            const SizedBox(width: 8),
            Icon(
              isPublic ? Icons.public : Icons.lock_outline,
              size: 14,
              color: isPublic ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              isPublic ? "Public" : "Private",
              style: TextStyle(
                fontSize: 11,
                color: isPublic ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Widget _buildHeader(
    BuildContext context,
    Itinerary trip,
    ItineraryProvider provider,
  ) {
    final bool isCompleted = trip.status == 'COMPLETED';
    final bool isPublic = trip.isPublic;
    final bool isCopied = trip.isCopied;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trip.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCopied && isCompleted) const SizedBox(height: 4),
              if (isCopied && isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 10,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Copied trips cannot be shared",
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) =>
              _handleMenuAction(context, value, trip, provider, isCopied),
          itemBuilder: (context) =>
              _buildMenuItems(context, trip, isCopied, isCompleted, isPublic),
        ),
      ],
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
    BuildContext context,
    Itinerary trip,
    bool isCopied,
    bool isCompleted,
    bool isPublic,
  ) {
    final items = <PopupMenuEntry<String>>[];

    // Edit option - always available
    items.add(_buildPopupItem('edit', Icons.edit_outlined, "Edit Details"));

    // Share/Unshare options
    if (!isCopied && isCompleted) {
      if (isPublic) {
        // Option to make private
        items.add(
          _buildPopupItem(
            'unshare',
            Icons.lock_outline,
            "Make Private",
            isWarning: true,
          ),
        );
      } else {
        // Option to share
        items.add(
          _buildPopupItem('share', Icons.share_outlined, "Share to Community"),
        );
      }
    } else if (isCopied && isCompleted && !isPublic) {
      // For copied trips that can't be shared
      items.add(
        _buildPopupItem(
          'info',
          Icons.info_outline,
          "Cannot Share",
          isDisabled: true,
        ),
      );
    }

    // Divider before destructive action
    if (items.isNotEmpty) {
      items.add(const PopupMenuDivider());
    }

    // Delete option
    items.add(
      _buildPopupItem(
        'delete',
        Icons.delete_outline,
        "Delete Trip",
        isDestructive: true,
      ),
    );

    return items;
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String text, {
    bool isDestructive = false,
    bool isWarning = false,
    bool isDisabled = false,
  }) {
    return PopupMenuItem(
      value: value,
      enabled: !isDisabled,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDisabled
                ? Colors.grey
                : isDestructive
                ? Colors.red
                : isWarning
                ? Colors.orange
                : AppColors.subtext,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isDisabled
                  ? Colors.grey
                  : isDestructive
                  ? Colors.red
                  : isWarning
                  ? Colors.orange
                  : Colors.black87,
              fontSize: 14,
              fontStyle: isDisabled ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String value,
    Itinerary trip,
    ItineraryProvider provider,
    bool isCopied,
  ) {
    switch (value) {
      case 'edit':
        _showEditDialog(context, trip);
        break;
      case 'share':
        _showShareConfirmation(context, provider, trip, isCopied);
        break;
      case 'unshare':
        _showUnshareConfirmation(context, provider, trip);
        break;
      case 'info':
        // Show info about why it can't be shared
        _showCannotShareInfo(context, trip);
        break;
      case 'delete':
        _showDeleteConfirmation(context, provider, trip);
        break;
    }
  }

  void _showCannotShareInfo(BuildContext context, Itinerary trip) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Copied trips cannot be shared. Only original plans can be shared with the community.",
        ),
        backgroundColor: Colors.orange[800],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showShareConfirmation(
    BuildContext context,
    ItineraryProvider provider,
    Itinerary trip,
    bool isCopied,
  ) {
    if (isCopied) {
      _showCannotShareInfo(context, trip);
      return;
    }

    // Check if trip is completed
    if (trip.status != 'COMPLETED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Only completed trips can be shared."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.public, color: Colors.green),
            SizedBox(width: 10),
            Text("Share with Community"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "This will make your itinerary visible on the Explore tab for other travelers to see and copy.",
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        "Benefits of sharing:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• Help other travelers discover great routes\n"
                    "• Get recognition for your planning skills\n"
                    "• Your trip might be featured on Explore page\n"
                    "• You can always make it private later",
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              final success = await provider.shareTrip(trip.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "🎉 Trip is now public! Others can now view and copy it.",
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to share trip. Please try again."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Share Now",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnshareConfirmation(
    BuildContext context,
    ItineraryProvider provider,
    Itinerary trip,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange),
            SizedBox(width: 10),
            Text("Make Trip Private"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Are you sure you want to make '${trip.title}' private?"),
            const SizedBox(height: 8),
            const Text(
              "This trip will no longer be visible to other users on the Explore tab.",
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_outlined,
                        size: 16,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Note:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• Existing copies made by other users will remain\n"
                    "• You can share it again anytime if you change your mind\n"
                    "• The trip will still be visible in your 'My Trips' tab",
                    style: TextStyle(fontSize: 12, color: Color(0xFFEF6C00)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep Public"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              bool success = false;

              // Use the provider's unshareTrip method
              success = await provider.unshareTrip(trip.id);

              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Trip is now private."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to make trip private."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Make Private",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Itinerary trip) {
    final titleController = TextEditingController(text: trip.title);
    final descController = TextEditingController(text: trip.description);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Edit Trip Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Trip Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009688),
            ),
            onPressed: () async {
              final success = await context
                  .read<ItineraryProvider>()
                  .updateItineraryHeaders(
                    trip.id,
                    title: titleController.text,
                    description: descController.text,
                  );

              if (context.mounted) {
                Navigator.pop(dialogContext);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to update trip"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Save Changes",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ItineraryProvider provider,
    Itinerary trip,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Trip?"),
        content: Text(
          "Are you sure you want to delete '${trip.title}'? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await provider.deleteTrip(trip.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Trip deleted successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to delete trip"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No trips yet",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009688),
            ),
            onPressed: () {
              // Navigate to explore or create new trip
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Navigate to Explore tab to find trips"),
                ),
              );
            },
            child: const Text(
              "Explore Trips",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonth(int month) {
    const months = [
      "JAN",
      "FEB",
      "MAR",
      "APR",
      "MAY",
      "JUN",
      "JUL",
      "AUG",
      "SEP",
      "OCT",
      "NOV",
      "DEC",
    ];
    return months[month - 1];
  }

  String _formatShortDate(DateTime date) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${months[date.month - 1]} ${date.day}";
  }
}
