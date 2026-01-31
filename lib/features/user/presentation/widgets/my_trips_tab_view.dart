import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_detail_screen.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/progress_stats.dart';

class MyTripsTabView extends StatelessWidget {
  const MyTripsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to AuthProvider for the user's personal plans
    final itineraryProvider = context.watch<ItineraryProvider>();
    final List<Itinerary> myTrips = itineraryProvider.myPlans;

    // Check loading state from the new provider
    if (itineraryProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (myTrips.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myTrips.length,
      itemBuilder: (context, index) {
        return _buildTripCard(context, myTrips[index]);
      },
    );
  }

  // Replace your _buildTripCard and _buildTripImage with these
  Widget _buildTripCard(BuildContext context, Itinerary trip) {
    final bool isCompleted = trip.status == 'COMPLETED';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Softer corners
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
                builder: (_) => ItineraryDetailScreen(itinerary: trip),
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
                            trip.sourceId != null,
                          ),
                          const SizedBox(height: 8),
                          _buildMetaInfo(trip, trip.sourceId != null),
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
        color: isCompleted ? const Color(0xFFE6F6EE) : const Color(0xFFFFF7E6),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            isCompleted ? Icons.verified : Icons.edit_note,
            size: 40,
            color: isCompleted ? Colors.green[700] : Colors.orange[700],
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
                trip.status ?? "DRAFT",
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

  Widget _buildMetaInfo(Itinerary trip, bool isCopied) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isCopied ? Icons.copy_all : Icons.person_outline,
              size: 14,
              color: Colors.blueGrey,
            ),
            const SizedBox(width: 4),
            Text(
              isCopied ? "Copied Plan" : "Original Plan",
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
            const SizedBox(width: 8),
            Icon(
              trip.isPublic ? Icons.public : Icons.lock_outline,
              size: 14,
              color: Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              trip.isPublic ? "Public" : "Private",
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Ends: ${trip.endDate != null ? trip.endDate.toString().split(' ')[0] : 'N/A'}",
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Itinerary trip,
    ItineraryProvider provider,
    bool isCopied,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            trip.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        PopupMenuButton<String>(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) =>
              _handleMenuAction(context, value, trip, provider, isCopied),
          itemBuilder: (context) => [
            _buildPopupItem('edit', Icons.edit_outlined, "Edit Details"),
            if (!isCopied && trip.status == 'COMPLETED' && !trip.isPublic)
              _buildPopupItem(
                'share',
                Icons.share_outlined,
                "Share to Community",
              ),
            const PopupMenuDivider(),
            _buildPopupItem(
              'delete',
              Icons.delete_outline,
              "Delete Trip",
              isDestructive: true,
            ),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String text, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDestructive ? Colors.red : Colors.blueGrey,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isDestructive ? Colors.red : Colors.black87,
              fontSize: 14,
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
        _showShareConfirmation(context, provider, trip);
        break;
      case 'delete':
        _showDeleteConfirmation(context, provider, trip);
        break;
    }
  }

  void _showShareConfirmation(
    BuildContext context,
    ItineraryProvider provider,
    Itinerary trip,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Share with Community?"),
        content: const Text(
          "This will make your itinerary visible on the Explore tab for other travelers to see and copy.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009688),
            ),
            onPressed: () async {
              // Ensure you have this method in your ItineraryProvider
              final success = await provider.shareTrip(trip.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? "Trip is now Public!" : "Failed to share trip",
                    ),
                  ),
                );
              }
            },
            child: const Text(
              "Make Public",
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
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009688),
            ),
            onPressed: () async {
              final success = await context
                  .read<ItineraryProvider>()
                  .updatePlanDetails(
                    trip.id,
                    titleController.text,
                    descController.text,
                  );

              if (context.mounted) {
                Navigator.pop(context);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to update trip")),
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
      builder: (context) => AlertDialog(
        title: const Text("Delete Trip?"),
        content: Text(
          "Are you sure you want to delete '${trip.title}'? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final success = await provider.deletePlan(trip.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Trip deleted")));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
          const Text(
            "Explore and copy plans to see them here!",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
