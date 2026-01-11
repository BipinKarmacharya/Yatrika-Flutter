import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
// sdds
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onItemSelected,
  });

  final int currentIndex;
  final ValueChanged<int>? onItemSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            label: 'Home',
            icon: Icons.home_outlined,
            active: currentIndex == 0,
            onTap: () => onItemSelected?.call(0),
          ),
          _BottomNavItem(
            label: 'Discover',
            icon: Icons.search,
            active: currentIndex == 1,
            onTap: () => onItemSelected?.call(1),
          ),
          _BottomNavItem(
            label: 'Plan',
            icon: Icons.add_circle_outline,
            active: currentIndex == 2,
            onTap: () => onItemSelected?.call(2),
          ),
          _BottomNavItem(
            label: 'Posts',
            icon: Icons.article_outlined,
            active: currentIndex == 3,
            onTap: () => onItemSelected?.call(3),
          ),
          _BottomNavItem(
            label: 'Profile',
            icon: Icons.person_outline,
            active: currentIndex == 4,
            onTap: () => onItemSelected?.call(4),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    this.active = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : const Color(0xFF6B7280);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 