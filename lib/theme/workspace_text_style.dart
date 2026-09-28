import 'package:flutter/material.dart';

import 'app_theme.dart';

const workspaceTextPadding = EdgeInsets.fromLTRB(12, 8, 12, 8);

TextStyle workspaceTextStyle(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.bodyMedium!.copyWith(
    height: 1.65,
    fontSize: 14,
    letterSpacing: 0.05,
    color: AppColors.editorText,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

StrutStyle workspaceStrutStyle(TextStyle style) {
  return StrutStyle.fromTextStyle(style, forceStrutHeight: true);
}
