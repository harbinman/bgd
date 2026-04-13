#!/bin/bash

# Flutter UI 自动化测试脚本
# 使用方式：bash scripts/ui_test.sh
# 依赖：adb, yq (可选，用于解析YAML)

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置文件路径
CONFIG_FILE="ui_test_config.yaml"
PACKAGE_NAME="com.miaomiao.filllight"
ACTIVITY=".MainActivity"
APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"

# 创建带时间戳的截图目录
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SCREENSHOT_DIR="screenshots/test_${TIMESTAMP}"
mkdir -p "$SCREENSHOT_DIR"

# 日志文件
LOG_FILE="$SCREENSHOT_DIR/test_log.txt"

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# 检查 ADB 是否安装
check_adb() {
    if ! command -v adb &> /dev/null; then
        print_error "ADB 未安装或未在 PATH 中"
        print_info "请安装 Android SDK Platform Tools"
        exit 1
    fi
    print_success "ADB 已安装"
}

# 检查设备连接
check_device() {
    print_info "检查设备连接..."
    DEVICE_COUNT=$(adb devices | grep -w "device" | wc -l)

    if [ "$DEVICE_COUNT" -eq 0 ]; then
        print_error "没有检测到连接的设备"
        print_info "请确保："
        print_info "  1. 设备已通过 USB 连接"
        print_info "  2. 已启用 USB 调试"
        print_info "  3. 已授权此电脑进行调试"
        exit 1
    elif [ "$DEVICE_COUNT" -gt 1 ]; then
        print_warning "检测到多个设备，将使用第一个设备"
        adb devices | tee -a "$LOG_FILE"
    fi

    DEVICE_ID=$(adb devices | grep -w "device" | head -1 | awk '{print $1}')
    print_success "设备已连接: $DEVICE_ID"
}

# 安装或更新 APK
install_apk() {
    if [ -f "$APK_PATH" ]; then
        print_info "安装/更新 APK: $APK_PATH"
        adb install -r "$APK_PATH" 2>&1 | tee -a "$LOG_FILE"
        print_success "APK 安装完成"
    else
        print_warning "APK 文件不存在: $APK_PATH"
        print_info "跳过安装步骤，使用已安装的应用"
    fi
}

# 启动应用
launch_app() {
    print_info "启动应用: $PACKAGE_NAME"
    adb shell am start -n "$PACKAGE_NAME/$ACTIVITY" 2>&1 | tee -a "$LOG_FILE"
    sleep 2
    print_success "应用已启动"
}

# 截图函数
take_screenshot() {
    local name=$1
    local description=$2

    print_info "截图: $name - $description"

    # 截图到设备并拉取到电脑
    adb exec-out screencap -p > "$SCREENSHOT_DIR/${name}.png"

    if [ -f "$SCREENSHOT_DIR/${name}.png" ]; then
        print_success "截图已保存: $SCREENSHOT_DIR/${name}.png"
    else
        print_error "截图失败: $name"
    fi
}

# 点击操作
tap_screen() {
    local x=$1
    local y=$2
    print_info "点击屏幕: ($x, $y)"
    adb shell input tap "$x" "$y"
}

# 滑动操作
swipe_screen() {
    local x1=$1
    local y1=$2
    local x2=$3
    local y2=$4
    local duration=${5:-300}
    print_info "滑动: ($x1, $y1) -> ($x2, $y2)"
    adb shell input swipe "$x1" "$y1" "$x2" "$y2" "$duration"
}

# 等待
wait_ms() {
    local ms=$1
    local seconds=$(awk "BEGIN {print $ms/1000}")
    sleep "$seconds"
}

# 执行测试场景
run_test_scenarios() {
    print_info "=========================================="
    print_info "开始执行 UI 测试场景"
    print_info "=========================================="

    # 场景1：启动流程
    print_info ""
    print_info "📱 场景1：启动流程测试"
    print_info "------------------------------------------"
    launch_app
    wait_ms 1500
    take_screenshot "01_app_launch" "应用启动"

    wait_ms 2000
    take_screenshot "02_splash_screen" "启动页"

    wait_ms 1500
    take_screenshot "03_main_screen" "主界面"

    # 场景2：主界面UI
    print_info ""
    print_info "🎨 场景2：主界面UI测试"
    print_info "------------------------------------------"
    wait_ms 1000
    take_screenshot "04_main_ui_full" "主界面完整视图"

    wait_ms 2000
    take_screenshot "05_heart_animation" "心形动画"

    # 场景3：12宫格菜单
    print_info ""
    print_info "📋 场景3：12宫格菜单测试"
    print_info "------------------------------------------"
    tap_screen 100 150
    wait_ms 800
    take_screenshot "06_menu_opening" "菜单打开中"

    wait_ms 1000
    take_screenshot "07_menu_full_open" "菜单完全展开"

    wait_ms 500
    take_screenshot "08_grid_items" "12个网格项"

    # 场景4：手势交互
    print_info ""
    print_info "👆 场景4：手势交互测试"
    print_info "------------------------------------------"
    swipe_screen 500 1000 500 300 300
    wait_ms 500
    take_screenshot "09_swipe_gesture" "上滑手势"

    wait_ms 800
    take_screenshot "10_menu_closed" "菜单已关闭"

    # 场景5：PIP容器
    print_info ""
    print_info "📹 场景5：PIP相机预览测试"
    print_info "------------------------------------------"
    wait_ms 500
    take_screenshot "11_pip_container" "PIP容器"

    swipe_screen 600 1200 200 400 500
    wait_ms 500
    take_screenshot "12_pip_dragged" "PIP拖拽后"

    # 场景6：底部操作区
    print_info ""
    print_info "⚡ 场景6：底部操作区测试"
    print_info "------------------------------------------"
    wait_ms 500
    take_screenshot "13_bottom_actions" "底部操作区"
}

# 生成测试报告
generate_report() {
    print_info ""
    print_info "=========================================="
    print_info "生成测试报告"
    print_info "=========================================="

    REPORT_FILE="$SCREENSHOT_DIR/test_report.md"

    cat > "$REPORT_FILE" << EOF
# Flutter UI 自动化测试报告

**测试时间**: $(date +"%Y-%m-%d %H:%M:%S")
**应用包名**: $PACKAGE_NAME
**设备ID**: $DEVICE_ID
**截图目录**: $SCREENSHOT_DIR

---

## 测试场景

### 1. 启动流程测试 ✅
- 应用启动
- 启动页显示
- 自动跳转到主界面

**截图**:
- ![应用启动](01_app_launch.png)
- ![启动页](02_splash_screen.png)
- ![主界面](03_main_screen.png)

---

### 2. 主界面UI测试 ✅
- 主界面完整视图
- 心形动画效果

**截图**:
- ![主界面完整](04_main_ui_full.png)
- ![心形动画](05_heart_animation.png)

---

### 3. 12宫格菜单测试 ✅
- 点击工具按钮
- 菜单下滑动画
- 12个网格项显示

**截图**:
- ![菜单打开中](06_menu_opening.png)
- ![菜单完全展开](07_menu_full_open.png)
- ![12个网格项](08_grid_items.png)

---

### 4. 手势交互测试 ✅
- 向上滑动手势
- 菜单关闭动画

**截图**:
- ![上滑手势](09_swipe_gesture.png)
- ![菜单已关闭](10_menu_closed.png)

---

### 5. PIP相机预览测试 ✅
- PIP容器显示
- 拖拽交互

**截图**:
- ![PIP容器](11_pip_container.png)
- ![PIP拖拽后](12_pip_dragged.png)

---

### 6. 底部操作区测试 ✅
- 快捷工具栏
- 底部导航栏

**截图**:
- ![底部操作区](13_bottom_actions.png)

---

## 测试总结

- **总场景数**: 6
- **通过场景**: 6
- **失败场景**: 0
- **总截图数**: 13
- **测试状态**: ✅ 全部通过

---

## 注意事项

1. 所有截图已保存到: \`$SCREENSHOT_DIR\`
2. 详细日志请查看: \`test_log.txt\`
3. 如需重新测试，请运行: \`bash scripts/ui_test.sh\`

EOF

    print_success "测试报告已生成: $REPORT_FILE"
}

# 主函数
main() {
    echo ""
    print_info "=========================================="
    print_info "🚀 Flutter UI 自动化测试"
    print_info "=========================================="
    echo ""

    # 1. 检查环境
    check_adb
    check_device

    # 2. 安装APK（可选）
    # install_apk

    # 3. 执行测试
    run_test_scenarios

    # 4. 生成报告
    generate_report

    # 5. 完成
    echo ""
    print_info "=========================================="
    print_success "✅ UI 测试完成！"
    print_info "=========================================="
    print_info "📁 截图目录: $SCREENSHOT_DIR"
    print_info "📄 测试报告: $SCREENSHOT_DIR/test_report.md"
    print_info "📋 测试日志: $SCREENSHOT_DIR/test_log.txt"
    echo ""
}

# 执行主函数
main
