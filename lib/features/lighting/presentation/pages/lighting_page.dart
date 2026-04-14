import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import 'package:miaomiao_fill_light/core/theme/app_theme.dart';
import 'package:miaomiao_fill_light/features/lighting/presentation/widgets/heart_painter.dart';
import 'package:miaomiao_fill_light/features/lighting/presentation/widgets/pip_container.dart';
import 'package:miaomiao_fill_light/features/lighting/presentation/widgets/grid_menu_overlay.dart';
import 'package:miaomiao_fill_light/features/lighting/presentation/widgets/shortcut_toolbar.dart';
import 'package:miaomiao_fill_light/features/lighting/presentation/widgets/bottom_nav_bar.dart';
import 'package:miaomiao_fill_light/features/lighting/presentation/widgets/filter_tray.dart';
import 'package:miaomiao_fill_light/features/lighting/domain/models/filter_type.dart';
import 'package:miaomiao_fill_light/features/lighting/presentation/pages/photo_preview_page.dart';

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

  // Milestone 3.1: Camera controller
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;

  // Milestone 4: Photo capture & filters
  FilterType _currentFilter = FilterType.none;
  bool _showFlashOverlay = false;
  int? _countdownSeconds;
  bool _isBurstMode = false;
  int _burstCount = 0;
  List<String> _recentPhotos = [];
  bool _showFilterTray = false;
  int? _timerDuration;
  bool _isCapturing = false;

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

    // Milestone 3.2: Enable brightness lock and wakelock
    _enableBrightnessLock();
    WakelockPlus.enable();

    // Delay permission request so first frame renders first
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _checkAndRequestPermissions();
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    ScreenBrightness().resetScreenBrightness();
    WakelockPlus.disable();
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
      // Initialize camera after permissions granted
      await _initializeCamera();

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

  Future<void> _enableBrightnessLock() async {
    try {
      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (e) {
      debugPrint('Failed to set brightness: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('No cameras available');
        return;
      }

      // 查找前置摄像头（自拍场景优先使用前置）
      CameraDescription? frontCamera;
      try {
        frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } catch (e) {
        // 如果没有前置摄像头，使用第一个可用相机
        debugPrint('No front camera found, using first available camera');
        frontCamera = _cameras![0];
      }

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
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
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.vibrantPink),
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  // Milestone 4.1: 拍照功能
  Future<void> _takePicture() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    try {
      setState(() => _isCapturing = true);

      // 1. 拍摄照片
      final XFile image = await _cameraController!.takePicture();

      // 2. 触觉反馈
      HapticFeedback.mediumImpact();

      // 3. 闪光动画
      setState(() => _showFlashOverlay = true);
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() => _showFlashOverlay = false);

      // 4. 保存照片
      await _savePhoto(image);
    } catch (e) {
      debugPrint('拍照失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('拍照失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  // Milestone 4.3: 保存照片到相册
  Future<void> _savePhoto(XFile image) async {
    try {
      // 读取照片数据
      final bytes = await image.readAsBytes();

      // 应用滤镜（如果有）
      Uint8List finalBytes;
      if (_currentFilter != FilterType.none) {
        final img.Image? originalImage = img.decodeImage(bytes);
        if (originalImage != null) {
          final filteredImage = _applyImageFilter(originalImage, _currentFilter);
          finalBytes = Uint8List.fromList(img.encodeJpg(filteredImage, quality: 95));
        } else {
          finalBytes = bytes;
        }
      } else {
        finalBytes = bytes;
      }

      // 保存到相册
      final result = await ImageGallerySaver.saveImage(
        finalBytes,
        quality: 95,
        name: 'BGD_${DateTime.now().millisecondsSinceEpoch}',
      );

      // 保存到临时目录用于缩略图预览
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/BGD_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(finalBytes);

      // 更新最近照片列表
      setState(() {
        _recentPhotos.insert(0, tempPath);
        if (_recentPhotos.length > 10) {
          _recentPhotos.removeLast();
        }
      });

      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 照片已保存'),
            backgroundColor: AppTheme.vibrantPink,
            duration: Duration(seconds: 1),
          ),
        );
      }

      debugPrint('照片保存成功: $result');
    } catch (e) {
      debugPrint('保存照片失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 应用滤镜到图像
  img.Image _applyImageFilter(img.Image image, FilterType filter) {
    switch (filter) {
      case FilterType.none:
        return image;
      case FilterType.grayscale:
        return img.grayscale(image);
      case FilterType.sepia:
        return img.sepia(image);
      case FilterType.cool:
        // 冷色调：降低红色，增加蓝色
        final adjusted = img.adjustColor(image, saturation: 0.9);
        return _adjustColorChannels(adjusted, redFactor: 0.9, blueFactor: 1.1);
      case FilterType.warm:
        // 暖色调：增加红色，降低蓝色
        final adjusted = img.adjustColor(image, saturation: 1.1);
        return _adjustColorChannels(adjusted, redFactor: 1.2, blueFactor: 0.8);
      case FilterType.vintage:
        return img.adjustColor(
          image,
          saturation: 0.8,
          brightness: 1.1,
          contrast: 1.2,
        );
      case FilterType.vivid:
        return img.adjustColor(image, saturation: 1.5, contrast: 1.2);
    }
  }

  // 手动调整颜色通道
  img.Image _adjustColorChannels(img.Image image, {double redFactor = 1.0, double greenFactor = 1.0, double blueFactor = 1.0}) {
    final result = img.Image.from(image);
    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final pixel = result.getPixel(x, y);
        final r = (pixel.r * redFactor).clamp(0, 255).toInt();
        final g = (pixel.g * greenFactor).clamp(0, 255).toInt();
        final b = (pixel.b * blueFactor).clamp(0, 255).toInt();
        result.setPixelRgba(x, y, r, g, b, pixel.a.toInt());
      }
    }
    return result;
  }

  // Milestone 4.1: 倒计时拍摄
  Future<void> _startCountdown(int seconds) async {
    setState(() => _countdownSeconds = seconds);

    for (int i = seconds; i > 0; i--) {
      if (!mounted) return;
      setState(() => _countdownSeconds = i);
      await Future.delayed(const Duration(seconds: 1));
      HapticFeedback.lightImpact();
    }

    setState(() => _countdownSeconds = null);
    await _takePicture();
  }

  // Milestone 4.1: 连拍模式
  void _startBurstMode() {
    setState(() {
      _isBurstMode = true;
      _burstCount = 0;
    });
  }

  void _stopBurstMode() {
    setState(() => _isBurstMode = false);
  }

  Future<void> _burstCapture() async {
    while (_isBurstMode && mounted) {
      await _takePicture();
      setState(() => _burstCount++);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  // Milestone 4.3: 分享照片
  Future<void> _sharePhoto(String photoPath) async {
    try {
      await Share.shareXFiles([XFile(photoPath)], text: '来自喵喵补光灯的照片');
    } catch (e) {
      debugPrint('分享失败: $e');
    }
  }

  // 打开照片预览
  void _openPhotoPreview(String photoPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoPreviewPage(
          photoPath: photoPath,
          onShare: () => _sharePhoto(photoPath),
          onDelete: () {
            setState(() => _recentPhotos.remove(photoPath));
            Navigator.pop(context);
          },
        ),
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
                        color: Colors.white
                            .withOpacity(_isMenuVisible ? 0.12 : 0.06),
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

          // ── 2.2 PIP Container with Filter ────────────────────────────────
          if (_cameraController != null &&
              _cameraController!.value.isInitialized)
            PipContainer(
              screenSize: screenSize,
              controller: _cameraController,
              filterType: _currentFilter,
            ),

          // ── Flash Overlay ────────────────────────────────────────────────
          if (_showFlashOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.white,
              ),
            ),

          // ── Countdown Overlay ────────────────────────────────────────────
          if (_countdownSeconds != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.5, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Text(
                          '$_countdownSeconds',
                          style: const TextStyle(
                            color: AppTheme.vibrantPink,
                            fontSize: 120,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // ── Burst Counter Overlay ────────────────────────────────────────
          if (_isBurstMode)
            Positioned(
              top: safePadding.top + 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.vibrantPink.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '连拍中... $_burstCount 张',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // ── Bottom action zone ───────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filter Tray
                if (_showFilterTray)
                  FilterTray(
                    currentFilter: _currentFilter,
                    onFilterSelected: (filter) {
                      setState(() => _currentFilter = filter);
                    },
                    onClose: () => setState(() => _showFilterTray = false),
                  ),
                // Shortcut toolbar
                ShortcutToolbar(
                  onShutter: () async {
                    if (_timerDuration != null) {
                      await _startCountdown(_timerDuration!);
                    } else {
                      await _takePicture();
                    }
                  },
                  onShutterLongPressStart: () {
                    _startBurstMode();
                    _burstCapture();
                  },
                  onShutterLongPressEnd: () {
                    _stopBurstMode();
                  },
                  onFilterTap: () {
                    setState(() => _showFilterTray = !_showFilterTray);
                  },
                  onTimerTap: () {
                    _showTimerDialog();
                  },
                  recentPhotoPath:
                      _recentPhotos.isNotEmpty ? _recentPhotos.first : null,
                  onThumbnailTap: () {
                    if (_recentPhotos.isNotEmpty) {
                      _openPhotoPreview(_recentPhotos.first);
                    }
                  },
                ),
                const SizedBox(height: 14),
                // Bottom Tab Bar
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

  // 显示定时器设置对话框
  void _showTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.charcoal,
        title: const Text('定时拍摄', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TimerOption(
              label: '关闭',
              onTap: () {
                setState(() => _timerDuration = null);
                Navigator.pop(context);
              },
              isSelected: _timerDuration == null,
            ),
            _TimerOption(
              label: '3 秒',
              onTap: () {
                setState(() => _timerDuration = 3);
                Navigator.pop(context);
              },
              isSelected: _timerDuration == 3,
            ),
            _TimerOption(
              label: '5 秒',
              onTap: () {
                setState(() => _timerDuration = 5);
                Navigator.pop(context);
              },
              isSelected: _timerDuration == 5,
            ),
            _TimerOption(
              label: '10 秒',
              onTap: () {
                setState(() => _timerDuration = 10);
                Navigator.pop(context);
              },
              isSelected: _timerDuration == 10,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const _TimerOption({
    required this.label,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.vibrantPink.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.vibrantPink
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.vibrantPink : Colors.white70,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
