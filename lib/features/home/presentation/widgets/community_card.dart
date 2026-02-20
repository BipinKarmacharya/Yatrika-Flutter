import 'package:flutter/material.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/community/data/models/community_post.dart' as CP;

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
        border: Border.all(color: AppColors.stroke.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Post Image (Left Side)
          _buildPostImage(),
          const SizedBox(width: 16),
          // 2. Post Content & Details (Right Side)
          Expanded(child: _buildPostContent()),
        ],
      ),
    );
  }

  Widget _buildPostImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 90,
        height: 90,
        child: post.coverImageUrl.isEmpty
            ? Container(color: Colors.grey[100], child: const Icon(Icons.image_outlined))
            : Image.network(
                post.coverImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[100]),
              ),
      ),
    );
  }

  Widget _buildPostContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 4),
        // Author Row
        Row(
          children: [
            CircleAvatar(
              radius: 9,
              backgroundImage: post.authorAvatar != null ? NetworkImage(post.authorAvatar!) : null,
              child: post.authorAvatar == null ? const Icon(Icons.person, size: 10) : null,
            ),
            const SizedBox(width: 6),
            Text("@${post.authorName}", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 12),
        // Interaction Row (Likes, Comments, Date)
        _buildFooter(),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(
          post.isLiked ? Icons.favorite : Icons.favorite_border,
          size: 16,
          color: post.isLiked ? Colors.redAccent : AppColors.subtext,
        ),
        const SizedBox(width: 4),
        Text("${post.totalLikes}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.subtext),
        const SizedBox(width: 4),
        Text("${post.totalComments}", style: const TextStyle(fontSize: 11)),
        const Spacer(),
        Text(post.formattedDate, style: const TextStyle(color: AppColors.subtext, fontSize: 10)),
      ],
    );
  }
}