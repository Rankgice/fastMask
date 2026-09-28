import 'package:fast_mask/controllers/app_controller.dart';
import 'package:fast_mask/models/mask_rule.dart';
import 'package:fast_mask/pages/home_page.dart';
import 'package:fast_mask/services/desktop_service.dart';
import 'package:fast_mask/theme/workspace_text_style.dart';
import 'package:fast_mask/widgets/masked_text_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows two workspace views and contextual actions', (
    tester,
  ) async {
    final controller = AppController();
    final desktopService = DesktopService(controller: controller);

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(controller: controller, desktopService: desktopService),
      ),
    );

    expect(find.text('编辑'), findsOneWidget);
    expect(find.text('模糊'), findsOneWidget);
    expect(find.text('原文'), findsNothing);
    expect(find.byTooltip('粘贴'), findsOneWidget);
    expect(find.byTooltip('清除遮挡'), findsNothing);
    expect(find.text('在此粘贴或输入文本…'), findsOneWidget);
    expect(find.byTooltip('隐藏窗口'), findsNothing);

    final editor = tester.widget<TextField>(find.byType(TextField));
    expect(editor.focusNode?.hasFocus, isFalse);

    await tester.tap(find.text('模糊'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('粘贴'), findsNothing);
    expect(find.byTooltip('清除遮挡'), findsNothing);

    controller.addMaskRange(0, 2);
    await tester.pumpAndSettle();

    expect(find.byTooltip('清除遮挡'), findsOneWidget);
  });

  testWidgets('uses the same content frame geometry in edit and masked views', (
    tester,
  ) async {
    final controller = AppController();
    final desktopService = DesktopService(controller: controller);
    controller.setSourceText('一段用于检查切换时文字的布局稳定性文本');

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(controller: controller, desktopService: desktopService),
      ),
    );

    final editFrame = tester.getRect(
      find.byKey(const ValueKey('workspace-content-frame')),
    );
    final editText = tester.widget<TextField>(find.byType(TextField));
    expect(editText.decoration, isNull);
    expect(find.byType(InputDecorator), findsNothing);

    await tester.tap(find.text('模糊'));
    await tester.pumpAndSettle();

    final maskedFrame = tester.getRect(
      find.byKey(const ValueKey('workspace-content-frame')),
    );
    final maskedView = tester.widget<MaskedTextView>(
      find.byType(MaskedTextView),
    );

    expect(maskedFrame, editFrame);
    expect(maskedView.contentPadding, EdgeInsets.zero);
    expect(workspaceTextPadding, const EdgeInsets.fromLTRB(12, 8, 12, 8));
  });

  testWidgets('warns only while editing focused text with masks', (
    tester,
  ) async {
    final controller = AppController();
    final desktopService = DesktopService(controller: controller);
    controller.setSourceText('123456789');
    controller.addMaskRange(4, 8);

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(controller: controller, desktopService: desktopService),
      ),
    );

    const warning = '编辑内容将清空遮挡区域。';
    expect(find.text(warning), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.text(warning), findsOneWidget);

    await tester.tap(find.text('模糊'));
    await tester.pumpAndSettle();
    expect(find.text(warning), findsNothing);

    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    expect(find.text(warning), findsNothing);
  });

  testWidgets('opens settings with rule and shortcut sections', (tester) async {
    final controller = AppController();
    final desktopService = DesktopService(controller: controller);

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(controller: controller, desktopService: desktopService),
      ),
    );

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();

    expect(find.text('模糊规则'), findsWidgets);
    expect(find.text('快捷键'), findsOneWidget);
  });

  testWidgets('rule changes require an explicit save', (tester) async {
    final controller = AppController();
    final desktopService = DesktopService(controller: controller);

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(controller: controller, desktopService: desktopService),
      ),
    );

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();

    FilledButton saveButton() {
      return tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '保存'),
      );
    }

    expect(saveButton().onPressed, isNull);

    await tester.tap(find.text('纯色遮挡'));
    await tester.pumpAndSettle();

    expect(controller.rule.visualStyle, MaskVisualStyle.glyph);
    expect(saveButton().onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(controller.rule.visualStyle, MaskVisualStyle.solid);
    expect(saveButton().onPressed, isNull);
  });
}
