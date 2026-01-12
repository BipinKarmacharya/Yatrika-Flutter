import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class FeatureCardData {
  // ✅ Update constructor to accept title, icon, and the optional onTap
  const FeatureCardData(this.title, this.icon, {this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback? onTap; 
}

class FeatureCardsRow extends StatelessWidget {
  const FeatureCardsRow({super.key, required this.cards});

  final List<FeatureCardData> cards;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Prevents the row from feeling "stuck" at the edges
      physics: const BouncingScrollPhysics(), 
      child: Row(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: SizedBox(width: 140, child: _FeatureCard(card: card)),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.card});

  final FeatureCardData card;

  @override
  Widget build(BuildContext context) {
    // ✅ Wrap in InkWell to make the card actually clickable
    return InkWell(
      onTap: card.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(card.icon, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              card.title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}