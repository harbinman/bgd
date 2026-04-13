import 'package:flutter/material.dart';
import 'package:miaomiao_fill_light/core/theme/app_theme.dart';

class HeartPainter extends CustomPainter {
  final double pulse;

  HeartPainter({this.pulse = 1.0});

  /// pulse is in range [0.85, 1.15] — clamp to [0.0, 1.0] for opacity usage.
  double get _p => pulse.clamp(0.0, 1.0);

  Path _heartPath(Offset center, double side) {
    final path = Path();
    path.moveTo(center.dx, center.dy - side * 0.35);
    path.cubicTo(
      center.dx - side * 0.7,
      center.dy - side * 1.0,
      center.dx - side * 1.2,
      center.dy + side * 0.1,
      center.dx,
      center.dy + side * 0.9,
    );
    path.cubicTo(
      center.dx + side * 1.2,
      center.dy + side * 0.1,
      center.dx + side * 0.7,
      center.dy - side * 1.0,
      center.dx,
      center.dy - side * 0.35,
    );
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 10 || size.height < 10) return;

    final center = Offset(size.width / 2, size.height / 2 - size.height * 0.05);
    final side = size.width * 0.40; // ~80% of screen width total

    final path = _heartPath(center, side);

    // ── Layer 1: Background ambient halo ──────────────────────────────────────
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.vibrantPink.withOpacity((0.18 * _p).clamp(0.0, 1.0))
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, (80 * pulse).clamp(10.0, 120.0)),
    );

    // ── Layer 2: Radial gradient fill ─────────────────────────────────────────
    canvas.save();
    canvas.clipPath(path);
    final bounds = path.getBounds();
    if (bounds.width > 1 && bounds.height > 1) {
      final shader = RadialGradient(
        center: const Alignment(0, -0.15),
        radius: 0.65,
        colors: [
          Colors.white.withOpacity((0.95 * _p).clamp(0.0, 1.0)),
          AppTheme.pearlPink.withOpacity((0.90 * _p).clamp(0.0, 1.0)),
          AppTheme.vibrantPink.withOpacity((0.85 * _p).clamp(0.0, 1.0)),
          const Color(0xFF8B0050).withOpacity((0.70 * _p).clamp(0.0, 1.0)),
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(bounds.inflate(2));
      canvas.drawRect(
        bounds.inflate(2),
        Paint()..shader = shader,
      );
    }
    canvas.restore();

    // ── Layer 3: Outer glow stroke ────────────────────────────────────────────
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.vibrantPink.withOpacity((0.55 * _p).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (30.0 * pulse).clamp(20.0, 40.0)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, (25.0 * pulse).clamp(15.0, 35.0)),
    );

    // ── Layer 4: Crisp white edge ─────────────────────────────────────────────
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round,
    );

    // ── Layer 5: Bottom screen ambient arc ───────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.85),
        width: size.width * 1.2,
        height: size.height * 0.22,
      ),
      Paint()
        ..color = AppTheme.vibrantPink.withOpacity((0.12 * _p).clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );
  }

  @override
  bool shouldRepaint(covariant HeartPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}
