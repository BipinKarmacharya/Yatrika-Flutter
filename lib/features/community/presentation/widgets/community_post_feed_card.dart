import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_routes.dart'; 
import '../../data/models/community_post.dart'; // Import the API model

class CommunityPostFeedCard extends StatelessWidget {
  const CommunityPostFeedCard({super.key, required this.post});

  final CommunityPost post; // Changed from CommunityFeed to CommunityPost

  @override
  Widget build(BuildContext context) {
    // Correctly get the full URL from the API client
    final imageUrl = post.coverImageUrl.isNotEmpty 
        ? ApiClient.getFullImageUrl(post.coverImageUrl) 
        : '';
    
    final stopsPlanned = post.days.length;

    return GestureDetector(
      onTap: () {
        context.push(
          AppRoutes.communityPost,
          extra: post, // Pass the whole post object
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageStack(imageUrl),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAuthorRow(),
                    const SizedBox(height: 10),
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    _buildStatsRow(stopsPlanned),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageStack(String imageUrl) {
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageUrl.isNotEmpty
              ? Image.network(imageUrl, fit: BoxFit.cover)
              : Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 48, color: Colors.grey)),
          Positioned(
            left: 12, top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(18)),
              child: const Text("ADVENTURE", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorRow() {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: NetworkImage(ApiClient.getFullImageUrl(post.authorAvatar ?? '')),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const Text("Just now", style: TextStyle(color: AppColors.subtext, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(int stops) {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.subtext),
        const SizedBox(width: 4),
        Text('$stops days trip', style: const TextStyle(color: AppColors.subtext, fontSize: 12)),
        const Spacer(),
        const Icon(Icons.favorite_border, size: 18, color: AppColors.subtext),
        const SizedBox(width: 4),
        Text('${post.totalLikes}', style: const TextStyle(color: AppColors.subtext, fontSize: 12)),
      ],
    );
  }
}