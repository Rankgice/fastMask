# FastMask

FastMask 是一个 Flutter 桌面工具，用来在不修改原始文本的前提下，快速遮挡一段文本并复制处理后的结果。

## 第一版功能

- 启动后隐藏主窗口，常驻系统托盘
- 托盘菜单提供快速模糊、显示主界面、规则快捷配置和退出
- 全局快捷键呼出快速模糊模式
- 编辑模式与模糊模式
- 在模糊模式下拖动鼠标创建遮挡区域
- 点击已有遮挡区域可取消该区域
- 原文与模糊结果预览切换
- 支持保持原长度、固定替换文本、按比例、随机增减四种长度规则
- 支持字符覆盖和纯色遮挡两种显示样式
- 复制模糊后的文本
- 复制模糊文本并隐藏窗口
- 窗口失去焦点后不会自动关闭

## 默认快捷键

| 操作 | 快捷键 |
| --- | --- |
| 打开快速模糊模式 | `Cmd/Ctrl + Shift + B` |
| 显示或隐藏窗口 | `Cmd/Ctrl + Shift + M` |
| 切换原文与模糊结果 | `Cmd/Ctrl + R` |
| 隐藏窗口 | `Esc` 或 `Cmd/Ctrl + W` |

macOS 首次使用全局快捷键时，可能需要到“系统设置 → 隐私与安全性 → 辅助功能/输入监控”中授予权限。

## 工作方式

FastMask 不会修改原始字符串。用户在模糊模式下创建的遮挡范围会保存为 UTF-16 文本区间：

```text
MaskRange(start, end, seed)
```

预览时，界面仍然按照原文的字符位置绘制遮挡，因此模糊后的字符数量不会改变页面布局。复制时再根据当前规则生成最终替换文本；固定文本、按比例和随机增减等规则可以改变复制结果的长度。

当前第一版中，编辑原文会清除已有遮挡范围，并显示提示。后续版本可以改为根据文本差异自动迁移遮挡区域。

## 开发与验证

当前项目使用 Flutter 3.47.5。

```bash
flutter pub get
flutter analyze
flutter test
```

运行 macOS 版本需要完整版 Xcode，而不是只有 Command Line Tools：

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
flutter run -d macos
```

如果 Flutter 在构建 macOS 插件时提示缺少 CocoaPods，再安装：

```bash
brew install cocoapods
```

Windows 构建需要 Visual Studio 的 Desktop development with C++ 工作负载；Linux 构建需要 GTK、CMake、Ninja 和 pkg-config 等开发依赖。macOS 上不能直接原生构建 Windows 应用。

## 第一版暂不包含

- 图片覆盖遮挡
- 多套命名规则
- 编辑原文后自动迁移遮挡范围
- 开机自动启动
- 设置页面和最近任务
- 正式的代码签名、公证和 DMG 安装包
