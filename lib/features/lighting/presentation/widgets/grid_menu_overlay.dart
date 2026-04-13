import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:miaomiao_fill_light/core/theme/app_theme.dart';
import 'package:miaomiao_fill_light/features/lighting/presentation/widgets/grid_item.dart';

class GridMenuOverlay extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onClose;

  const GridMenuOverlay({
    super.key,
    required this.isVisible,
    required this.onClose,
  });

  @override
  State<GridMenuOverlay> createState() => _GridMenuOverlayState();
}

class _GridMenuOverlayState extends State<GridMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _blurAnimation;
  late Animation<double> _liquidWobble;

  // 手势拖拽相关状态
  double _dragOffset = 0.0;  // 当前拖拽偏移量
  bool _isDragging = false;   // 是否正在拖拽

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Slide from TOP: begin at -1.0 (fully above screen), end at 0.0 (in view)
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.fastLinearToSlowEaseIn,
      ),
    );

    _blurAnimation = Tween<double>(begin: 0.0, end: 25.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _liquidWobble = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.04), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isVisible) _controller.forward();
  }

  @override
  void didUpdateWidget(GridMenuOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.value == 0 && !widget.isVisible) {
          return const SizedBox.shrink();
        }

        final screenHeight = MediaQuery.of(context).size.height;

        return Stack(
          children: [
            // Dark overlay tap to close
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  color: Colors.black.withOpacity(0.45 * _controller.value),
                ),
              ),
            ),

            // Blur overlay
            Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _blurAnimation.value,
                    sigmaY: _blurAnimation.value,
                  ),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),

            // Menu Content — anchored to TOP, slides DOWN
            Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                // 垂直拖拽开始
                onVerticalDragStart: (details) {
                  setState(() {
                    _isDragging = true;
                    _dragOffset = 0.0;
                  });
                },
                // 垂直拖拽更新
                onVerticalDragUpdate: (details) {
                  setState(() {
                    // 向上滑动时 dy < 0
                    _dragOffset += details.delta.dy;
                    // 限制只能向上拖拽（负值）
                    if (_dragOffset > 0) {
                      _dragOffset = 0;
                    }
                  });
                },
                // 垂直拖拽结束
                onVerticalDragEnd: (details) {
                  setState(() {
                    _isDragging = false;
                  });

                  final velocity = details.primaryVelocity ?? 0;

                  // 判断是否应该关闭菜单
                  // 条件1：向上拖拽超过120像素
                  // 条件2：快速向上滑动（速度 < -600）
                  if (_dragOffset < -120 || velocity < -600) {
                    widget.onClose();
                  } else {
                    // 回弹到原位
                    setState(() {
                      _dragOffset = 0.0;
                    });
                  }
                },
                child: Transform.translate(
                  // 组合动画偏移和拖拽偏移
                  offset: Offset(
                    0,
                    _slideAnimation.value * screenHeight * 0.75 + _dragOffset
                  ),
                  child: Transform.scale(
                    scaleY: _liquidWobble.value,
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: screenHeight * 0.78,  // 从 0.72 增加到 0.78
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(28, 50, 28, 20),  // 顶部从60减到50
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(40),
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Drag handle - 拖拽时有视觉反馈
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _isDragging ? 60 : 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(_isDragging ? 0.4 : 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Title
                        Text(
                          'MIAO PHOTO TOOLS',
                          style: TextStyle(
                            color: AppTheme.pearlPink.withOpacity(0.9),
                            fontSize: 16,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'AESTHETIC CAPTURE',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.2),
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 12-Grid
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 3,
                            mainAxisSpacing: 20,  // 从24减到20
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.85,  // 添加宽高比控制
                            physics: const NeverScrollableScrollPhysics(),
                            children: _buildGridItems(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildGridItems() {
    final items = [
      {'label': '全屏预览', 'icon': Icons.fullscreen},
      {'label': '色彩模式', 'icon': Icons.palette_outlined},
      {'label': '画幅比例', 'icon': Icons.aspect_ratio_outlined},
      {'label': '亮度调节', 'icon': Icons.light_mode_outlined},
      {'label': '快门速度', 'icon': Icons.shutter_speed},
      {'label': '定时拍摄', 'icon': Icons.timer_outlined},
      {'label': '自拍模式', 'icon': Icons.face_retouching_natural},
      {'label': '声音开关', 'icon': Icons.volume_up_outlined},
      {'label': '高清画质', 'icon': Icons.high_quality_outlined},
      {'label': '缩放控制', 'icon': Icons.zoom_in_outlined},
      {'label': '心跳捕捉', 'icon': Icons.favorite_border_rounded},
      {'label': '更多设置', 'icon': Icons.more_horiz},
    ];

    return items
        .map((item) => GridItem(
              label: item['label'] as String,
              icon: item['icon'] as IconData,
              onTap: () {},
            ))
        .toList();
  }
}
