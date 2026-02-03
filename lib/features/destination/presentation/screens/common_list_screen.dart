// import 'package:flutter/material.dart';
// import 'package:tour_guide/features/destination/data/models/destination.dart';
// import '../widgets/destination_card.dart';

// class CommonListScreen extends StatelessWidget {
//   final String title;
//   final Future<List<Destination>> future;

//   const CommonListScreen({
//     super.key,
//     required this.title,
//     required this.future,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//       ),
//       body: FutureBuilder<List<Destination>>( // ← FIXED: Changed to List<Destination>
//         future: future,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           final List<Destination> items = snapshot.data ?? []; // ← Simplified

//           if (items.isEmpty) {
//             return const Center(child: Text("No destinations found"));
//           }

//           return GridView.builder(
//             padding: const EdgeInsets.all(16),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               childAspectRatio: 0.7,
//               crossAxisSpacing: 12,
//               mainAxisSpacing: 12,
//             ),
//             itemCount: items.length,
//             itemBuilder: (context, index) => DestinationCard(
//               destination: items[index],
//               isGrid: true,
//             ),
//           );
//         },
//       ),
//     );
//   }
// }