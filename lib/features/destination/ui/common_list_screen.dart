// lib/screens/common_list_screen.dart
import 'package:flutter/material.dart';
import 'destination_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/api_client.dart';

class CommonListScreen extends StatelessWidget {
  final String title;
  final Future<List<dynamic>> future;

  const CommonListScreen({super.key, required this.title, required this.future});

  String _formatImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    return path.startsWith('http') ? path : '${ApiClient.baseUrl}$path';
  }

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
              final d = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DestinationCardDataWrapper(
                  data: DestinationCardData(
                    title: d.name,
                    subtitle: d.shortDescription ?? '',
                    tag: (d.tags != null && d.tags.isNotEmpty) ? d.tags.first : 'Explore',
                    tagColor: AppColors.primary,
                    imageUrl: _formatImageUrl(d.images.isNotEmpty ? d.images.first : null),
                    metaIcon: Icons.location_on,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Small helper to reuse the card style without the PageView behavior
class DestinationCardDataWrapper extends StatelessWidget {
  final DestinationCardData data;
  const DestinationCardDataWrapper({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // This calls the internal _DestinationCard you have in destination_card.dart
    // Since _DestinationCard is private in your file, you might need to make it public 
    // (remove the underscore) or copy the build logic here.
    return SizedBox(
      width: double.infinity,
      child: DestinationCard(data: data), // Ensure DestinationCard is public
    );
  }
}