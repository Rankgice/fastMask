import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF76A9EA);
  static const canvas = Color(0xFF202124);
  static const surface = Color(0xFF24262A);
  static const surfaceSubtle = Color(0xFF2A2D31);
  static const editorSurface = Color(0xFF202124);
  static const editorGutter = Color(0xFF24262A);
  static const border = Color(0xFF383B40);
  static const borderStrong = Color(0xFF4A4E55);
  static const textPrimary = Color(0xFFD7D9DD);
  static const textSecondary = Color(0xFFA2A7AF);
  static const textMuted = Color(0xFF747A83);
  static const primarySoft = Color(0xFF2D3947);
  static const hoverSurface = Color(0xFF303338);
  static const selectedSurface = Color(0xFF3A3D42);
  static const warning = Color(0xFFE0A464);
  static const editorText = Color(0xFFD7A978);
  static const selectionFill = Color(0x554D8BD1);
  static const selectionBorder = Color(0xFF76A9EA);
  static const error = Color(0xFFE06C75);
}

ThemeData buildFastMaskTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.primary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
        error: AppColors.error,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    visualDensity: VisualDensity.compact,
    scaffoldBackgroundColor: AppColors.canvas,
    splashFactory: InkSparkle.splashFactory,
  );

  const inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(5)),
    borderSide: BorderSide(color: AppColors.borderStrong),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    iconTheme: const IconThemeData(color: AppColors.textSecondary),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.canvas,
      surfaceTintColor: AppColors.canvas,
      foregroundColor: AppColors.textPrimary,
      toolbarHeight: 48,
      titleSpacing: 12,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceSubtle,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
      labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      floatingLabelStyle: TextStyle(color: AppColors.primary, fontSize: 12),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
        borderSide: BorderSide(color: AppColors.primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
        borderSide: BorderSide(color: AppColors.error),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
        ),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        foregroundColor: const WidgetStatePropertyAll(AppColors.textPrimary),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.borderStrong),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
        ),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 30)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        foregroundColor: const WidgetStatePropertyAll(AppColors.textPrimary),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
        ),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 30)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.selectedSurface
              : AppColors.surface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.textPrimary
              : AppColors.textSecondary;
        }),
        overlayColor: const WidgetStatePropertyAll(AppColors.hoverSurface),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.borderStrong),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
        ),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      side: const BorderSide(color: AppColors.borderStrong),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.surface),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: AppColors.selectedSurface,
      selectedIconTheme: IconThemeData(color: AppColors.textPrimary, size: 18),
      unselectedIconTheme: IconThemeData(
        color: AppColors.textSecondary,
        size: 18,
      ),
      selectedLabelTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
      ),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.borderStrong,
      thumbColor: AppColors.primary,
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceSubtle,
      contentTextStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      insetPadding: const EdgeInsets.all(12),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(7),
      radius: const Radius.circular(7),
      thumbColor: WidgetStatePropertyAll(
        AppColors.textMuted.withValues(alpha: 0.75),
      ),
      trackColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
  );
}
