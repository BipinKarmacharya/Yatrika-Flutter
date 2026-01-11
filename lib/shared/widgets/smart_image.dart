import 'package:flutter/material.dart';
import '../../core/api/api_client.dart'; // Import your ApiClient
import '../../core/theme/app_colors.dart';

class SmartImage extends StatelessWidget {
  final String url;
  final String heroTag;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  const SmartImage({
    super.key,
    required this.url,
    required this.heroTag,
    this.height,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // 💡 Transform the relative path to a full ngrok URL here
    final String fullUrl = ApiClient.getFullImageUrl(url);

    return Hero(
      tag: heroTag,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.network(
          fullUrl, // Use the resolved URL
          height: height,
          width: width,
          fit: BoxFit.cover,
          headers: const {"ngrok-skip-browser-warning": "true"},
          // 💡 Important for ngrok: sometimes it takes time to wake up
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: height,
              width: width,
              color: AppColors.stroke.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint("Image Error ($fullUrl): $error");
            return Container(
              height: height,
              width: width,
              color: AppColors.stroke,
              child: const Icon(Icons.broken_image, color: AppColors.subtext),
            );
          },
        ),
      ),
    );
  }
}
