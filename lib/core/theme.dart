import 'package:flutter/material.dart';

/// Дизайн-система: плоский «спортивный» стиль, тёмная тема основная.
/// Один акцент — оранжевый; выполненное и главное действие.
abstract final class AppColors {
  static const accent = Color(0xFFFF6B2C);
  static const onAccent = Color(0xFF1A0A00);

  /// Тот же оранжевый темнее: на светлом фоне яркий не даёт контраста 4.5:1.
  static const accentOnLight = Color(0xFFC2410C);
}

/// Числа (вес, повторы, таймер) — табличные цифры, чтобы не прыгали при вводе.
const tabularFigures = [FontFeature.tabularFigures()];

final darkTheme = _theme(
  const ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    secondary: AppColors.accent,
    onSecondary: AppColors.onAccent,
    secondaryContainer: Color(0xFF3D2418),
    onSecondaryContainer: Color(0xFFFFC2A6),
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF2A0000),
    surface: Color(0xFF0F0F10),
    onSurface: Color(0xFFF2F2F0),
    onSurfaceVariant: Color(0xFFA8A8A6),
    surfaceContainerLow: Color(0xFF151517),
    surfaceContainer: Color(0xFF1A1A1C),
    surfaceContainerHigh: Color(0xFF242427),
    surfaceContainerHighest: Color(0xFF2E2E32),
    outline: Color(0xFF45454A),
    outlineVariant: Color(0xFF2E2E32),
  ),
);

final lightTheme = _theme(
  const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.accentOnLight,
    onPrimary: Colors.white,
    secondary: AppColors.accentOnLight,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFFFE2D4),
    onSecondaryContainer: Color(0xFF5C2200),
    error: Color(0xFFC62828),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Color(0xFF141414),
    onSurfaceVariant: Color(0xFF5C5C5C),
    surfaceContainerLow: Color(0xFFF8F8F6),
    surfaceContainer: Color(0xFFF2F2EF),
    surfaceContainerHigh: Color(0xFFE8E8E4),
    surfaceContainerHighest: Color(0xFFDCDCD7),
    outline: Color(0xFFBDBDB7),
    outlineVariant: Color(0xFFDCDCD7),
  ),
);

ThemeData _theme(ColorScheme scheme) {
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final text = base.textTheme;
  const radius = BorderRadius.all(Radius.circular(14));
  const buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      labelSmall: text.labelSmall?.copyWith(
        fontSize: 11,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      // Размер задан явно: размеры textTheme подмешиваются позже, в Theme.
      titleTextStyle: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainer,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: const RoundedRectangleBorder(borderRadius: radius),
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: const RoundedRectangleBorder(borderRadius: radius),
        side: BorderSide(color: scheme.outline),
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      side: BorderSide(color: scheme.outline, width: 2),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primary.withValues(alpha: 0.18),
      elevation: 0,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primary.withValues(alpha: 0.18),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide(color: scheme.outlineVariant),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
