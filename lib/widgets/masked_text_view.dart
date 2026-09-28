import 'dart:math';

import 'package:flutter/material.dart';

import '../models/mask_range.dart';
import '../models/mask_rule.dart';
import '../theme/workspace_text_style.dart';

class MaskedTextView extends StatefulWidget {
  const MaskedTextView({
    required this.text,
    required this.ranges,
    required this.rule,
    required this.showMasked,
    required this.onAddRange,
    required this.onRemoveRange,
    this.scrollController,
    this.contentPadding = EdgeInsets.zero,
    super.key,
  });

  final String text;
  final List<MaskRange> ranges;
  final MaskRule rule;
  final bool showMasked;
  final ValueChanged<MaskRange> onAddRange;
  final ValueChanged<MaskRange> onRemoveRange;
  final ScrollController? scrollController;
  final EdgeInsets contentPadding;

  @override
  State<MaskedTextView> createState() => _MaskedTextViewState();
}

class _MaskedTextViewState extends State<MaskedTextView> {
  int? _dragAnchor;
  int? _dragCurrent;

  MaskRange? get _dragRange {
    final anchor = _dragAnchor;
    final current = _dragCurrent;
    if (anchor == null || current == null || anchor == current) {
      return null;
    }
    return MaskRange(
      start: min(anchor, current),
      end: max(anchor, current),
      seed: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = workspaceTextStyle(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 800.0;
        final painter = _buildTextPainter(baseStyle, width);
        final viewportHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 0.0;
        final contentHeight = max(
          viewportHeight,
          painter.height + widget.contentPadding.vertical,
        );

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            controller: widget.scrollController,
            padding: EdgeInsets.zero,
            child: MouseRegion(
              cursor: SystemMouseCursors.text,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  if (widget.text.isEmpty) {
                    return;
                  }
                  final offset = _offsetFor(
                    details.localPosition,
                    baseStyle,
                    width,
                  );
                  final existing = _rangeAt(offset);
                  if (existing != null) {
                    widget.onRemoveRange(existing);
                  }
                },
                onPanStart: (details) {
                  if (widget.text.isEmpty) {
                    return;
                  }
                  final offset = _offsetFor(
                    details.localPosition,
                    baseStyle,
                    width,
                  );
                  setState(() {
                    _dragAnchor = offset;
                    _dragCurrent = offset;
                  });
                },
                onPanUpdate: (details) {
                  if (_dragAnchor == null || widget.text.isEmpty) {
                    return;
                  }
                  final offset = _offsetFor(
                    details.localPosition,
                    baseStyle,
                    width,
                  );
                  setState(() => _dragCurrent = offset);
                },
                onPanEnd: (_) {
                  final range = _dragRange;
                  if (range != null) {
                    widget.onAddRange(range);
                  }
                  setState(() {
                    _dragAnchor = null;
                    _dragCurrent = null;
                  });
                },
                onPanCancel: () {
                  setState(() {
                    _dragAnchor = null;
                    _dragCurrent = null;
                  });
                },
                child: SizedBox(
                  width: width,
                  height: contentHeight,
                  child: CustomPaint(
                    painter: _MaskedTextPainter(
                      text: widget.text,
                      ranges: widget.ranges,
                      rule: widget.rule,
                      showMasked: widget.showMasked,
                      selection: _dragRange,
                      style: baseStyle,
                      padding: widget.contentPadding,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  TextPainter _buildTextPainter(TextStyle style, double width) {
    final maxWidth = max(50.0, width - widget.contentPadding.horizontal);
    return TextPainter(
      text: TextSpan(text: widget.text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      strutStyle: workspaceStrutStyle(style),
    )..layout(maxWidth: maxWidth);
  }

  int _offsetFor(Offset position, TextStyle style, double width) {
    final painter = _buildTextPainter(style, width);
    final maxWidth = max(50.0, width - widget.contentPadding.horizontal);
    final local = Offset(
      (position.dx - widget.contentPadding.left)
          .clamp(0.0, maxWidth)
          .toDouble(),
      (position.dy - widget.contentPadding.top)
          .clamp(0.0, max(0.0, painter.height))
          .toDouble(),
    );
    return painter.getPositionForOffset(local).offset;
  }

  MaskRange? _rangeAt(int offset) {
    for (final range in widget.ranges) {
      if (range.contains(offset)) {
        return range;
      }
    }
    return null;
  }
}

class _MaskedTextPainter extends CustomPainter {
  const _MaskedTextPainter({
    required this.text,
    required this.ranges,
    required this.rule,
    required this.showMasked,
    required this.selection,
    required this.style,
    required this.padding,
  });

  final String text;
  final List<MaskRange> ranges;
  final MaskRule rule;
  final bool showMasked;
  final MaskRange? selection;
  final TextStyle style;
  final EdgeInsets padding;

  @override
  void paint(Canvas canvas, Size size) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      strutStyle: workspaceStrutStyle(style),
    )..layout(maxWidth: max(50.0, size.width - padding.horizontal));

    canvas.save();
    canvas.translate(padding.left, padding.top);
    painter.paint(canvas, Offset.zero);

    if (showMasked) {
      for (final range in ranges) {
        _paintMaskRange(canvas, painter, range);
      }
    }

    final activeSelection = selection;
    if (activeSelection != null) {
      _paintSelection(canvas, painter, activeSelection);
    }

    canvas.restore();
  }

  void _paintMaskRange(
    Canvas canvas,
    TextPainter sourcePainter,
    MaskRange range,
  ) {
    if (range.start >= text.length) {
      return;
    }

    final selection = TextSelection(
      baseOffset: range.start,
      extentOffset: min(range.end, text.length),
    );
    final boxes = sourcePainter.getBoxesForSelection(selection);
    final backgroundPaint = Paint()
      ..color = Color(rule.backgroundColor.value)
      ..style = PaintingStyle.fill;

    for (final box in boxes) {
      final rect = Rect.fromLTRB(
        box.left,
        box.top,
        box.right,
        box.bottom,
      ).inflate(0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        backgroundPaint,
      );

      if (rule.visualStyle == MaskVisualStyle.glyph) {
        _paintGlyph(canvas, rect, range);
      }
    }
  }

  void _paintGlyph(Canvas canvas, Rect rect, MaskRange range) {
    if (rect.width <= 0 || rect.height <= 0) {
      return;
    }

    final tokenStyle = style.copyWith(
      color: Color(rule.foregroundColor.value),
      fontWeight: FontWeight.w600,
      height: 1,
    );
    final tokenPainter = TextPainter(
      text: TextSpan(text: rule.previewToken, style: tokenStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final tokenWidth = max(1.0, tokenPainter.width);
    final count = max(1, (rect.width / tokenWidth).ceil());
    final label = rule.lengthMode == MaskLengthMode.fixed
        ? rule.fixedText
        : List.filled(count, rule.previewToken).join();
    final labelPainter = TextPainter(
      text: TextSpan(text: label, style: tokenStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: rule.lengthMode == MaskLengthMode.fixed ? '…' : '',
    )..layout(maxWidth: rect.width);
    final y = rect.top + max(0.0, (rect.height - labelPainter.height) / 2);

    canvas.save();
    canvas.clipRect(rect);
    labelPainter.paint(canvas, Offset(rect.left, y));
    canvas.restore();
  }

  void _paintSelection(
    Canvas canvas,
    TextPainter sourcePainter,
    MaskRange range,
  ) {
    if (range.start >= text.length) {
      return;
    }

    final boxes = sourcePainter.getBoxesForSelection(
      TextSelection(
        baseOffset: range.start,
        extentOffset: min(range.end, text.length),
      ),
    );
    final fill = Paint()..color = const Color(0x554D8BD1);
    final border = Paint()
      ..color = const Color(0xFF76A9EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final box in boxes) {
      final rect = Rect.fromLTRB(box.left, box.top, box.right, box.bottom);
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect.deflate(0.5), border);
    }
  }

  @override
  bool shouldRepaint(_MaskedTextPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.ranges != ranges ||
        oldDelegate.rule != rule ||
        oldDelegate.showMasked != showMasked ||
        oldDelegate.selection != selection ||
        oldDelegate.style != style;
  }
}
