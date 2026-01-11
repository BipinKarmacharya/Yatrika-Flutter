// import 'package:flutter/material.dart';

// import '../../../../ui/components/app_colors.dart';

// // bjsdbfds
// class CommunityPostData {
//   const CommunityPostData({
//     required this.title,
//     required this.author,
//     required this.likes,
//     required this.comments,
//     required this.imageUrl,
//     required this.accent,
//   });

//   final String title;
//   final String author;
//   final int likes;
//   final int comments;
//   final String imageUrl;
//   final Color accent;
// }

// class CommunityPostCard extends StatelessWidget {
//   const CommunityPostCard({super.key, required this.post});

//   final CommunityPostData post;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 96,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           ClipRRect(
//             borderRadius: const BorderRadius.only(
//               topLeft: Radius.circular(12),
//               bottomLeft: Radius.circular(12),
//             ),
//             child:
//                 post
//                     .imageUrl
//                     .isEmpty // ✅ Added safety check
//                 ? Container(
//                     width: 88,
//                     height: double.infinity,
//                     color: Colors.grey[200],
//                     child: const Icon(
//                       Icons.image_not_supported,
//                       color: Colors.grey,
//                     ),
//                   )
//                 : Image.network(
//                     post.imageUrl,
//                     width: 88,
//                     height: double.infinity,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) => Container(
//                       width: 88,
//                       color: Colors.grey[200],
//                       child: const Icon(Icons.broken_image, color: Colors.grey),
//                     ),
//                   ),
//           ),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     post.title,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w700,
//                       fontSize: 15,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       Flexible(
//                         child: Text(
//                           'by ${post.author}',
//                           style: const TextStyle(
//                             color: AppColors.subtext,
//                             fontSize: 13,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       const Icon(
//                         Icons.favorite_border,
//                         size: 16,
//                         color: Color(0xFF9CA3AF),
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         '${post.likes}',
//                         style: const TextStyle(
//                           color: AppColors.subtext,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       const Icon(
//                         Icons.chat_bubble_outline,
//                         size: 16,
//                         color: Color(0xFF9CA3AF),
//                       ),
//                       const SizedBox(width: 4),
//                       Flexible(
//                         child: Text(
//                           '${post.comments} comments',
//                           style: const TextStyle(
//                             color: AppColors.subtext,
//                             fontSize: 12,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.only(right: 12),
//             child: Container(
//               width: 18,
//               height: 18,
//               decoration: BoxDecoration(
//                 color: post.accent,
//                 shape: BoxShape.circle,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';

import 'package:tour_guide/core/theme/app_colors.dart';

// bjsdbfds
class CommunityPostData {
  const CommunityPostData({
    required this.title,
    required this.author,
    required this.likes,
    required this.comments,
    required this.imageUrl,
    required this.accent,
  });

  final String title;
  final String author;
  final int likes;
  final int comments;
  final String imageUrl;
  final Color accent;
}

class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({super.key, required this.post});

  final CommunityPostData post;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child:
                post
                    .imageUrl
                    .isEmpty // ✅ Added safety check
                ? Container(
                    width: 88,
                    height: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  )
                : Image.network(
                    post.imageUrl,
                    width: 88,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 88,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'by ${post.author}',
                          style: const TextStyle(
                            color: AppColors.subtext,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likes}',
                        style: const TextStyle(
                          color: AppColors.subtext,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${post.comments} comments',
                          style: const TextStyle(
                            color: AppColors.subtext,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: post.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}