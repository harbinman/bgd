# 相机集成技术指南

**文档版本**: 1.0  
**更新时间**: 2026-04-13  
**适用范围**: 喵喵补光 App - 相机预览与 PIP 系统

---

## 📋 目录

1. [概述](#概述)
2. [技术架构](#技术架构)
3. [依赖配置](#依赖配置)
4. [权限管理](#权限管理)
5. [相机初始化](#相机初始化)
6. [PIP 容器集成](#pip-容器集成)
7. [资源管理](#资源管理)
8. [错误处理](#错误处理)
9. [性能优化](#性能优化)
10. [测试验证](#测试验证)
11. [常见问题](#常见问题)

---

## 概述

### 功能描述

喵喵补光 App 使用 Flutter Camera 插件实现实时相机预览功能，通过画中画（PIP）容器在主界面显示相机流，用户可以在补光的同时实时查看拍摄效果。

### 核心特性

- ✅ 实时相机预览（后置摄像头）
- ✅ 高分辨率配置（`ResolutionPreset.high`）
- ✅ 可拖拽的 PIP 容器
- ✅ 四角智能吸附
- ✅ 优雅的资源管理
- ✅ 完善的错误处理

### 技术栈

- **Flutter Camera**: `^0.11.0+2`
- **Permission Handler**: `^11.3.1`
- **平台**: Android 14+ (API Level 34+)

---

## 技术架构

### 系统架构图

```
┌─────────────────────────────────────────────────────────┐
│                    LightingPage                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Permission Check & Request                       │  │
│  │  ├─ Camera Permission                             │  │
│  │  └─ Storage Permission                            │  │
│  └───────────────────────────────────────────────────┘  │
│                          ↓                              │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Camera Initialization                            │  │
│  │  ├─ availableCameras()                            │  │
│  │  ├─ CameraController.initialize()                 │  │
│  │  └─ setState() to trigger rebuild                 │  │
│  └───────────────────────────────────────────────────┘  │
│                          ↓                              │
│  ┌───────────────────────────────────────────────────┐  │
│  │  PipContainer Widget                              │  │
│  │  ├─ Receives CameraController                     │  │
│  │  ├─ Renders CameraPreview                         │  │
│  │  └─ Handles drag & snap gestures                  │  │
│  └───────────────────────────────────────────────────┘  │
│                          ↓                              │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Resource Cleanup (dispose)                       │  │
│  │  └─ CameraController.dispose()                    │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 数据流

```
User Opens App
      ↓
Permission Request
      ↓
[Granted] → Initialize Camera → Display PIP Preview
      ↓
[Denied] → Show Settings Guide
      ↓
User Exits Page
      ↓
Dispose Camera Resources
```

---

## 依赖配置

### pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  camera: ^0.11.0+2           # 相机插件
  permission_handler: ^11.3.1  # 权限管理
```

### 安装依赖

```bash
flutter pub get
```

---

## 权限管理

### AndroidManifest.xml 配置

**文件路径**: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- 相机权限 -->
    <uses-permission android:name="android.permission.CAMERA" />
    
    <!-- 存储权限（Android 13+ 使用细分权限）-->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    
    <!-- 相机硬件特性（可选）-->
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
    
    <application>
        <!-- ... -->
    </application>
</manifest>
```

### 动态权限请求

**文件路径**: `lib/features/lighting/presentation/pages/lighting_page.dart`

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> _checkAndRequestPermissions() async {
  // 检查相机权限
  PermissionStatus cameraStatus = await Permission.camera.status;
  if (!cameraStatus.isGranted) {
    cameraStatus = await Permission.camera.request();
  }

  // 检查存储权限
  PermissionStatus storageStatus = await Permission.photos.status;
  if (!storageStatus.isGranted) {
    storageStatus = await Permission.photos.request();
  }

  // 权限通过后初始化相机
  if (cameraStatus.isGranted && storageStatus.isGranted) {
    await _initializeCamera();
  } else if (cameraStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
    // 引导用户跳转系统设置
    _showPermissionDialog();
  }
}

void _showPermissionDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('需要权限'),
      content: const Text('请在系统设置中开启相机和相册权限'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            openAppSettings(); // 跳转系统设置
            Navigator.pop(context);
          },
          child: const Text('去设置'),
        ),
      ],
    ),
  );
}
```

---

## 相机初始化

### 核心代码实现

**文件路径**: `lib/features/lighting/presentation/pages/lighting_page.dart`

```dart
import 'package:camera/camera.dart';

class _LightingPageState extends State<LightingPage> {
  // 相机相关状态
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions(); // 检查权限并初始化
  }

  /// 初始化相机
  Future<void> _initializeCamera() async {
    try {
      // 1. 获取可用相机列表
      _cameras = await availableCameras();
      
      // 2. 检查相机是否可用
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('No cameras available');
        return;
      }

      // 3. 创建 CameraController
      _cameraController = CameraController(
        _cameras![0],              // 使用第一个相机（通常是后置）
        ResolutionPreset.high,     // 高分辨率
        enableAudio: false,        // 禁用音频（补光场景不需要）
      );

      // 4. 初始化控制器
      await _cameraController!.initialize();

      // 5. 触发 UI 重建，显示预览
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      // 可选：显示错误提示给用户
    }
  }

  @override
  void dispose() {
    // 释放相机资源
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ... 其他 UI 组件
          
          // PIP 容器
          PipContainer(
            screenSize: MediaQuery.of(context).size,
            controller: _cameraController, // 传递控制器
          ),
        ],
      ),
    );
  }
}
```

### 初始化流程说明

1. **获取相机列表**: `availableCameras()` 返回设备上所有可用相机
2. **选择相机**: 通常选择 `_cameras[0]`（后置摄像头）
3. **配置参数**:
   - `ResolutionPreset.high`: 高分辨率（1080p+）
   - `enableAudio: false`: 禁用音频录制
4. **异步初始化**: `await _cameraController!.initialize()`
5. **触发重建**: `setState()` 通知 Flutter 重新构建 UI
6. **错误处理**: `try-catch` 捕获初始化失败

---

## PIP 容器集成

### PipContainer Widget

**文件路径**: `lib/features/lighting/presentation/widgets/pip_container.dart`

```dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class PipContainer extends StatefulWidget {
  final Size screenSize;
  final CameraController? controller; // 接收相机控制器

  const PipContainer({
    super.key,
    required this.screenSize,
    this.controller,
  });

  @override
  State<PipContainer> createState() => _PipContainerState();
}

class _PipContainerState extends State<PipContainer> {
  Offset _position = const Offset(20, 100);

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      left: _position.dx,
      top: _position.dy,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        onPanEnd: (_) => _snapToCorner(),
        child: Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.pink, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildPreview(),
        ),
      ),
    );
  }

  /// 构建预览内容
  Widget _buildPreview() {
    // 检查控制器是否已初始化
    if (widget.controller == null || !widget.controller!.value.isInitialized) {
      return _buildPlaceholder(); // 显示占位符
    }

    // 显示相机预览
    return CameraPreview(widget.controller!);
  }

  /// 占位符 UI
  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: Colors.white54, size: 32),
            SizedBox(height: 8),
            Text(
              'MIAO CAM',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// 四角吸附逻辑
  void _snapToCorner() {
    final screenWidth = widget.screenSize.width;
    final screenHeight = widget.screenSize.height;
    final containerWidth = 120.0;
    final containerHeight = 160.0;

    // 计算最近的角落
    final isLeft = _position.dx < screenWidth / 2;
    final isTop = _position.dy < screenHeight / 2;

    setState(() {
      _position = Offset(
        isLeft ? 20 : screenWidth - containerWidth - 20,
        isTop ? 100 : screenHeight - containerHeight - 100,
      );
    });
  }
}
```

### 关键实现细节

1. **条件渲染**:
   ```dart
   widget.controller?.value.isInitialized ?? false
   ```
   检查控制器是否已初始化，未初始化时显示占位符

2. **CameraPreview Widget**:
   ```dart
   CameraPreview(widget.controller!)
   ```
   Flutter Camera 插件提供的预览组件，自动处理相机流渲染

3. **拖拽交互**:
   ```dart
   onPanUpdate: (details) => _position += details.delta
   ```
   实时更新位置，跟随手指移动

4. **吸附动画**:
   ```dart
   AnimatedPositioned(duration: 420ms, curve: easeOutBack)
   ```
   松手后平滑吸附到最近的角落

---

## 资源管理

### 生命周期管理

```dart
class _LightingPageState extends State<LightingPage> {
  @override
  void initState() {
    super.initState();
    // 初始化相机
    _initializeCamera();
  }

  @override
  void dispose() {
    // 释放相机资源（必须）
    _cameraController?.dispose();
    
    // 释放其他资源
    _pulseController.dispose();
    
    super.dispose();
  }
}
```

### 资源释放时机

| 场景 | 触发时机 | 操作 |
|------|---------|------|
| 页面退出 | `dispose()` | 调用 `_cameraController?.dispose()` |
| 应用后台 | `AppLifecycleState.paused` | 可选：暂停相机流 |
| 应用恢复 | `AppLifecycleState.resumed` | 可选：恢复相机流 |

### 内存优化

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (_cameraController == null || !_cameraController!.value.isInitialized) {
    return;
  }

  if (state == AppLifecycleState.inactive) {
    // 应用进入后台，释放相机
    _cameraController?.dispose();
  } else if (state == AppLifecycleState.resumed) {
    // 应用恢复，重新初始化
    _initializeCamera();
  }
}
```

---

## 错误处理

### 常见错误场景

#### 1. 相机初始化失败

```dart
Future<void> _initializeCamera() async {
  try {
    _cameras = await availableCameras();
    // ...
  } on CameraException catch (e) {
    switch (e.code) {
      case 'CameraAccessDenied':
        _showError('相机权限被拒绝');
        break;
      case 'CameraAccessDeniedWithoutPrompt':
        _showError('请在系统设置中开启相机权限');
        break;
      case 'CameraAccessRestricted':
        _showError('相机访问受限');
        break;
      default:
        _showError('相机初始化失败: ${e.description}');
    }
  } catch (e) {
    _showError('未知错误: $e');
  }
}
```

#### 2. 相机列表为空

```dart
if (_cameras == null || _cameras!.isEmpty) {
  debugPrint('No cameras available on this device');
  _showError('设备没有可用的相机');
  return;
}
```

#### 3. 控制器未初始化

```dart
Widget _buildPreview() {
  if (widget.controller == null) {
    return _buildPlaceholder();
  }

  if (!widget.controller!.value.isInitialized) {
    return const Center(child: CircularProgressIndicator());
  }

  return CameraPreview(widget.controller!);
}
```

### 错误提示 UI

```dart
void _showError(String message) {
  if (!mounted) return;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    ),
  );
}
```

---

## 性能优化

### 分辨率配置

```dart
// 高端设备：高分辨率
ResolutionPreset.high      // 1080p+

// 中端设备：中等分辨率
ResolutionPreset.medium    // 720p

// 低端设备：低分辨率
ResolutionPreset.low       // 480p
```

### 动态分辨率选择

```dart
Future<void> _initializeCamera() async {
  // 检测设备性能
  final isLowEndDevice = await _checkDevicePerformance();
  
  final preset = isLowEndDevice 
      ? ResolutionPreset.medium 
      : ResolutionPreset.high;

  _cameraController = CameraController(
    _cameras![0],
    preset,
    enableAudio: false,
  );
  
  await _cameraController!.initialize();
}
```

### 帧率监控（开发模式）

```dart
int _frameCount = 0;
int _lastFrameTime = DateTime.now().millisecondsSinceEpoch;

void _monitorFPS() {
  _frameCount++;
  if (_frameCount % 30 == 0) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final fps = 30000 / (now - _lastFrameTime);
    debugPrint('Camera FPS: ${fps.toStringAsFixed(1)}');
    _lastFrameTime = now;
  }
}
```

### 内存占用优化

- ✅ 禁用音频：`enableAudio: false`
- ✅ 合理分辨率：避免使用 `ResolutionPreset.max`
- ✅ 及时释放：页面退出时调用 `dispose()`
- ✅ 后台暂停：应用进入后台时释放相机

---

## 测试验证

### 单元测试

**文件路径**: `test/features/lighting/presentation/pages/lighting_page_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';

void main() {
  group('Camera Initialization', () {
    test('should initialize camera controller', () async {
      final cameras = await availableCameras();
      expect(cameras, isNotEmpty);

      final controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      expect(controller.value.isInitialized, isTrue);

      await controller.dispose();
    });
  });
}
```

### Widget 测试

```dart
testWidgets('PipContainer should show placeholder when controller is null', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PipContainer(
          screenSize: const Size(400, 800),
          controller: null, // 未初始化
        ),
      ),
    ),
  );

  expect(find.text('MIAO CAM'), findsOneWidget);
  expect(find.byIcon(Icons.camera_alt), findsOneWidget);
});
```

### 真机测试清单

- [ ] 相机权限请求流程
- [ ] 相机预览正常显示
- [ ] PIP 容器拖拽流畅
- [ ] 四角吸附动画自然
- [ ] 页面退出资源释放
- [ ] 应用后台/恢复相机状态
- [ ] 低端设备性能表现

---

## 常见问题

### Q1: 相机预览显示黑屏

**原因**:
- 控制器未初始化完成
- 权限未授予
- 相机被其他应用占用

**解决方案**:
```dart
// 检查初始化状态
if (_cameraController?.value.isInitialized ?? false) {
  return CameraPreview(_cameraController!);
} else {
  return const CircularProgressIndicator();
}
```

### Q2: 相机初始化失败

**原因**:
- 设备没有相机硬件
- 权限被拒绝
- 相机驱动异常

**解决方案**:
```dart
try {
  _cameras = await availableCameras();
  if (_cameras!.isEmpty) {
    _showError('设备没有可用的相机');
    return;
  }
} on CameraException catch (e) {
  _showError('相机初始化失败: ${e.description}');
}
```

### Q3: 内存泄漏

**原因**:
- 未调用 `dispose()`
- 多次初始化未释放旧实例

**解决方案**:
```dart
@override
void dispose() {
  _cameraController?.dispose(); // 必须调用
  super.dispose();
}
```

### Q4: 相机预览变形

**原因**:
- 容器宽高比与相机分辨率不匹配

**解决方案**:
```dart
// 使用 AspectRatio 保持比例
AspectRatio(
  aspectRatio: _cameraController!.value.aspectRatio,
  child: CameraPreview(_cameraController!),
)
```

### Q5: Android 13+ 权限问题

**原因**:
- Android 13 引入细分存储权限

**解决方案**:
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

---

## 参考资料

### 官方文档
- [Flutter Camera Plugin](https://pub.dev/packages/camera)
- [Permission Handler Plugin](https://pub.dev/packages/permission_handler)
- [Android Camera2 API](https://developer.android.com/reference/android/hardware/camera2/package-summary)

### 相关文件
- `lib/features/lighting/presentation/pages/lighting_page.dart`
- `lib/features/lighting/presentation/widgets/pip_container.dart`
- `android/app/src/main/AndroidManifest.xml`
- `docs/milestone_3_analysis.md`

### 版本历史
- **v1.0** (2026-04-13): 初始版本，完成相机集成与 PIP 系统
