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

  Widget _buildTripCard(BuildContext context, Itinerary trip) {
    // Access provider using read (for actions)
    final itineraryProvider = context.read<ItineraryProvider>();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ItineraryDetailScreen(itinerary: trip),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            // Image section
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
              child: const Icon(Icons.map_outlined, color: Colors.grey),
            ),
            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            trip.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // --- DELETE / ACTIONS MENU ---
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            size: 20,
                            color: Colors.grey,
                          ),
                          // inside _buildTripCard...
                          onSelected: (value) {
                            if (value == 'delete') {
                              _showDeleteConfirmation(
                                context,
                                itineraryProvider,
                                trip,
                              );
                            } else if (value == 'edit') {
                              _showEditDialog(
                                context,
                                trip,
                              ); // Call a dialog here too
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text("Edit Details"),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Delete Trip",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${trip.totalDays ?? 0} Days • ${trip.theme ?? 'Trip'}",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    _buildProgressBar(trip),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildProgressBar(Itinerary trip) {
    return ProgressStats.forTripCard(itinerary: trip);
  }

  // Widget _buildProgressBar(Itinerary trip) {
  //   final total = trip.summary?.activityCount ?? 0;
  //   final completed = trip.summary?.completedActivities ?? 0;

  //   // Calculate actual percentage
  //   double progress = total > 0 ? completed / total : 0;

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       ClipRRect(
  //         borderRadius: BorderRadius.circular(10),
  //         child: LinearProgressIndicator(
  //           value: progress,
  //           backgroundColor: Colors.grey[200],
  //           valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
  //           minHeight: 6,
  //         ),
  //       ),
  //       const SizedBox(height: 4),
  //       Text(
  //         "$completed of $total activities visited",
  //         style: const TextStyle(fontSize: 10, color: Colors.grey),
  //       ),
  //     ],
  //   );
  // }

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
