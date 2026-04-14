import 'package:flutter/material.dart';
import 'package:miaomiao_fill_light/core/theme/app_theme.dart';
import 'dart:io';

/// Shortcut toolbar row: Thumbnail | Shutter | Filter | Timer
class ShortcutToolbar extends StatelessWidget {
  final VoidCallback onShutter;
  final VoidCallback? onShutterLongPressStart;
  final VoidCallback? onShutterLongPressEnd;
  final VoidCallback? onFilterTap;
  final VoidCallback? onTimerTap;
  final String? recentPhotoPath;
  final VoidCallback? onThumbnailTap;

  const ShortcutToolbar({
    super.key,
    required this.onShutter,
    this.onShutterLongPressStart,
    this.onShutterLongPressEnd,
    this.onFilterTap,
    this.onTimerTap,
    this.recentPhotoPath,
    this.onThumbnailTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail preview
          GestureDetector(
            onTap: onThumbnailTap,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                border: Border.all(
                  color: AppTheme.pearlPink.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: recentPhotoPath != null
                  ? ClipOval(
                      child: Image.file(
                        File(recentPhotoPath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white.withOpacity(0.3),
                      size: 24,
                    ),
            ),
          ),
          // Central shutter button
          GestureDetector(
            onTap: onShutter,
            onLongPressStart: (_) => onShutterLongPressStart?.call(),
            onLongPressEnd: (_) => onShutterLongPressEnd?.call(),
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
          _ToolBtn(
              icon: Icons.color_lens_outlined,
              label: '滤镜',
              onTap: onFilterTap ?? () {}),
          _ToolBtn(
              icon: Icons.timer_outlined,
              label: '定时',
              onTap: onTimerTap ?? () {}),
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
