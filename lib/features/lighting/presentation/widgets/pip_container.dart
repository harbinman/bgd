import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:miaomiao_fill_light/core/theme/app_theme.dart';

class PipContainer extends StatefulWidget {
  final CameraController? controller;
  final Size screenSize;

  const PipContainer({
    super.key,
    this.controller,
    required this.screenSize,
  });

  @override
  State<PipContainer> createState() => _PipContainerState();
}

class _PipContainerState extends State<PipContainer> {
  Offset _position = const Offset(20, 20);
  final double _pipWidth = 120.0;
  final double _pipHeight = 160.0; // 3:4 portrait

  @override
  void initState() {
    super.initState();
    _position = Offset(
      widget.screenSize.width - _pipWidth - 20,
      widget.screenSize.height - _pipHeight - 190, // above toolbar+tabbar
    );
  }

  void _snapToCorner() {
    double x = _position.dx;
    double y = _position.dy;

    x = (x + _pipWidth / 2 < widget.screenSize.width / 2)
        ? 20
        : widget.screenSize.width - _pipWidth - 20;

    y = (y + _pipHeight / 2 < widget.screenSize.height / 2)
        ? 80
        : widget.screenSize.height - _pipHeight - 190;

    setState(() => _position = Offset(x, y));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.screenSize.width == 0) return const SizedBox.shrink();

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (d) => setState(() => _position += d.delta),
        onPanEnd: (_) => _snapToCorner(),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            borderRadius: 12,
            color: AppTheme.vibrantPink.withOpacity(0.7),
            dashWidth: 6,
            dashSpace: 4,
            strokeWidth: 1.2,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12), // P2: 12dp
            child: Container(
              width: _pipWidth,
              height: _pipHeight,
              color: Colors.black,
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final hasController =
        widget.controller != null && widget.controller!.value.isInitialized;

    if (hasController) {
      // 使用 ClipRect + FittedBox 确保相机画面填满容器且不失真
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FittedBox(
          fit: BoxFit.cover,  // 填充容器，保持比例，可能裁剪
          child: SizedBox(
            width: widget.controller!.value.previewSize!.height,
            height: widget.controller!.value.previewSize!.width,
            child: CameraPreview(widget.controller!),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Faint cat background
        Image.asset(
          'assets/images/onboarding_cat.png',
          fit: BoxFit.cover,
          opacity: const AlwaysStoppedAnimation(0.12),
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off_outlined,
                  color: AppTheme.pearlPink.withOpacity(0.4), size: 22),
              const SizedBox(height: 6),
              Text('MIAO CAM',
                  style: TextStyle(
                    color: AppTheme.pearlPink.withOpacity(0.25),
                    fontSize: 9,
                    letterSpacing: 2,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for dashed rounded-rectangle border
class _DashedBorderPainter extends CustomPainter {
  final double borderRadius;
  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  const _DashedBorderPainter({
    required this.borderRadius,
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashPath = _createDashedPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source, double dashLength, double dashGap) {
    final result = Path();
    final metrics = source.computeMetrics().toList();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = distance + dashLength > metric.length
            ? metric.length - distance
            : dashLength;
        result.addPath(
          metric.extractPath(distance, distance + len),
          Offset.zero,
        );
        distance += dashLength + dashGap;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.dashWidth != dashWidth;
}
