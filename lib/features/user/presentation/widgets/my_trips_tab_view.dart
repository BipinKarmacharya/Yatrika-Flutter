import 'package:flutter/material.dart';

class MyTripsTabView extends StatelessWidget {
  const MyTripsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    // This would eventually come from your TripProvider
    final List<Map<String, dynamic>> myTrips = [
      {
        "title": "Swiss Alps Adventure",
        "date": "Jan 12 - Jan 20, 2024",
        "image": "https://images.unsplash.com/photo-1531310197839-ccf54634509e",
        "status": "Completed",
        "location": "Switzerland",
      },
      {
        "title": "Paris Getaway",
        "date": "Mar 05 - Mar 10, 2024",
        "image": "https://images.unsplash.com/photo-1502602898657-3e91760cbb34",
        "status": "Upcoming",
        "location": "France",
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myTrips.length,
      itemBuilder: (context, index) {
        final trip = myTrips[index];
        return _buildTripCard(trip);
      },
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          // Trip Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: Image.network(
              trip['image'],
              width: 100,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          // Trip Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: trip['status'] == "Completed" 
                              ? Colors.green.withOpacity(0.1) 
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trip['status'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: trip['status'] == "Completed" ? Colors.green : Colors.blue,
                          ),
                        ),
                      ),
                      const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trip['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(trip['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}