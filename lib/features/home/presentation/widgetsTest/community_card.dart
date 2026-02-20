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
          _buildHeroImage(),
          const SizedBox(width: 16),
          Expanded(child: _buildPostDetails()),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
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

  Widget _buildPostDetails() {
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
        Text(
          post.content,
          style: const TextStyle(color: AppColors.subtext, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
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