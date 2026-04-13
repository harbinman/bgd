# 《喵喵补光灯》项目架构与技术框架文档 (Detailed v1.1)

## 1. 技术栈选型 (Tech Stack)
- **开发优先级**: 优先 Android 测试，渐进式补全 iOS，UI 先行，功能后补。
- **底层框架**: Flutter 3.24+ (Dart 3.x)
- **后端架构 (Pending)**: 推荐使用 **Firebase** 或 **Supabase** (Serverless) 以实现快速的 Auth、Database 和云存储，或定制化 Node.js/Python REST API。
- **状态管理**: Riverpod 2.x (推荐理由：高性能、易测试、解耦彻底)
- **数据持久化**: Shared Preferences (用于配置) + SQLite (用于样片库管理)
- **硬件桥接**: Flutter MethodChannel (调用原生 Swift/Kotlin API)

## 2. 系统架构设计 (Clean Architecture)
采用 **按功能分区 (Feature-First)** 的 Clean Architecture 模式，确保代码的可移植性和可维护性。

### 2.1 目录结构标准
```text
lib/
├── core/                     # 公共工具、常量、通用 Widget
│   ├── catchlights/          # 眼神光 Painter 定义
│   └── theme/                # 自定义 Dark-Focus 风格
├── features/                 # 核心功能模块
│   ├── lighting/             # 补光引擎模块
│   │   ├── data/             # 色卡配置、存储实现
│   │   ├── domain/           # 补光逻辑实体、抽象接口
│   │   └── presentation/     # 颜色选择器、背景层 UI
│   ├── camera/               # 相机模块
│   │   ├── data/             # 画中画逻辑、流数据处理
│   │   └── presentation/     # PIP 悬浮窗、快门交互
│   └── settings/             # 权限、偏好设置
└── main.dart                 # 入口，全局 Provider 初始化
```

- **Lighting Engine (补光引擎)**:
    - 核心是一个全屏 `Stack` 置底。
    - 使用 `CustomPainter` 实现 **HeartPainter**（带内外发光效果的心形眼神光）。
    - **实现细节**：利用多层 `MaskFilter.blur` 模拟物理柔光感，并配合 `AnimationController` 实现 0.9x-1.1x 的呼吸律动 (Breathing Effect)。
- **Camera Module (相机模块)**:
    - **PIP Container (画中画容器)**：实现圆角（24dp）且带粉色微光边框的悬浮预览。
    - **交互逻辑**：集成 `GestureDetector` 的位移追踪，并支持在 `onPanEnd` 时自动吸附 (Snap) 至屏幕四角。
- **Liquid Menu (分栏菜单)** [FINALIZED]:
    - **高保真模糊**：使用 `ImageFilter.blur(sigma: 30)` 实现毛玻璃全屏背景。
    - **动画系统**：采用顶部下滑（Top-down Slide）逻辑，通过 `Align.topCenter` 与基于 `AnimationController` 的 Y 轴偏移驱动。
    - **渲染兼容性修复**：面板容器应用了统一颜色的 `Border.all`，成功绕过了 Flutter `BoxDecoration` 对”非统一边框颜色与 borderRadius 并存”时的运行时崩溃限制。
    - **手势交互增强 [NEW]**：
        - 实现向上滑动手势关闭功能，支持拖拽偏移实时跟随
        - 拖拽阈值：向上拖拽 > 120px 或快速滑动速度 < -600px/s 触发关闭
        - 拖拽手柄动态反馈：拖拽时宽度和透明度实时变化，提供视觉反馈
        - 未达到关闭条件时自动回弹到原位
    - **布局优化 [NEW]**：
        - 容器高度从 `screenHeight * 0.72` 增加到 `0.78`
        - 顶部 padding 从 60px 优化到 50px
        - 网格行间距从 24px 优化到 20px
        - 添加 `childAspectRatio: 0.85` 确保 12 个网格项完整显示
        - 保持无滚动设计（`NeverScrollableScrollPhysics()`）
- **Bottom Action Zone (底部操作区)** [FINALIZED]:
    - **ShortcutToolbar Widget**：独立的快捷操作行组件，包含 Beauty / 大圆快门 / Filter / Timer。快门按钮采用 64dp `RadialGradient` 粉色圆形背景，强化点击感。
    - **BottomNavBar Widget**：毛玻璃胶囊导航栏，选中项带顶部粉色偏移指示条。
- **PIP 增强与渲染稳定性** [NEW]:
    - **虚线描边**：通过 `_DashedBorderPainter` (CustomPainter) 实现精确的 12dp 圆角粉色虚线取景边框。
    - **渲染稳定策略**：全局采用 `(pulse * factor).clamp(0.0, 1.0)` 方案，解决 `withOpacity()` 在动画越界时的 Assertion Error。

## 3. 性能优化与安全
- **渲染性能**: 为补光背景层设置独立的 `RepaintBoundary`，避免重绘补光层时触发相机预览框的无效布局计算。
- **滤镜引擎**: **UI-First 架构**。首个版本优先实现滤镜选择与交互界面，算法底层模块预留接口，待定具体的 GLSL 或 SDK 实现。
- **数据持久化**: 纯本地 SQLite 存储，关闭所有云端同步 (Cloud-Sync Disabled)。

## 4. 依赖项清单 (Pubspec Map)
- `camera: latest`: 相机基础流。
- `riverpod: latest`: 响应式状态流。
- `screen_brightness: ^1.x`: 系统亮度控制。
- `wakelock_plus: ^1.x`: 常亮支持。
- `flutter_localizations`: 国际化多语言支持。
- `in_app_purchase: latest`: 官方支付插件，处理跨平台交易。
- `firebase_auth / supabase_flutter`: 用户认证与后端服务。
- `cloud_firestore / supabase_db`: 后端管理数据存储。
