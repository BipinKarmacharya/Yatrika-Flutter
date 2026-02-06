import 'package:flutter/material.dart';
import 'package:tour_guide/features/destination/data/models/destination.dart' as MD;
import 'package:tour_guide/features/community/data/models/community_post.dart' as CP;

class RecommendationCard extends StatelessWidget {
  final MD.Destination destination;
  const RecommendationCard({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    final imageUrl = destination.images.isNotEmpty ? destination.images.first : null;
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (imageUrl != null)
                Image.network(imageUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover)
              else
                Container(color: Colors.grey[200], child: const Icon(Icons.photo_outlined, size: 40)),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(destination.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(destination.district ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommunityCard extends StatelessWidget {
  final CP.CommunityPost post;
  const CommunityCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 90,
              height: 90,
              child: _buildPostImage(post.coverImageUrl),
            ),
          ),
          const SizedBox(width: 16),
          // Post Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                // ✅ Added Date
                Text(
                  post.formattedDate,
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: post.authorAvatar != null 
                          ? NetworkImage(post.authorAvatar!) 
                          : null,
                      child: post.authorAvatar == null 
                          ? const Icon(Icons.person, size: 12, color: Colors.grey) 
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        post.authorName, // Now shows "imbipin" instead of "Guest"
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 14, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Text("${post.totalLikes}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    const Icon(Icons.mode_comment_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("${post.totalComments}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage(String url) {
    if (url.isEmpty) return Container(color: Colors.grey[200]);
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => 
          Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 20)),
    );
  }
}

// class CommunityCard extends StatelessWidget {
//   final CP.CommunityPost post;
//   const CommunityCard({super.key, required this.post});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(16),
//             child: SizedBox(
//             width: 85,
//             height: 85,
//             child: _buildPostImage(post.coverImageUrl),
//           ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
//                 const SizedBox(height: 6),
//                 Row(
//                   children: [
//                     CircleAvatar(radius: 10, backgroundImage: NetworkImage(post.authorAvatar ?? 'https://via.placeholder.com/20')),
//                     const SizedBox(width: 6),
//                     Text("by ${post.authorName}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     const Icon(Icons.favorite_border, size: 14, color: Colors.grey),
//                     const SizedBox(width: 4),
//                     Text("${post.totalLikes}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
//                   ],
//                 )
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }


//   Widget _buildPostImage(String url) {
//   if (url.isEmpty || !url.startsWith('http')) {
//     return Container(color: Colors.grey[200], child: const Icon(Icons.broken_image));
//   }
//   return Image.network(
//     url,
//     fit: BoxFit.cover,
//     errorBuilder: (context, error, stackTrace) => 
//         Container(color: Colors.grey[200], child: const Icon(Icons.warning_amber_rounded)),
//   );
// }
