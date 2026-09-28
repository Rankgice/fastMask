import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../controllers/app_controller.dart';
import '../models/mask_rule.dart';
import '../models/shortcut_config.dart';

class DesktopService with TrayListener, WindowListener {
  DesktopService({required this.controller});

  static const _nativeTrayChannel = MethodChannel('fastmask/native_tray');

  final AppController controller;
  final List<HotKey> _registeredHotKeys = [];

  bool get _usesNativeTray => Platform.isMacOS;

  Future<void> initialize() async {
    if (_usesNativeTray) {
      _nativeTrayChannel.setMethodCallHandler(_handleNativeTrayCall);
    } else {
      trayManager.addListener(this);
    }
    windowManager.addListener(this);

    await windowManager.setPreventClose(true);
    await windowManager.setAlwaysOnTop(true);
    await _configureTray();
    await _registerHotKeys();
  }

  Future<void> _handleNativeTrayCall(MethodCall call) async {
    if (call.method != 'trayAction') {
      return;
    }

    final action = call.arguments as String?;
    if (action != null) {
      _handleTrayAction(action);
    }
  }

  Future<void> _configureTray() async {
    try {
      if (_usesNativeTray) {
        debugPrint('Configuring native macOS tray');
        await _nativeTrayChannel.invokeMethod<void>('configureTray', {
          'lengthMode': controller.rule.lengthMode.name,
          'token': controller.rule.token,
        });
        await refreshTrayMenu();
        return;
      }

      final iconPath = Platform.isWindows
          ? 'assets/tray_icon.ico'
          : 'assets/tray_icon.png';
      debugPrint('Configuring tray icon: $iconPath');
      await trayManager.setIcon(iconPath, iconSize: 18);
      await trayManager.setToolTip('FastMask');
      await refreshTrayMenu();
      final bounds = await trayManager.getBounds();
      debugPrint('Tray icon bounds: $bounds');
    } catch (error, stackTrace) {
      debugPrint('Unable to configure tray: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> refreshTrayMenu() async {
    if (_usesNativeTray) {
      await _nativeTrayChannel.invokeMethod<void>('updateTrayMenu', {
        'lengthMode': controller.rule.lengthMode.name,
        'token': controller.rule.token,
      });
      return;
    }

    String mark(bool selected) => selected ? '✓ ' : '   ';

    final menu = Menu(
      items: [
        MenuItem(key: 'quick_mask', label: '快速模糊'),
        MenuItem(key: 'show_window', label: '显示主界面'),
        MenuItem.separator(),
        MenuItem(
          key: 'length_preserve',
          label:
              '${mark(controller.rule.lengthMode == MaskLengthMode.preserve)}保持原长度',
        ),
        MenuItem(
          key: 'length_fixed',
          label:
              '${mark(controller.rule.lengthMode == MaskLengthMode.fixed)}固定长度',
        ),
        MenuItem(
          key: 'length_proportional',
          label:
              '${mark(controller.rule.lengthMode == MaskLengthMode.proportional)}按比例',
        ),
        MenuItem(
          key: 'length_random',
          label:
              '${mark(controller.rule.lengthMode == MaskLengthMode.randomRange)}随机范围',
        ),
        MenuItem(
          key: 'token_menu',
          label: '遮挡字符',
          submenu: Menu(
            items: [
              MenuItem(
                key: 'token_asterisk',
                label: '${mark(controller.rule.token == '*')}*',
              ),
              MenuItem(
                key: 'token_square',
                label: '${mark(controller.rule.token == '█')}█',
              ),
              MenuItem(
                key: 'token_hash',
                label: '${mark(controller.rule.token == '#')}#',
              ),
              MenuItem(
                key: 'token_x',
                label: '${mark(controller.rule.token == 'x')}x',
              ),
            ],
          ),
        ),
        MenuItem.separator(),
        MenuItem(key: 'hide_window', label: '隐藏窗口'),
        MenuItem(key: 'exit_app', label: '退出 FastMask'),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  Future<void> _registerHotKeys() async {
    await hotKeyManager.unregisterAll();
    _registeredHotKeys.clear();

    final callbacks = <ShortcutAction, VoidCallback>{
      ShortcutAction.quickMask: showQuickMask,
      ShortcutAction.toggleWindow: toggleWindow,
      ShortcutAction.togglePreview: controller.togglePreview,
    };

    for (final action in ShortcutAction.values) {
      final config =
          controller.shortcuts[action] ?? ShortcutConfig.defaults[action]!;
      await _register(config.toHotKey(), callbacks[action]!);
    }
  }

  Future<void> refreshHotKeys() => _registerHotKeys();

  Future<void> _register(HotKey hotKey, VoidCallback callback) async {
    try {
      await hotKeyManager.register(hotKey, keyDownHandler: (_) => callback());
      _registeredHotKeys.add(hotKey);
    } on PlatformException catch (error) {
      debugPrint('Unable to register hotkey: $error');
    }
  }

  Future<void> showWindow({WorkspaceView? view}) async {
    if (view != null) {
      controller.setView(view);
    }
    await windowManager.setSkipTaskbar(false);
    await windowManager.setOpacity(1);
    await windowManager.show();
    await windowManager.restore();
    await windowManager.focus();
  }

  Future<void> showQuickMask() async {
    await showWindow(view: WorkspaceView.masked);
  }

  Future<void> hideWindow() async {
    await windowManager.hide();
    await windowManager.setOpacity(0);
    await windowManager.setSkipTaskbar(true);
  }

  Future<void> toggleWindow() async {
    if (await windowManager.isVisible()) {
      await hideWindow();
    } else {
      await showWindow();
    }
  }

  Future<void> quit() async {
    await hotKeyManager.unregisterAll();
    if (_usesNativeTray) {
      await _nativeTrayChannel.invokeMethod<void>('destroyTray');
    } else {
      await trayManager.destroy();
    }
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  void onWindowClose() {
    hideWindow();
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    _handleTrayAction(menuItem.key ?? '');
  }

  void _handleTrayAction(String action) {
    switch (action) {
      case 'quick_mask':
        showQuickMask();
        break;
      case 'show_window':
        showWindow();
        break;
      case 'hide_window':
        hideWindow();
        break;
      case 'exit_app':
        quit();
        break;
      case 'length_preserve':
        controller.setLengthMode(MaskLengthMode.preserve);
        refreshTrayMenu();
        break;
      case 'length_fixed':
        controller.setLengthMode(MaskLengthMode.fixed);
        refreshTrayMenu();
        break;
      case 'length_proportional':
        controller.setLengthMode(MaskLengthMode.proportional);
        refreshTrayMenu();
        break;
      case 'length_random':
        controller.setLengthMode(MaskLengthMode.randomRange);
        refreshTrayMenu();
        break;
      case 'token_asterisk':
        controller.setToken('*');
        refreshTrayMenu();
        break;
      case 'token_square':
        controller.setToken('█');
        refreshTrayMenu();
        break;
      case 'token_hash':
        controller.setToken('#');
        refreshTrayMenu();
        break;
      case 'token_x':
        controller.setToken('x');
        refreshTrayMenu();
        break;
    }
  }
}
