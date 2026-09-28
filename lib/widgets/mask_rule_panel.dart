import 'package:flutter/material.dart';

import '../models/mask_rule.dart';
import '../theme/app_theme.dart';

class MaskRulePanel extends StatefulWidget {
  const MaskRulePanel({required this.rule, required this.onSaved, super.key});

  final MaskRule rule;
  final ValueChanged<MaskRule> onSaved;

  @override
  State<MaskRulePanel> createState() => _MaskRulePanelState();
}

class _MaskRulePanelState extends State<MaskRulePanel> {
  late MaskRule _savedRule;
  late MaskRule _draft;
  late final TextEditingController _fixedTextController;
  late final TextEditingController _customTokenController;

  bool get _isDirty => _draft != _savedRule;

  @override
  void initState() {
    super.initState();
    _savedRule = widget.rule;
    _draft = widget.rule;
    _fixedTextController = TextEditingController(text: _draft.fixedText);
    _customTokenController = TextEditingController(
      text: _isPresetToken(_draft.token) ? '' : _draft.token,
    );
  }

  @override
  void didUpdateWidget(covariant MaskRulePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rule == oldWidget.rule) {
      return;
    }

    final wasClean = !_isDirty;
    _savedRule = widget.rule;
    if (wasClean) {
      _draft = widget.rule;
      _syncTextControllers();
    }
  }

  @override
  void dispose() {
    _fixedTextController.dispose();
    _customTokenController.dispose();
    super.dispose();
  }

  void _syncTextControllers() {
    _fixedTextController.text = _draft.fixedText;
    _customTokenController.text = _isPresetToken(_draft.token)
        ? ''
        : _draft.token;
  }

  bool _isPresetToken(String token) =>
      const ['*', '█', '#', 'x'].contains(token);

  void _updateDraft(MaskRule value) {
    if (value == _draft) {
      return;
    }
    setState(() => _draft = value);
  }

  void _save() {
    if (!_isDirty) {
      return;
    }

    final value = _draft;
    setState(() => _savedRule = value);
    widget.onSaved(value);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('模糊规则已保存。')));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '模糊规则',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '只影响预览和复制结果，不会直接修改原文。',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _isDirty ? _save : null,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('保存'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _SectionLabel('模糊后长度'),
          const SizedBox(height: 7),
          DropdownButtonFormField<MaskLengthMode>(
            key: ValueKey('length-mode-${_draft.lengthMode}'),
            initialValue: _draft.lengthMode,
            decoration: const InputDecoration(labelText: '长度规则'),
            items: const [
              DropdownMenuItem(
                value: MaskLengthMode.preserve,
                child: Text('保持原长度'),
              ),
              DropdownMenuItem(
                value: MaskLengthMode.fixed,
                child: Text('固定替换文本'),
              ),
              DropdownMenuItem(
                value: MaskLengthMode.proportional,
                child: Text('按比例'),
              ),
              DropdownMenuItem(
                value: MaskLengthMode.randomRange,
                child: Text('随机增减'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _updateDraft(_draft.copyWith(lengthMode: value));
              }
            },
          ),
          const SizedBox(height: 10),
          _buildLengthOptions(),
          const SizedBox(height: 14),
          const _SectionLabel('遮挡字符'),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['*', '█', '#', 'x'].map((token) {
              final selected = _draft.token == token;
              return ChoiceChip(
                label: Text(
                  token,
                  style: TextStyle(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                selected: selected,
                showCheckmark: false,
                selectedColor: AppColors.selectedSurface,
                backgroundColor: AppColors.editorSurface,
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.borderStrong,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                onSelected: (_) {
                  _customTokenController.clear();
                  _updateDraft(
                    _draft.copyWith(
                      token: token,
                      patternPreset: switch (token) {
                        '*' => MaskPatternPreset.asterisk,
                        '█' => MaskPatternPreset.square,
                        '#' => MaskPatternPreset.hash,
                        _ => MaskPatternPreset.custom,
                      },
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _customTokenController,
            decoration: const InputDecoration(
              labelText: '自定义字符',
              hintText: '例如 ■ 或 [隐藏]',
            ),
            onChanged: (value) {
              _updateDraft(
                _draft.copyWith(
                  token: value,
                  patternPreset: MaskPatternPreset.custom,
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          const _SectionLabel('显示样式'),
          const SizedBox(height: 7),
          SegmentedButton<MaskVisualStyle>(
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            segments: const [
              ButtonSegment(
                value: MaskVisualStyle.glyph,
                icon: Icon(Icons.text_fields_outlined, size: 16),
                label: Text('字符覆盖'),
              ),
              ButtonSegment(
                value: MaskVisualStyle.solid,
                icon: Icon(Icons.square_outlined, size: 16),
                label: Text('纯色遮挡'),
              ),
            ],
            selected: {_draft.visualStyle},
            onSelectionChanged: (selection) {
              _updateDraft(_draft.copyWith(visualStyle: selection.first));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLengthOptions() {
    switch (_draft.lengthMode) {
      case MaskLengthMode.preserve:
        return const _HintBox(text: '遮挡字符数量与原文可见字符数量一致。');
      case MaskLengthMode.fixed:
        return TextFormField(
          controller: _fixedTextController,
          decoration: const InputDecoration(
            labelText: '固定替换文本',
            hintText: '请输入替换文本',
          ),
          onChanged: (value) {
            _updateDraft(_draft.copyWith(fixedText: value));
          },
        );
      case MaskLengthMode.proportional:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '当前比例：${_draft.ratio.toStringAsFixed(2)}×',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            Slider(
              value: _draft.ratio.clamp(0.25, 2.0).toDouble(),
              min: 0.25,
              max: 2,
              divisions: 7,
              label: '${_draft.ratio.toStringAsFixed(2)}×',
              onChanged: (value) {
                _updateDraft(_draft.copyWith(ratio: value));
              },
            ),
          ],
        );
      case MaskLengthMode.randomRange:
        final values = RangeValues(
          _draft.minDelta.toDouble().clamp(-20, 20).toDouble(),
          _draft.maxDelta.toDouble().clamp(-20, 20).toDouble(),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '随机增减：${_draft.minDelta} 到 ${_draft.maxDelta} 个字符',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            RangeSlider(
              values: values,
              min: -20,
              max: 20,
              divisions: 40,
              labels: RangeLabels(
                '${values.start.round()}',
                '${values.end.round()}',
              ),
              onChanged: (range) {
                _updateDraft(
                  _draft.copyWith(
                    minDelta: range.start.round(),
                    maxDelta: range.end.round(),
                  ),
                );
              },
            ),
          ],
        );
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11.5,
          height: 1.35,
        ),
      ),
    );
  }
}
