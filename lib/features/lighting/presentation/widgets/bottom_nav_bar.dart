import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:miaomiao_fill_light/core/theme/app_theme.dart';

/// Bottom 4-tab navigation bar: Home | Fill Light (active) | Filters | Gallery
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  isActive: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.favorite,
                  label: 'Fill Light',
                  isActive: currentIndex == 1,
                  onTap: () => onTap(1),
                  isHeart: true,
                ),
                _NavItem(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Filters',
                  isActive: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  isActive: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isHeart;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isHeart = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.vibrantPink : Colors.white38;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active indicator dot above icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              width: isActive ? 20 : 0,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: AppTheme.vibrantPink,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(icon, color: color, size: isHeart ? 22 : 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                letterSpacing: 0.2,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
