import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/app_controller.dart';
import '../models/mask_range.dart';
import '../models/mask_rule.dart';
import '../models/shortcut_config.dart';
import '../services/desktop_service.dart';
import '../theme/app_theme.dart';
import '../theme/workspace_text_style.dart';
import '../widgets/mask_rule_panel.dart';
import '../widgets/masked_text_view.dart';
import '../widgets/shortcut_recorder_field.dart';

enum _AppSection { workspace, settings }

enum _SettingsSection { rules, shortcuts }

class HomePage extends StatefulWidget {
  const HomePage({
    required this.controller,
    required this.desktopService,
    super.key,
  });

  final AppController controller;
  final DesktopService desktopService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TextEditingController _editorController;
  late final FocusNode _editorFocusNode;
  _AppSection _section = _AppSection.workspace;
  _SettingsSection _settingsSection = _SettingsSection.rules;

  AppController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _editorController = TextEditingController(text: controller.sourceText);
    _editorFocusNode = FocusNode()..addListener(_onEditorFocusChanged);
    controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    _editorFocusNode
      ..removeListener(_onEditorFocusChanged)
      ..dispose();
    _editorController.dispose();
    super.dispose();
  }

  void _onEditorFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    if (_editorController.text != controller.sourceText) {
      _editorController.value = TextEditingValue(
        text: controller.sourceText,
        selection: TextSelection.collapsed(
          offset: controller.sourceText.length,
        ),
      );
    }

    if (controller.rangesWereClearedByEdit) {
      controller.acknowledgeClearedRanges();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('文本内容已修改，原有遮挡区域已清除。')));
      });
    }

    if (controller.view == WorkspaceView.masked && _editorFocusNode.hasFocus) {
      _editorFocusNode.unfocus();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 140),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _section == _AppSection.workspace
            ? Padding(
                key: const ValueKey('workspace-page'),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: _buildWorkspace(),
              )
            : Padding(
                key: const ValueKey('settings-page'),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: _buildSettings(),
              ),
      ),
    );
  }

  Widget _buildWorkspace() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(),
        const SizedBox(height: 6),
        Expanded(child: _buildEditor()),
        const SizedBox(height: 6),
        _buildActionBar(),
      ],
    );
  }

  Widget _buildEditor() {
    final textStyle = workspaceTextStyle(context);
    const radius = BorderRadius.all(Radius.circular(4));

    return Container(
      key: const ValueKey('workspace-content-frame'),
      decoration: BoxDecoration(
        color: AppColors.editorSurface,
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: _EditorPane(
          view: controller.view,
          text: controller.sourceText,
          editorController: _editorController,
          focusNode: _editorFocusNode,
          textStyle: textStyle,
          ranges: controller.maskRanges,
          rule: controller.rule,
          onChanged: controller.setSourceText,
          onAddRange: (range) {
            controller.addMaskRange(range.start, range.end);
          },
          onRemoveRange: controller.removeMaskRange,
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final showEditWarning =
        controller.view == WorkspaceView.edit &&
        _editorFocusNode.hasFocus &&
        controller.maskRanges.isNotEmpty;

    return SizedBox(
      height: 30,
      child: Row(
        children: [
          _ModeTab(
            label: '编辑',
            selected: controller.view == WorkspaceView.edit,
            onTap: () => controller.setView(WorkspaceView.edit),
          ),
          const SizedBox(width: 4),
          _ModeTab(
            label: '模糊',
            selected: controller.view == WorkspaceView.masked,
            onTap: () => controller.setView(WorkspaceView.masked),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: showEditWarning
                  ? const Text(
                      '编辑内容将清空遮挡区域。',
                      key: ValueKey('edit-clears-masks-warning'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          if (controller.view == WorkspaceView.edit)
            _ToolbarIconButton(
              key: const ValueKey('paste-action'),
              tooltip: '粘贴',
              icon: Icons.content_paste_outlined,
              onPressed: _pasteFromClipboard,
            ),
          if (controller.view == WorkspaceView.masked &&
              controller.maskRanges.isNotEmpty)
            _ToolbarIconButton(
              key: const ValueKey('clear-masks-action'),
              tooltip: '清除遮挡',
              icon: Icons.layers_clear_outlined,
              onPressed: controller.clearMasks,
            ),
          const SizedBox(width: 4),
          _ToolbarIconButton(
            key: const ValueKey('copy-masked-action'),
            tooltip: '复制模糊文本',
            icon: Icons.copy_all_outlined,
            onPressed: _copyMasked,
          ),
          _ToolbarIconButton(
            key: const ValueKey('copy-and-close-action'),
            tooltip: '复制并关闭',
            icon: Icons.done_all_outlined,
            onPressed: _copyAndHide,
          ),
          _ToolbarIconButton(
            key: const ValueKey('settings-action'),
            tooltip: '设置',
            icon: Icons.settings_outlined,
            onPressed: () {
              setState(() {
                _section = _AppSection.settings;
                _settingsSection = _SettingsSection.rules;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    final maskCount = controller.maskRanges.length;
    final characterCount = controller.sourceText.characters.length;

    return SizedBox(
      height: 22,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Row(
          children: [
            Text(
              '$characterCount 个字符',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            const SizedBox(width: 12),
            Text(
              '$maskCount 个遮挡区域',
              style: TextStyle(
                color: maskCount == 0 ? AppColors.textMuted : AppColors.primary,
                fontSize: 11,
                fontWeight: maskCount == 0 ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              controller.view == WorkspaceView.edit
                  ? '拖动选择文本后切换到模糊模式'
                  : '拖动添加遮挡，点击已有遮挡可移除',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 30,
          child: Row(
            children: [
              _ToolbarIconButton(
                key: const ValueKey('back-to-workspace-action'),
                tooltip: '返回工作台',
                icon: Icons.arrow_back_ios_new_outlined,
                onPressed: () {
                  setState(() => _section = _AppSection.workspace);
                },
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: _SettingsPageTitle(
                  title: '设置',
                  description: '调整遮挡效果与快捷操作',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    width: 128,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: [
                          _SettingsNavItem(
                            label: '模糊规则',
                            icon: Icons.rule_outlined,
                            selectedIcon: Icons.rule,
                            selected:
                                _settingsSection == _SettingsSection.rules,
                            onTap: () {
                              setState(() {
                                _settingsSection = _SettingsSection.rules;
                              });
                            },
                          ),
                          const SizedBox(height: 3),
                          _SettingsNavItem(
                            label: '快捷键',
                            icon: Icons.keyboard_outlined,
                            selectedIcon: Icons.keyboard,
                            selected:
                                _settingsSection == _SettingsSection.shortcuts,
                            onTap: () {
                              setState(() {
                                _settingsSection = _SettingsSection.shortcuts;
                              });
                            },
                          ),
                          const Spacer(),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(7, 8, 7, 5),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 13,
                                  color: AppColors.textMuted,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  '本地处理',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 140),
                      child: _settingsSection == _SettingsSection.rules
                          ? MaskRulePanel(
                              key: const ValueKey('rule-panel'),
                              rule: controller.rule,
                              onSaved: (rule) {
                                controller.setRule(rule);
                                widget.desktopService.refreshTrayMenu();
                              },
                            )
                          : _buildShortcutSettings(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutSettings() {
    return SingleChildScrollView(
      key: const ValueKey('shortcut-panel'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SettingsPanelHeading(
                  title: '快捷键',
                  description: '修改后立即生效，Esc 始终用于关闭窗口。',
                ),
              ),
              _SettingsQuietButton(
                icon: Icons.restart_alt,
                label: '恢复默认',
                onPressed: () {
                  controller.resetShortcuts();
                  widget.desktopService.refreshHotKeys();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            title: '功能快捷键',
            description: '点击录制框后按下新的组合键。',
            child: Column(
              children: [
                _buildShortcutRow(
                  ShortcutAction.quickMask,
                  '打开快速模糊',
                  '显示窗口并进入模糊视图',
                ),
                const SizedBox(height: 7),
                _buildShortcutRow(
                  ShortcutAction.toggleWindow,
                  '显示/隐藏主窗口',
                  '在后台显示或隐藏工作台',
                ),
                const SizedBox(height: 7),
                _buildShortcutRow(
                  ShortcutAction.togglePreview,
                  '编辑/模糊切换',
                  '在工作台编辑和模糊结果之间切换',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.28),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 15,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'macOS 首次使用时，可能需要在“系统设置 → 隐私与安全性 → 输入监控 / 辅助功能”中允许 FastMask。',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(
    ShortcutAction action,
    String title,
    String description,
  ) {
    final config =
        controller.shortcuts[action] ?? ShortcutConfig.defaults[action]!;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
      decoration: BoxDecoration(
        color: AppColors.canvas.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 154,
            child: ShortcutRecorderField(
              action: action,
              config: config,
              onRecorded: (value) {
                final duplicate = controller.shortcuts.entries.any((entry) {
                  if (entry.key == action) {
                    return false;
                  }
                  final other = entry.value;
                  if (other.key != value.key ||
                      other.modifiers.length != value.modifiers.length) {
                    return false;
                  }
                  return other.modifiers.every(value.modifiers.contains);
                });
                if (duplicate) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('该快捷键已用于其他功能，请换一个组合。')),
                  );
                  return;
                }
                controller.setShortcut(action, value);
                widget.desktopService.refreshHotKeys();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      return;
    }
    controller.setSourceText(text);
    controller.setView(WorkspaceView.edit);
    _editorController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _copyMasked() async {
    await Clipboard.setData(ClipboardData(text: controller.maskedText));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('模糊后的文本已复制。')));
  }

  Future<void> _copyAndHide() async {
    await Clipboard.setData(ClipboardData(text: controller.maskedText));
    await widget.desktopService.hideWindow();
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(46, 28)),
        maximumSize: const WidgetStatePropertyAll(Size(64, 28)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 10),
        ),
        foregroundColor: WidgetStatePropertyAll(
          selected ? AppColors.textPrimary : AppColors.textSecondary,
        ),
        backgroundColor: WidgetStatePropertyAll(
          selected ? AppColors.selectedSurface : Colors.transparent,
        ),
        overlayColor: const WidgetStatePropertyAll(AppColors.hoverSurface),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }
}

class _SettingsPageTitle extends StatelessWidget {
  const _SettingsPageTitle({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _SettingsNavItem extends StatelessWidget {
  const _SettingsNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.selectedSurface : Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        hoverColor: AppColors.hoverSurface,
        child: SizedBox(
          height: 34,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 16,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsPanelHeading extends StatelessWidget {
  const _SettingsPanelHeading({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _SettingsQuietButton extends StatelessWidget {
  const _SettingsQuietButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(AppColors.textSecondary),
        overlayColor: const WidgetStatePropertyAll(AppColors.hoverSurface),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 8),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(0, 28)),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
      ),
      icon: Icon(icon, size: 15),
      label: Text(label),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.child,
    this.description,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (description != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _EditorPane extends StatefulWidget {
  const _EditorPane({
    required this.view,
    required this.text,
    required this.editorController,
    required this.focusNode,
    required this.textStyle,
    required this.ranges,
    required this.rule,
    required this.onChanged,
    required this.onAddRange,
    required this.onRemoveRange,
  });

  final WorkspaceView view;
  final String text;
  final TextEditingController editorController;
  final FocusNode focusNode;
  final TextStyle textStyle;
  final List<MaskRange> ranges;
  final MaskRule rule;
  final ValueChanged<String> onChanged;
  final ValueChanged<MaskRange> onAddRange;
  final ValueChanged<MaskRange> onRemoveRange;

  @override
  State<_EditorPane> createState() => _EditorPaneState();
}

class _EditorPaneState extends State<_EditorPane> {
  final ScrollController _editScrollController = ScrollController();
  final ScrollController _maskedScrollController = ScrollController();
  late final Listenable _scrollListenable = Listenable.merge([
    _editScrollController,
    _maskedScrollController,
  ]);

  ScrollController get _activeScrollController =>
      widget.view == WorkspaceView.edit
      ? _editScrollController
      : _maskedScrollController;

  @override
  void didUpdateWidget(covariant _EditorPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.view == widget.view) {
      return;
    }

    final previousController = oldWidget.view == WorkspaceView.edit
        ? _editScrollController
        : _maskedScrollController;
    final nextController = _activeScrollController;
    final previousOffset = previousController.hasClients
        ? previousController.offset
        : 0.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !nextController.hasClients) {
        return;
      }
      nextController.jumpTo(
        previousOffset.clamp(
          nextController.position.minScrollExtent,
          nextController.position.maxScrollExtent,
        ),
      );
    });
  }

  @override
  void dispose() {
    _editScrollController.dispose();
    _maskedScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LineNumberGutter(
          text: widget.text,
          style: widget.textStyle,
          scrollController: _activeScrollController,
          scrollListenable: _scrollListenable,
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Padding(
            padding: workspaceTextPadding,
            child: widget.view == WorkspaceView.edit
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(
                            context,
                          ).copyWith(scrollbars: false),
                          child: TextField(
                            controller: widget.editorController,
                            focusNode: widget.focusNode,
                            scrollController: _editScrollController,
                            expands: true,
                            maxLines: null,
                            minLines: null,
                            keyboardType: TextInputType.multiline,
                            textAlignVertical: TextAlignVertical.top,
                            cursorWidth: 1.4,
                            cursorColor: AppColors.primary,
                            style: widget.textStyle,
                            strutStyle: workspaceStrutStyle(widget.textStyle),
                            decoration: null,
                            onChanged: widget.onChanged,
                          ),
                        ),
                      ),
                      if (widget.editorController.text.isEmpty)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                '在此粘贴或输入文本…',
                                style: widget.textStyle.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: MaskedTextView(
                          text: widget.text,
                          ranges: widget.ranges,
                          rule: widget.rule,
                          showMasked: widget.view == WorkspaceView.masked,
                          onAddRange: widget.onAddRange,
                          onRemoveRange: widget.onRemoveRange,
                          scrollController: _maskedScrollController,
                        ),
                      ),
                      if (widget.text.isEmpty)
                        const Center(
                          child: IgnorePointer(
                            child: Text(
                              '拖动鼠标选择要遮挡的文本',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _LineNumberGutter extends StatelessWidget {
  const _LineNumberGutter({
    required this.text,
    required this.style,
    required this.scrollController,
    required this.scrollListenable,
  });

  final String text;
  final TextStyle style;
  final ScrollController scrollController;
  final Listenable scrollListenable;

  @override
  Widget build(BuildContext context) {
    final lineCount = text.isEmpty ? 1 : '\n'.allMatches(text).length + 1;
    final lineHeight = style.fontSize! * style.height!;

    return Container(
      width: 50,
      color: AppColors.editorGutter,
      child: AnimatedBuilder(
        animation: scrollListenable,
        builder: (context, _) {
          return ClipRect(
            child: CustomPaint(
              painter: _LineNumberPainter(
                lineCount: lineCount,
                lineHeight: lineHeight,
                topPadding: workspaceTextPadding.top,
                offset: scrollController.hasClients
                    ? scrollController.offset
                    : 0,
                style: style.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1,
                  fontFeatures: const [],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
    );
  }
}

class _LineNumberPainter extends CustomPainter {
  const _LineNumberPainter({
    required this.lineCount,
    required this.lineHeight,
    required this.topPadding,
    required this.offset,
    required this.style,
  });

  final int lineCount;
  final double lineHeight;
  final double topPadding;
  final double offset;
  final TextStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < lineCount; index++) {
      final painter = TextPainter(
        text: TextSpan(text: '${index + 1}', style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final y =
          topPadding +
          index * lineHeight +
          (lineHeight - painter.height) / 2 -
          offset;
      if (y + painter.height < 0 || y > size.height) {
        continue;
      }
      painter.paint(canvas, Offset(size.width - 10 - painter.width, y));
    }
  }

  @override
  bool shouldRepaint(_LineNumberPainter oldDelegate) {
    return oldDelegate.lineCount != lineCount ||
        oldDelegate.lineHeight != lineHeight ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.offset != offset ||
        oldDelegate.style != style;
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 17),
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.square(30)),
          maximumSize: const WidgetStatePropertyAll(Size.square(30)),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.pressed)
                ? AppColors.textPrimary
                : AppColors.textSecondary;
          }),
          overlayColor: const WidgetStatePropertyAll(AppColors.hoverSurface),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ),
    );
  }
}
