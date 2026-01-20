import 'package:flutter/material.dart';
import 'package:tour_guide/features/destination/data/models/destination.dart';
import '../widgets/destination_card.dart';

class CommonListScreen extends StatelessWidget {
  final String title;
  final Future<List<dynamic>> future;

  const CommonListScreen({
    super.key,
    required this.title,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              // If future returns a list of Destination models:
              if (item is Destination) {
                return DestinationCard(destination: item);
              }

              // If it returns raw JSON (Map):
              return DestinationCard(
                destination: Destination.fromJson(item as Map<String, dynamic>),
              );
            },
          );
        },
      ),
    );
  }
}
