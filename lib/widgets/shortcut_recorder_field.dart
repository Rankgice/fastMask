import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../models/shortcut_config.dart';
import '../theme/app_theme.dart';

class ShortcutRecorderField extends StatefulWidget {
  const ShortcutRecorderField({
    required this.action,
    required this.config,
    required this.onRecorded,
    super.key,
  });

  final ShortcutAction action;
  final ShortcutConfig config;
  final ValueChanged<ShortcutConfig> onRecorded;

  @override
  State<ShortcutRecorderField> createState() => _ShortcutRecorderFieldState();
}

class _ShortcutRecorderFieldState extends State<ShortcutRecorderField> {
  bool _recording = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: () => setState(() => _recording = true),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: _recording
              ? AppColors.primarySoft
              : AppColors.editorSurface,
          side: BorderSide(
            color: _recording ? primary : AppColors.borderStrong,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _recording ? '请按下快捷键…' : widget.config.displayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _recording ? primary : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              _recording ? Icons.keyboard : Icons.edit_outlined,
              size: 15,
              color: _recording ? primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    if (!_recording || event is! KeyDownEvent) {
      return false;
    }

    final pressed = HardwareKeyboard.instance.physicalKeysPressed;
    final modifiers = <HotKeyModifier>[
      if (pressed.contains(PhysicalKeyboardKey.metaLeft) ||
          pressed.contains(PhysicalKeyboardKey.metaRight))
        HotKeyModifier.meta,
      if (pressed.contains(PhysicalKeyboardKey.controlLeft) ||
          pressed.contains(PhysicalKeyboardKey.controlRight))
        HotKeyModifier.control,
      if (pressed.contains(PhysicalKeyboardKey.altLeft) ||
          pressed.contains(PhysicalKeyboardKey.altRight))
        HotKeyModifier.alt,
      if (pressed.contains(PhysicalKeyboardKey.shiftLeft) ||
          pressed.contains(PhysicalKeyboardKey.shiftRight))
        HotKeyModifier.shift,
    ];
    final key = event.physicalKey;
    final isModifierKey = <PhysicalKeyboardKey>{
      PhysicalKeyboardKey.metaLeft,
      PhysicalKeyboardKey.metaRight,
      PhysicalKeyboardKey.controlLeft,
      PhysicalKeyboardKey.controlRight,
      PhysicalKeyboardKey.altLeft,
      PhysicalKeyboardKey.altRight,
      PhysicalKeyboardKey.shiftLeft,
      PhysicalKeyboardKey.shiftRight,
      PhysicalKeyboardKey.capsLock,
      PhysicalKeyboardKey.fn,
    }.contains(key);

    if (isModifierKey) {
      return true;
    }

    if (modifiers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('快捷键至少需要一个修饰键（⌘ / ⌃ / ⌥ / ⇧）。')),
      );
      return true;
    }

    widget.onRecorded(ShortcutConfig(key: key, modifiers: modifiers));
    setState(() => _recording = false);
    return true;
  }
}
