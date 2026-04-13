import 'package:flutter/material.dart';
import 'package:miaomiao_fill_light/core/theme/app_theme.dart';

class GridItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const GridItem({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.pearlPink.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Center(
              // Simulating 0.5pt thin icon using CustomPainter helper
              child: CustomPaint(
                size: const Size(28, 28),
                painter: ThinIconPainter(icon: icon),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// A helper to draw Material Icons with an extremely thin 0.5pt stroke style.
class ThinIconPainter extends CustomPainter {
  final IconData icon;

  ThinIconPainter({required this.icon});

  @override
  void paint(Canvas canvas, Size size) {
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size.width,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        // We use a very light color and transparency to mimic thinness
        // Real 0.5pt stroke on a filled font is achieved by drawing it with a stroke style
        foreground: Paint()
          ..color = AppTheme.pearlPink.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
