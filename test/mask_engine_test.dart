import 'package:fast_mask/controllers/app_controller.dart';
import 'package:fast_mask/models/mask_range.dart';
import 'package:fast_mask/models/mask_rule.dart';
import 'package:fast_mask/services/mask_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppController', () {
    test('togglePreview switches between edit and masked views', () {
      final controller = AppController();

      expect(controller.view, WorkspaceView.edit);
      controller.togglePreview();
      expect(controller.view, WorkspaceView.masked);
      controller.togglePreview();
      expect(controller.view, WorkspaceView.edit);
    });
  });

  group('MaskEngine', () {
    test('uses a readable default mask palette', () {
      const rule = MaskRule();

      expect(rule.backgroundColor.value, MaskRule.defaultBackgroundColor);
      expect(rule.foregroundColor.value, MaskRule.defaultForegroundColor);
      expect(rule.backgroundColor.value, isNot(0xFF1F2933));
      expect(rule.foregroundColor.value, isNot(0xFFFFFFFF));
    });

    test('migrates legacy default mask colors from saved rules', () {
      final rule = MaskRule.fromJson({
        'backgroundColor': 0xFF1F2933,
        'foregroundColor': 0xFFFFFFFF,
      });

      expect(rule.backgroundColor.value, MaskRule.defaultBackgroundColor);
      expect(rule.foregroundColor.value, MaskRule.defaultForegroundColor);
    });

    test('preserves source and masks only selected ranges', () {
      const source = 'phone=13812345678';
      const range = MaskRange(start: 6, end: 17, seed: 1);
      const rule = MaskRule();

      expect(
        MaskEngine.render(source, const [range], rule),
        'phone=***********',
      );
      expect(source, 'phone=13812345678');
    });

    test('supports fixed replacement text', () {
      const source = 'token: abcdef';
      const range = MaskRange(start: 7, end: 13, seed: 1);
      const rule = MaskRule(
        lengthMode: MaskLengthMode.fixed,
        fixedText: '[REDACTED]',
      );

      expect(
        MaskEngine.render(source, const [range], rule),
        'token: [REDACTED]',
      );
    });

    test('preserves line breaks in preserve-length mode', () {
      const source = 'ab\ncd';
      const range = MaskRange(start: 0, end: 5, seed: 1);

      expect(
        MaskEngine.render(source, const [range], const MaskRule()),
        '**\n**',
      );
    });

    test('supports proportional multi-character tokens', () {
      const source = 'abcdef';
      const range = MaskRange(start: 0, end: 6, seed: 1);
      const rule = MaskRule(
        lengthMode: MaskLengthMode.proportional,
        token: 'xx',
        ratio: 0.5,
      );

      expect(MaskEngine.render(source, const [range], rule), 'xxx');
    });

    test('random-length rules are deterministic for a mask range', () {
      const source = 'abcdefghij';
      const range = MaskRange(start: 0, end: 10, seed: 42);
      const rule = MaskRule(
        lengthMode: MaskLengthMode.randomRange,
        minDelta: -3,
        maxDelta: 3,
      );

      final first = MaskEngine.render(source, const [range], rule);
      final second = MaskEngine.render(source, const [range], rule);

      expect(first, second);
      expect(first.length, inInclusiveRange(7, 13));
    });

    test('merges overlapping ranges', () {
      final ranges = MaskEngine.addRange(const [
        MaskRange(start: 2, end: 5, seed: 1),
      ], const MaskRange(start: 4, end: 8, seed: 2));

      expect(ranges, hasLength(1));
      expect(ranges.single.start, 2);
      expect(ranges.single.end, 8);
    });

    test('merges adjacent ranges and renders them as one mask', () {
      final first = MaskEngine.addRange(
        const [],
        const MaskRange(start: 4, end: 6, seed: 1),
      );
      final ranges = MaskEngine.addRange(
        first,
        const MaskRange(start: 6, end: 8, seed: 2),
      );

      expect(ranges, hasLength(1));
      expect(ranges.single.start, 4);
      expect(ranges.single.end, 8);
      expect(
        MaskEngine.render(
          '123456789',
          ranges,
          const MaskRule(lengthMode: MaskLengthMode.fixed, fixedText: '[已隐藏]'),
        ),
        '1234[已隐藏]9',
      );
    });
  });
}
