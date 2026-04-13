import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:miaomiao_fill_light/core/theme/app_theme.dart';
import 'package:miaomiao_fill_light/features/lighting/presentation/widgets/heart_painter.dart';
import 'package:miaomiao_fill_light/features/lighting/presentation/widgets/pip_container.dart';
import 'package:miaomiao_fill_light/features/lighting/presentation/widgets/grid_menu_overlay.dart';
import 'package:miaomiao_fill_light/features/lighting/presentation/widgets/shortcut_toolbar.dart';
import 'package:miaomiao_fill_light/features/lighting/presentation/widgets/bottom_nav_bar.dart';

class LightingPage extends StatefulWidget {
  const LightingPage({super.key});

  @override
  State<LightingPage> createState() => _LightingPageState();
}

class _LightingPageState extends State<LightingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isMenuVisible = false;
  int _currentTabIndex = 1; // Fill Light tab active by default

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Delay permission request so first frame renders first
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _checkAndRequestPermissions();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkAndRequestPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.photos,
    ].request();

    final cameraOk = statuses[Permission.camera]!.isGranted;
    final photosOk = statuses[Permission.photos]!.isGranted ||
        statuses[Permission.photos]!.isLimited;

    if (cameraOk && photosOk) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ 补光引擎已就绪'),
            backgroundColor: AppTheme.vibrantPink,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (statuses[Permission.camera]!.isPermanentlyDenied ||
        statuses[Permission.photos]!.isPermanentlyDenied) {
      _showOpenSettingsDialog();
    }
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.charcoal,
        title: const Text('需要相关权限', style: TextStyle(color: Colors.white)),
        content: const Text(
          '请在系统设置中开启相机和相册权限，以体验完整补光拍摄功能。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('了解', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vibrantPink),
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Subtle radial bg ─────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.1),
                radius: 0.9,
                colors: [Color(0xFF180510), Colors.black],
              ),
            ),
          ),

          // ── 2.1 Heart Catchlight Engine ──────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) => CustomPaint(
                painter: HeartPainter(pulse: _pulseAnimation.value),
                child: Container(),
              ),
            ),
          ),

          // ── Brand watermark ─────────────────────────────────────────────
          Positioned(
            top: safePadding.top + 52,
            left: 0,
            right: 0,
            child: Center(
              child: IgnorePointer(
                child: Text(
                  'MIAO LIGHT',
                  style: TextStyle(
                    color: AppTheme.pearlPink.withOpacity(0.35),
                    fontSize: 13,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ),

          // ── Top bar: grid trigger (↓) + settings ────────────────────────
          Positioned(
            top: safePadding.top + 8,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ↓ Pull-down indicator to open 12-grid menu
                  GestureDetector(
                    onTap: () =>
                        setState(() => _isMenuVisible = !_isMenuVisible),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                            _isMenuVisible ? 0.12 : 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedRotation(
                            turns: _isMenuVisible ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.pearlPink.withOpacity(0.8),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '工具',
                            style: TextStyle(
                              color: AppTheme.pearlPink.withOpacity(0.7),
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Settings icon
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white54, size: 22),
                  ),
                ],
              ),
            ),
          ),

          // ── 2.2 PIP Container ────────────────────────────────────────────
          PipContainer(screenSize: screenSize),

          // ── Bottom action zone ───────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // P1.1 Shortcut toolbar
                ShortcutToolbar(onShutter: () {}),
                const SizedBox(height: 14),
                // P1.2 Bottom Tab Bar
                SafeArea(
                  top: false,
                  child: BottomNavBar(
                    currentIndex: _currentTabIndex,
                    onTap: (i) => setState(() => _currentTabIndex = i),
                  ),
                ),
              ],
            ),
          ),

          // ── 2.4 Grid Menu Overlay (top-down) ────────────────────────────
          GridMenuOverlay(
            isVisible: _isMenuVisible,
            onClose: () => setState(() => _isMenuVisible = false),
          ),
        ],
      ),
    );
  }
}
