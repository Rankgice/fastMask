import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

enum ShortcutAction { quickMask, toggleWindow, togglePreview }

class ShortcutConfig {
  const ShortcutConfig({required this.key, required this.modifiers});

  final PhysicalKeyboardKey key;
  final List<HotKeyModifier> modifiers;

  static const defaults = <ShortcutAction, ShortcutConfig>{
    ShortcutAction.quickMask: ShortcutConfig(
      key: PhysicalKeyboardKey.keyB,
      modifiers: [HotKeyModifier.meta, HotKeyModifier.shift],
    ),
    ShortcutAction.toggleWindow: ShortcutConfig(
      key: PhysicalKeyboardKey.keyM,
      modifiers: [HotKeyModifier.meta, HotKeyModifier.shift],
    ),
    ShortcutAction.togglePreview: ShortcutConfig(
      key: PhysicalKeyboardKey.keyR,
      modifiers: [HotKeyModifier.meta],
    ),
  };

  HotKey toHotKey() {
    return HotKey(
      key: key,
      modifiers: List<HotKeyModifier>.unmodifiable(modifiers),
      scope: HotKeyScope.system,
    );
  }

  ShortcutConfig withModifiers(List<HotKeyModifier> value) {
    return ShortcutConfig(key: key, modifiers: value);
  }

  String get displayLabel {
    final labels = <String>[];
    for (final modifier in modifiers) {
      labels.add(switch (modifier) {
        HotKeyModifier.meta => '⌘',
        HotKeyModifier.control => '⌃',
        HotKeyModifier.alt => '⌥',
        HotKeyModifier.shift => '⇧',
        HotKeyModifier.capsLock => '⇪',
        HotKeyModifier.fn => 'fn',
      });
    }
    labels.add(key.keyLabel);
    return labels.join(' ');
  }

  Map<String, Object> toJson() => {
    'key': key.usbHidUsage,
    'modifiers': modifiers.map((modifier) => modifier.name).toList(),
  };

  factory ShortcutConfig.fromJson(Map<String, dynamic> json) {
    final key =
        PhysicalKeyboardKey.findKeyByCode(json['key'] as int? ?? 0) ??
        PhysicalKeyboardKey.keyB;
    final modifierNames = (json['modifiers'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toSet();
    final modifiers = HotKeyModifier.values
        .where((modifier) => modifierNames.contains(modifier.name))
        .toList();
    return ShortcutConfig(key: key, modifiers: modifiers);
  }
}
