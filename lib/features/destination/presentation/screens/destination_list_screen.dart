// import 'package:flutter/material.dart';
// import '../../data/services/destination_service.dart';
// import '../../data/models/destination.dart';
// import '../widgets/destination_card.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/api/api_client.dart';

// class DestinationListScreen extends StatefulWidget {
//   const DestinationListScreen({super.key});

//   @override
//   State<DestinationListScreen> createState() => _DestinationListScreenState();
// }

// class _DestinationListScreenState extends State<DestinationListScreen> {
//   // We use a key or a simple counter to force FutureBuilder to restart
//   int _refreshKey = 0;

//   String _formatImageUrl(String? path) {
//     if (path == null || path.isEmpty || path == "string") {
//       return 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=800';
//     }
//     if (path.startsWith('http')) return path;
//     final rootUrl = ApiClient.baseUrl.replaceFirst('/api', '');
//     return '$rootUrl$path';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: const Text(
//           'All Destinations',
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: const BackButton(color: Colors.black),
//         automaticallyImplyLeading: false,
//       ),
//       body: RefreshIndicator(
//         onRefresh: () async {
//           await DestinationService.popular();
//           setState(() {
//             _refreshKey++; // This triggers a rebuild of the FutureBuilder
//           });
//         },
//         child: FutureBuilder<List<Destination>>(
//           key: ValueKey(_refreshKey), // Important: helps force refresh
//           future: DestinationService.popular(),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (snapshot.hasData) {
//               debugPrint("Destinations found: ${snapshot.data!.length}");
//               for (var d in snapshot.data!) {
//                 debugPrint("Destination Name: ${d.name}");
//               }
//             }

//             if (snapshot.hasError) {
//               debugPrint(
//                 "PARSE ERROR: ${snapshot.error}",
//               ); // Check this in your VS Code/Android Studio console
//               return ListView(
//                 children: [
//                   SizedBox(height: MediaQuery.of(context).size.height * 0.3),
//                   const Icon(Icons.error_outline, size: 48, color: Colors.red),
//                   Center(child: Text('Parsing Error: Check Console')),
//                 ],
//               );
//             }

//             final destinations = snapshot.data ?? [];
//             if (destinations.isEmpty) {
//               return const Center(child: Text('No destinations available.'));
//             }

//             return ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: destinations.length,
//               itemBuilder: (context, index) {
//                 final d = destinations[index];
//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 16),
//                   child: DestinationCard(
//                     data: DestinationCardData(
//                       title: d.name,
//                       subtitle: d.shortDescription,
//                       tag: d.tags.isNotEmpty ? d.tags.first : 'Explore',
//                       tagColor: AppColors.primary,
//                       imageUrl: _formatImageUrl(
//                         d.images.isNotEmpty ? d.images.first : null,
//                       ),
//                       metaIcon: Icons.location_on,
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }


// lib/features/destination/presentation/screens/destination_list_screen.dart
import 'package:flutter/material.dart';
import '../../data/services/destination_service.dart';
import '../../data/models/destination.dart';
import '../widgets/destination_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';

class DestinationListScreen extends StatefulWidget {
  const DestinationListScreen({super.key});

  @override
  State<DestinationListScreen> createState() => _DestinationListScreenState();
}

class _DestinationListScreenState extends State<DestinationListScreen> {
  int _refreshKey = 0;

  String _formatImageUrl(String? path) {
    if (path == null || path.isEmpty || path == "string") {
      return 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=800';
    }
    if (path.startsWith('http')) return path;
    final rootUrl = ApiClient.baseUrl.replaceFirst('/api', '');
    return '$rootUrl$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'All Destinations',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await DestinationService.popular();
          setState(() {
            _refreshKey++;
          });
        },
        child: FutureBuilder<List<Destination>>(
          key: ValueKey(_refreshKey),
          future: DestinationService.popular(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              debugPrint("PARSE ERROR: ${snapshot.error}");
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const Center(child: Text('Error loading destinations')),
                ],
              );
            }

            final destinations = snapshot.data ?? [];
            if (destinations.isEmpty) {
              return const Center(child: Text('No destinations available.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final d = destinations[index];
                return DestinationCard(
                  data: DestinationCardData(
                    title: d.name,
                    location: d.district ?? 'Unknown Location',
                    tag: d.tags.isNotEmpty ? d.tags.first : 'Explore',
                    tagColor: AppColors.primary,
                    imageUrl: _formatImageUrl(
                      d.images.isNotEmpty ? d.images.first : null,
                    ),
                    metaIcon: Icons.location_on,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}