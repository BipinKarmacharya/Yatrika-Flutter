import 'package:flutter/material.dart';
import 'package:tour_guide/features/destination/data/models/destination.dart';
import 'package:tour_guide/features/itinerary/data/services/itinerary_service.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/destination/presentation/screens/trip_planner_screen.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import '../../../auth/logic/auth_provider.dart';

class DestinationDetailScreen extends StatelessWidget {
  final Destination destination;
  final ItineraryService _itineraryService = ItineraryService();

  DestinationDetailScreen({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF8F9FA,
      ), // Light grey background like screenshot
      body: CustomScrollView(
        slivers: [
          // 1. IMAGE HEADER SECTION
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: BackButton(color: Colors.teal[800]),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.bookmark_border, color: Colors.teal[800]),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'dest_image_${destination.id}',
                    child: Image.network(
                      destination.images.isNotEmpty
                          ? destination.images[0]
                          : '',
                      fit: BoxFit.cover,
                      headers: const {"ngrok-skip-browser-warning": "true"},
                    ),
                  ),
                  // Gradient for text readability
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                  // Floating Tags and Title inside the header
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: destination.tags
                              .map((tag) => _buildHeaderTag(tag))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          destination.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              destination.district ?? "Location",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
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

          // 2. INFO GRID SECTION (Daily Cost, Best Time, etc.)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _buildInfoCard(
                        Icons.attach_money,
                        "Daily Cost",
                        "~\$${destination.cost.toInt()}",
                        Colors.teal,
                      ),
                      _buildInfoCard(
                        Icons.calendar_today,
                        "Best Time",
                        "May - Sept",
                        Colors.teal,
                      ),
                      _buildInfoCard(
                        Icons.star_border,
                        "Rating",
                        "${destination.averageRating}/5",
                        Colors.orange,
                      ),
                      _buildInfoCard(
                        Icons.people_outline,
                        "Reviews",
                        "2,847",
                        Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. TAB INDICATOR SECTION
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton("Overview", isActive: true),
                        _buildTabButton("Highlights"),
                        _buildTabButton("Activities"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. ABOUT SECTION
                  _buildContentCard(
                    title: "About ${destination.name}",
                    content:
                        destination.description ?? "No description available.",
                  ),
                  const SizedBox(height: 16),

                  // 5. SUGGESTED ITINERARIES SECTION
                  _buildContentCard(
                    title: "Suggested Itineraries",
                    icon: Icons.auto_awesome_outlined,
                    child: FutureBuilder<List<Itinerary>>(
                      future: ItineraryService.getItinerariesByDestination(
                        int.parse(destination.id.toString()),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Text(
                            "No curated itineraries for this spot yet.",
                          );
                        }

                        final itineraries = snapshot.data!;
                        return Column(
                          children: itineraries
                              .map((it) => _buildItineraryCard(it))
                              .toList(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6. LOCATION SECTION
                  _buildContentCard(
                    title: "Location",
                    icon: Icons.location_on_outlined,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://static-maps.yandex.ru/1.x/?lang=en_US&ll=${destination.lng},${destination.lat}&z=12&l=map&size=600,300',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 7. PLAN YOUR TRIP SECTION (Green Banner)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009688),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Plan Your Trip",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Create a custom itinerary for your adventure.",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              // ✅ FIX: Use Provider to check if a token exists
                              final authProvider = context.read<AuthProvider>();
                              final bool isLoggedIn =
                                  authProvider.token != null;

                              if (isLoggedIn) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TripPlannerScreen(
                                      destination: destination,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Please login to create an itinerary.",
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                // Ensure '/login' route is defined in main.dart
                                Navigator.pushNamed(context, '/login');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF009688),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Start Planning",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildHeaderTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, {bool isActive = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard({
    required String title,
    String? content,
    IconData? icon,
    Widget? child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (content != null)
            Text(
              content,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
                height: 1.6,
              ),
            ),
          if (child != null) child,
        ],
      ),
    );
  }

  Widget _buildItineraryCard(Itinerary itinerary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, // Changed to white for better contrast
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  itinerary.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (itinerary.theme != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    itinerary.theme!,
                    style: const TextStyle(
                      color: Colors.teal,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            "${itinerary.totalDays ?? 0} Days Plan",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                itinerary.description ?? "Explore this curated journey.",
              ),
            ),
            // We can add a button here to "View Full Plan"
          ],
        ),
      ),
    );
  }
}
