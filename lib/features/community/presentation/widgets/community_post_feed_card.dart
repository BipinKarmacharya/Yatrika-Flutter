import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/auth/logic/auth_provider.dart';
import 'package:tour_guide/features/community/logic/community_provider.dart';
import 'package:tour_guide/features/community/presentation/screens/community_post_detail_screen.dart';
import 'package:tour_guide/features/community/presentation/widgets/create_post_modal.dart';
import '../../../../core/api/api_client.dart';
import '../../data/models/community_post.dart';
import 'package:intl/intl.dart';

class CommunityPostFeedCard extends StatefulWidget {
  final CommunityPost post;
  const CommunityPostFeedCard({super.key, required this.post});

  @override
  State<CommunityPostFeedCard> createState() => _CommunityPostFeedCardState();
}

class _CommunityPostFeedCardState extends State<CommunityPostFeedCard> {
  final PageController _pageController = PageController();

  // 1. Navigation Helper
  void _navigateToDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityPostDetailScreen(post: widget.post),
      ),
    );
  }

  // Helper to generate a shareable link
  void _handleShare() {
    final String postLink =
        "${ApiClient.baseUrl}/community/post/${widget.post.id}";
    Share.share(
      "Check out this journey to ${widget.post.destination} on Yatrika: $postLink",
      subject: widget.post.title,
    );
  }

  // Existing helpers...
  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return "https://via.placeholder.com/400x300";
    }
    if (path.startsWith('http')) return path;
    return '${ApiClient.baseUrl}$path';
  }

  String _getRelativeTime(String? dateStr) {
    if (dateStr == null) return "";
    try {
      DateTime date = DateTime.parse(dateStr);
      Duration diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      if (diff.inDays < 7) return "${diff.inDays}d ago";
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return "";
    }
  }

  void _showOwnPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text("Edit Post"),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (context) => CreatePostModal(postToEdit: widget.post),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              "Delete Story",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              _confirmDeletion(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Story?"),
        content: const Text("This action cannot be undone. Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final provider = context.read<CommunityProvider>();
              Navigator.pop(ctx); // Close Dialog

              final success = await provider.deletePost(widget.post.id!);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Post deleted successfully")),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // Double check: Compare IDs to see if this post belongs to the logged-in user
    final bool isOwnPost =
        auth.user != null &&
        auth.user!.id.toString() == widget.post.user?.id.toString();

    return GestureDetector(
      onTap: _navigateToDetails, // Entire card is clickable
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Author Header
            ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(
                  _getImageUrl(widget.post.user?.profileImage),
                ),
              ),
              title: Text(
                isOwnPost
                    ? "You"
                    : "@${widget.post.user?.username ?? 'traveler'}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "${widget.post.destination} • ${_getRelativeTime(widget.post.createdAt)}",
              ),
              trailing: isOwnPost
                  ? _buildMenuButton() // Three dots for Edit/Delete
                  : _buildFollowButton(), // Follow button for others
            ),

            // 2. Media Section
            SizedBox(
              height: 300,
              width: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.post.media.isNotEmpty
                    ? widget.post.media.length
                    : 1,
                itemBuilder: (ctx, i) {
                  final url = widget.post.media.isNotEmpty
                      ? widget.post.media[i].mediaUrl
                      : widget.post.coverImageUrl;
                  return CachedNetworkImage(
                    imageUrl: _getImageUrl(url),
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),

            // 3. Interaction Bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      // Corrected: Passing the toggleLike function to the action item
                      _buildActionItem(
                        icon: widget.post.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: "${widget.post.totalLikes}",
                        color: widget.post.isLiked
                            ? Colors.red
                            : Colors.black87,
                        onTap: () => context
                            .read<CommunityProvider>()
                            .toggleLike(widget.post.id!),
                      ),
                      const SizedBox(width: 20),
                      const Icon(Icons.mode_comment_outlined, size: 22),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: _handleShare,
                        child: const Icon(Icons.share_outlined, size: 22),
                      ),
                      const Spacer(),
                      // ONLY show bookmark if it is NOT the user's own post
                      if (!isOwnPost)
                        const Icon(Icons.bookmark_border, size: 24),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Sub-Widgets for Clarity ---

  Widget _buildFollowButton() {
    if (widget.post.user == null) return const SizedBox.shrink();
    return TextButton(
      onPressed: () =>
          context.read<CommunityProvider>().toggleFollow(widget.post.user!.id),
      child: Text(
        widget.post.user!.isFollowing ? "Following" : "Follow",
        style: TextStyle(
          color: widget.post.user!.isFollowing
              ? Colors.grey
              : AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    return IconButton(
      icon: const Icon(Icons.more_vert),
      onPressed: () => _showOwnPostMenu(context),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap, // Correctly using the passed onTap function
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart'; // Add this to pubspec.yaml
// import 'package:tour_guide/core/theme/app_colors.dart';
// import 'package:tour_guide/features/auth/logic/auth_provider.dart';
// import 'package:tour_guide/features/community/logic/community_provider.dart';
// import '../../../../core/api/api_client.dart';
// import '../../data/models/community_post.dart';
// import 'package:intl/intl.dart';

// class CommunityPostFeedCard extends StatefulWidget {
//   final CommunityPost post;
//   const CommunityPostFeedCard({super.key, required this.post});

//   @override
//   State<CommunityPostFeedCard> createState() => _CommunityPostFeedCardState();
// }

// class _CommunityPostFeedCardState extends State<CommunityPostFeedCard> {
//   final PageController _pageController = PageController();

//   // Helper to generate a shareable link
//   void _handleShare() {
//     final String postLink =
//         "${ApiClient.baseUrl}/community/post/${widget.post.id}";
//     Share.share(
//       "Check out this journey to ${widget.post.destination} on Yatrika: $postLink",
//       subject: widget.post.title,
//     );
//   }

//   // Existing helpers...
//   String _getImageUrl(String? path) {
//     if (path == null || path.isEmpty) {
//       return "https://via.placeholder.com/400x300";
//     }
//     if (path.startsWith('http')) return path;
//     return '${ApiClient.baseUrl}$path';
//   }



//   String _getRelativeTime(String? dateStr) {
//     if (dateStr == null) return "";
//     DateTime date = DateTime.parse(dateStr);
//     Duration diff = DateTime.now().difference(date);
//     if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
//     if (diff.inHours < 24) return "${diff.inHours}h ago";
//     if (diff.inDays < 7) return "${diff.inDays}d ago";
//     return DateFormat('MMM d').format(date);
//   }

//   void _showOwnPostMenu(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const SizedBox(height: 8),
//           Container(
//             width: 40,
//             height: 4,
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.edit_outlined),
//             title: const Text("Edit Post"),
//             onTap: () {
//               Navigator.pop(context);
//               // TODO: Navigate to Edit Screen
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.delete_outline, color: Colors.red),
//             title: const Text(
//               "Delete Story",
//               style: TextStyle(color: Colors.red),
//             ),
//             onTap: () {
//               Navigator.pop(context);
//               _confirmDeletion(context);
//             },
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   void _confirmDeletion(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Delete Story?"),
//         content: const Text("This action cannot be undone. Are you sure?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () {
//               // Call your provider to delete
//               // context.read<CommunityProvider>().deletePost(widget.post.id!);
//               Navigator.pop(ctx);
//             },
//             child: const Text("Delete", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthProvider>();
//     // Double check: Compare IDs to see if this post belongs to the logged-in user
//     final bool isOwnPost =
//         auth.user != null &&
//         auth.user!.id.toString() == widget.post.user?.id.toString();

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // 1. Author Header
//           ListTile(
//             leading: CircleAvatar(
//               backgroundImage: CachedNetworkImageProvider(
//                 _getImageUrl(widget.post.user?.profileImage),
//               ),
//             ),
//             title: Text(
//               isOwnPost
//                   ? "You"
//                   : "@${widget.post.user?.username ?? 'traveler'}",
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//             subtitle: Text(
//               "${widget.post.destination} • ${_getRelativeTime(widget.post.createdAt)}",
//             ),
//             trailing: isOwnPost
//                 ? _buildMenuButton() // Three dots for Edit/Delete
//                 : _buildFollowButton(), // Follow button for others
//           ),

//           // 2. Media Section
//           SizedBox(
//             height: 300,
//             width: double.infinity,
//             child: PageView.builder(
//               controller: _pageController,
//               itemCount: widget.post.media.length,
//               itemBuilder: (ctx, i) => CachedNetworkImage(
//                 imageUrl: _getImageUrl(widget.post.media[i].mediaUrl),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),

//           // 3. Interaction Bar
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.post.title,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   widget.post.content,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 15),
//                 Row(
//                   children: [
//                     _buildActionItem(
//                       icon: widget.post.isLiked
//                           ? Icons.favorite
//                           : Icons.favorite_border,
//                       label: "${widget.post.totalLikes}",
//                       color: widget.post.isLiked ? Colors.red : Colors.black87,
//                       onTap: () => context.read<CommunityProvider>().toggleLike(
//                         widget.post.id!,
//                       ),
//                     ),
//                     const SizedBox(width: 20),
//                     const Icon(Icons.mode_comment_outlined, size: 22),
//                     const SizedBox(width: 20),
//                     GestureDetector(
//                       onTap: _handleShare,
//                       child: const Icon(Icons.share_outlined, size: 22),
//                     ),
//                     const Spacer(),
//                     // ONLY show bookmark if it is NOT the user's own post
//                     if (!isOwnPost) const Icon(Icons.bookmark_border, size: 24),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- Sub-Widgets for Clarity ---

//   Widget _buildFollowButton() {
//     if (widget.post.user == null) return const SizedBox.shrink();
//     return TextButton(
//       onPressed: () =>
//           context.read<CommunityProvider>().toggleFollow(widget.post.user!.id),
//       child: Text(
//         widget.post.user!.isFollowing ? "Following" : "Follow",
//         style: TextStyle(
//           color: widget.post.user!.isFollowing
//               ? Colors.grey
//               : AppColors.primary,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   Widget _buildMenuButton() {
//     return IconButton(
//       icon: const Icon(Icons.more_vert),
//       onPressed: () {
//         // Show Bottom Sheet for Edit/Delete
//       },
//     );
//   }

//   Widget _buildActionItem({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: () => _showOwnPostMenu(context),
//       child: Row(
//         children: [
//           Icon(icon, color: color, size: 22),
//           const SizedBox(width: 5),
//           Text(
//             label,
//             style: TextStyle(color: color, fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }
// }
