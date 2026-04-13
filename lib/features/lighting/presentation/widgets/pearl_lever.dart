import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:miaomiao_fill_light/core/theme/app_theme.dart';

class PearlLever extends StatelessWidget {
  final VoidCallback onTap;
  final bool isOpen;

  const PearlLever({
    super.key,
    required this.onTap,
    this.isOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Cat Ears Background (Glow)
            Positioned(
              top: -6,
              child: CustomPaint(
                size: const Size(60, 30),
                painter: CatEarPainter(),
              ),
            ),
            
            // Glassmorphic Lever Body
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: 140,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 500),
                      turns: isOpen ? 0.5 : 0,
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        color: AppTheme.pearlPink.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CatEarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.vibrantPink.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path();
    
    // Left Ear
    path.moveTo(size.width * 0.2, size.height);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.1,
      size.width * 0.4, size.height * 0.5,
    );
    
    // Right Ear
    path.moveTo(size.width * 0.8, size.height);
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.1,
      size.width * 0.6, size.height * 0.5,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
