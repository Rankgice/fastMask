import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mask_range.dart';
import '../models/mask_rule.dart';
import '../models/shortcut_config.dart';
import '../services/mask_engine.dart';

enum WorkspaceView { edit, masked }

class AppController extends ChangeNotifier {
  AppController({SharedPreferences? preferences}) : _preferences = preferences;

  static const _ruleKey = 'mask_rule';
  static const _shortcutsKey = 'shortcuts';

  final SharedPreferences? _preferences;
  final Random _random = Random();

  String _sourceText = '';
  List<MaskRange> _maskRanges = const [];
  MaskRule _rule = const MaskRule();
  WorkspaceView _view = WorkspaceView.edit;
  Map<ShortcutAction, ShortcutConfig> _shortcuts = ShortcutConfig.defaults;
  bool _rangesWereClearedByEdit = false;

  String get sourceText => _sourceText;
  List<MaskRange> get maskRanges => List.unmodifiable(_maskRanges);
  MaskRule get rule => _rule;
  WorkspaceView get view => _view;
  bool get showMasked => _view == WorkspaceView.masked;
  Map<ShortcutAction, ShortcutConfig> get shortcuts =>
      Map.unmodifiable(_shortcuts);
  bool get rangesWereClearedByEdit => _rangesWereClearedByEdit;
  String get maskedText => MaskEngine.render(_sourceText, _maskRanges, _rule);

  Future<void> initialize() async {
    final encodedRule = _preferences?.getString(_ruleKey);
    if (encodedRule != null) {
      try {
        final json = jsonDecode(encodedRule) as Map<String, dynamic>;
        _rule = MaskRule.fromJson(json);
      } on FormatException {
        // Keep defaults when stored data cannot be decoded.
      }
    }

    final encodedShortcuts = _preferences?.getString(_shortcutsKey);
    if (encodedShortcuts != null) {
      try {
        final json = jsonDecode(encodedShortcuts) as Map<String, dynamic>;
        _shortcuts = {
          for (final action in ShortcutAction.values)
            action: json[action.name] is Map<String, dynamic>
                ? ShortcutConfig.fromJson(
                    json[action.name] as Map<String, dynamic>,
                  )
                : ShortcutConfig.defaults[action]!,
        };
      } catch (_) {
        _shortcuts = ShortcutConfig.defaults;
      }
    }

    notifyListeners();
  }

  void setSourceText(String value) {
    if (value == _sourceText) {
      return;
    }

    _sourceText = value;
    _rangesWereClearedByEdit = _maskRanges.isNotEmpty;
    if (_rangesWereClearedByEdit) {
      _maskRanges = const [];
    }
    notifyListeners();
  }

  void clearSource() {
    _sourceText = '';
    _maskRanges = const [];
    _rangesWereClearedByEdit = false;
    notifyListeners();
  }

  void acknowledgeClearedRanges() {
    _rangesWereClearedByEdit = false;
  }

  void setView(WorkspaceView value) {
    if (_view == value) {
      return;
    }
    _view = value;
    notifyListeners();
  }

  void setShowMasked(bool value) {
    setView(value ? WorkspaceView.masked : WorkspaceView.edit);
  }

  void togglePreview() {
    setView(
      _view == WorkspaceView.edit ? WorkspaceView.masked : WorkspaceView.edit,
    );
  }

  void addMaskRange(int start, int end) {
    if (start == end) {
      return;
    }

    final normalizedStart = min(start, end);
    final normalizedEnd = max(start, end);
    final incoming = MaskRange(
      start: normalizedStart,
      end: normalizedEnd,
      seed: _random.nextInt(1 << 31),
    );

    _maskRanges = MaskEngine.addRange(_maskRanges, incoming);
    _rangesWereClearedByEdit = false;
    notifyListeners();
  }

  void removeMaskRange(MaskRange range) {
    final next = _maskRanges
        .where(
          (candidate) =>
              candidate.start != range.start ||
              candidate.end != range.end ||
              candidate.seed != range.seed,
        )
        .toList();
    if (next.length == _maskRanges.length) {
      return;
    }
    _maskRanges = next;
    notifyListeners();
  }

  void removeMaskAt(int offset) {
    final range = MaskEngine.rangeAt(offset, _maskRanges);
    if (range != null) {
      removeMaskRange(range);
    }
  }

  void clearMasks() {
    if (_maskRanges.isEmpty) {
      return;
    }
    _maskRanges = const [];
    notifyListeners();
  }

  void setRule(MaskRule value) {
    _rule = value;
    _persistRule();
    notifyListeners();
  }

  void setLengthMode(MaskLengthMode value) {
    setRule(_rule.copyWith(lengthMode: value));
  }

  void setToken(String value) {
    if (value.isEmpty) {
      return;
    }
    setRule(
      _rule.copyWith(token: value, patternPreset: MaskPatternPreset.custom),
    );
  }

  void setShortcut(ShortcutAction action, ShortcutConfig config) {
    _shortcuts = {..._shortcuts, action: config};
    _preferences?.setString(
      _shortcutsKey,
      jsonEncode({
        for (final entry in _shortcuts.entries)
          entry.key.name: entry.value.toJson(),
      }),
    );
    notifyListeners();
  }

  void resetShortcuts() {
    _shortcuts = ShortcutConfig.defaults;
    _preferences?.setString(
      _shortcutsKey,
      jsonEncode({
        for (final entry in _shortcuts.entries)
          entry.key.name: entry.value.toJson(),
      }),
    );
    notifyListeners();
  }

  Future<void> _persistRule() async {
    await _preferences?.setString(_ruleKey, jsonEncode(_rule.toJson()));
  }
}
