import 'package:flutter/material.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/data/services/itinerary_service.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_map_screen.dart';

class ItineraryDetailScreen extends StatefulWidget {
  final Itinerary itinerary;
  const ItineraryDetailScreen({super.key, required this.itinerary});

  @override
  State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen> {
  int selectedDay = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: ItineraryService.getItineraryDetails(widget.itinerary.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF009688)),
            );
          }

          final data = snapshot.data ?? {};
          final List activities = data['items'] ?? [];
          // Filter activities for the currently selected day
          final dailyActivities = activities
              .where((a) => a['dayNumber'] == selectedDay)
              .toList();

          return CustomScrollView(
            slivers: [
              _buildParallaxHeader(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickStats(),
                      const SizedBox(height: 24),
                      const Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.itinerary.description ??
                            "Explore this hand-picked journey crafted for the best experience.",
                        style: TextStyle(
                          color: Colors.grey[600],
                          height: 1.5,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildDaySelector(widget.itinerary.totalDays ?? 1),
                    ],
                  ),
                ),
              ),
              // Activities List
              dailyActivities.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text("No activities planned for this day."),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildTimelineActivity(
                            dailyActivities[index],
                            index + 1,
                          ),
                          childCount: dailyActivities.length,
                        ),
                      ),
                    ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FutureBuilder<Map<String, dynamic>>(
        future: ItineraryService.getItineraryDetails(widget.itinerary.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final List activities = snapshot.data!['items'] ?? [];
          final dailyActivities = activities
              .where((a) => a['dayNumber'] == selectedDay)
              .toList();

          return FloatingActionButton.extended(
            onPressed: () {
              final validActivities = dailyActivities.where((a) {
                final dest = a['destination'];
                if (dest == null) return false;

                // Check if lat/lng exists inside the destination object
                // Adjust 'latitude'/'longitude' to match whatever names your backend uses
                return dest['latitude'] != null && dest['longitude'] != null;
              }).toList();

              if (validActivities.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("No coordinates found in destination data."),
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ItineraryMapScreen(activities: validActivities),
                ),
              );
            },
            backgroundColor: dailyActivities.isEmpty
                ? Colors.grey
                : const Color(0xFF009688),
            icon: const Icon(Icons.directions_outlined, color: Colors.white),
            label: const Text(
              "Show Day Route",
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParallaxHeader() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF009688),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.itinerary.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Using a hero-style image or destination combination
            Image.network(
              "https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=800",
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statTile(
            Icons.payments_outlined,
            "\$${widget.itinerary.estimatedBudget?.toInt()}",
            "Budget",
          ),
          _divider(),
          _statTile(
            Icons.star_rounded,
            "${widget.itinerary.averageRating ?? 'N/A'}",
            "Rating",
          ),
          _divider(),
          _statTile(
            Icons.access_time,
            "${widget.itinerary.totalDays} Days",
            "Duration",
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineActivity(Map<String, dynamic> act, int order) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The Numbered Timeline
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF009688),
                shape: BoxShape.circle,
              ),
              child: Text(
                "$order",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            Container(
              width: 2,
              height: 120,
              color: Colors.teal.withOpacity(0.2),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                act['startTime']?.substring(0, 5) ?? "Morning",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF009688),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                act['title'] ?? "Visit Destination",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                act['notes'] ?? "No additional details.",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              if (act['destinationImageUrl'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      act['destinationImageUrl'],
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDaySelector(int totalDays) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalDays,
        itemBuilder: (context, index) {
          int day = index + 1;
          bool isSelected = selectedDay == day;
          return Padding(
            padding: const EdgeInsets.only(
              right: 12,
            ), // Fixed the EdgeInsets error here
            child: ChoiceChip(
              label: Text("Day $day"),
              selected: isSelected,
              onSelected: (val) => setState(() => selectedDay = day),
              selectedColor: const Color(0xFF009688),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statTile(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF009688)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _divider() => Container(height: 30, width: 1, color: Colors.grey[300]);
}
