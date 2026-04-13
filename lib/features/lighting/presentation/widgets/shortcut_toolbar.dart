import 'package:flutter/material.dart';
import 'package:miaomiao_fill_light/core/theme/app_theme.dart';

/// Shortcut toolbar row: Beauty | Shutter | Filter | Timer
class ShortcutToolbar extends StatelessWidget {
  final VoidCallback onShutter;

  const ShortcutToolbar({super.key, required this.onShutter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ToolBtn(
              icon: Icons.auto_fix_high_outlined, label: '美颜', onTap: () {}),
          // Central shutter button
          GestureDetector(
            onTap: onShutter,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFFB3D1),
                    AppTheme.vibrantPink,
                    Color(0xFFD4006A),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.vibrantPink.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt_outlined,
                  color: Colors.white, size: 28),
            ),
          ),
          _ToolBtn(icon: Icons.color_lens_outlined, label: '滤镜', onTap: () {}),
          _ToolBtn(icon: Icons.timer_outlined, label: '定时', onTap: () {}),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
