// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../logic/community_provider.dart';

// class CreatePostModal extends StatefulWidget {
//   const CreatePostModal({super.key});

//   @override
//   State<CreatePostModal> createState() => _CreatePostModalState();
// }

// class _CreatePostModalState extends State<CreatePostModal> {
//   final TextEditingController _contentController = TextEditingController();

//   @override
//   void dispose() {
//     _contentController.dispose();
//     super.dispose();
//   }

//   Future<void> _submit() async {
//     final content = _contentController.text.trim();
//     if (content.isEmpty) return;

//     final provider = context.read<CommunityProvider>();
    
//     // Assuming your CommunityProvider has a createPost method
//     final success = await provider.createPostFromRaw(payload); 

//     if (success && mounted) {
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Adventure posted!")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isLoading = context.watch<CommunityProvider>().isCreating; // Add this bool to your provider

//     return Container(
//       padding: EdgeInsets.only(
//         bottom: MediaQuery.of(context).viewInsets.bottom,
//         top: 20, left: 20, right: 20,
//       ),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text("Share Adventure", 
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               IconButton(onPressed: () => Navigator.pop(context), 
//                 icon: const Icon(Icons.close)),
//             ],
//           ),
//           const Divider(),
//           TextField(
//             controller: _contentController,
//             maxLines: 5,
//             autofocus: true,
//             decoration: const InputDecoration(
//               hintText: "What's happening on your trip?",
//               border: InputBorder.none,
//             ),
//           ),
//           const SizedBox(height: 20),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: isLoading ? null : _submit,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//               ),
//               child: isLoading 
//                 ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
//                 : const Text("Post Now", style: TextStyle(color: Colors.white)),
//             ),
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }
// }