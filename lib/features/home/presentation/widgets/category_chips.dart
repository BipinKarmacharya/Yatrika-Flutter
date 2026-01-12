import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key, required this.chips});

  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: i == 0
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : const Color(0xFFE6F2ED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                chips[i],
                style: TextStyle(
                  color: i == 0 ? AppColors.primary : const Color(0xFF4D7358),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
         ],
      ),
    );
  }
}
