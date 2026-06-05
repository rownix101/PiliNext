import 'package:flutter/material.dart';

/// PiliNext desaturated color palette.
///
/// All colors keep chroma/saturation ≤ 15% (except brand accent).
/// No color exceeds 30% saturation in the UI.
///
/// Design principle: "high-end perfume bottle" colors —
/// muted, elegant, with subtle warmth.
abstract final class AppColors {
  AppColors._();

  // ── Light Theme ──────────────────────────────────────────────

  static const Color lightSurface = Color(0xFFF8F7F4);
  static const Color lightSurfaceContainer = Color(0xFFF0EEE9);
  static const Color lightSurfaceContainerHigh = Color(0xFFE8E5DF);
  static const Color lightSurfaceContainerHighest = Color(0xFFE0DDD6);

  static const Color lightPrimary = Color(0xFF5B6E7A);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFDFE6ED);
  static const Color lightOnPrimaryContainer = Color(0xFF17242D);

  static const Color lightSecondary = Color(0xFF8B7E74);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightSecondaryContainer = Color(0xFFF3E8DD);
  static const Color lightOnSecondaryContainer = Color(0xFF2D221A);

  static const Color lightTertiary = Color(0xFF6B8B7A);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightTertiaryContainer = Color(0xFFE0F5E8);
  static const Color lightOnTertiaryContainer = Color(0xFF0F2419);

  static const Color lightError = Color(0xFFC4726F);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFFFE5E4);
  static const Color lightOnErrorContainer = Color(0xFF3B1211);

  static const Color lightOutline = Color(0xFFD6D3CD);
  static const Color lightOutlineVariant = Color(0xFFE8E5DF);

  static const Color lightShadow = Color(0x0A000000);

  // ── Dark Theme ───────────────────────────────────────────────

  static const Color darkSurface = Color(0xFF1A1B1E);
  static const Color darkSurfaceContainer = Color(0xFF232528);
  static const Color darkSurfaceContainerHigh = Color(0xFF2D2F33);
  static const Color darkSurfaceContainerHighest = Color(0xFF37393E);

  static const Color darkPrimary = Color(0xFF8DA3B2);
  static const Color darkOnPrimary = Color(0xFF1A1B1E);
  static const Color darkPrimaryContainer = Color(0xFF3E515D);
  static const Color darkOnPrimaryContainer = Color(0xFFDFE6ED);

  static const Color darkSecondary = Color(0xFFB5A89C);
  static const Color darkOnSecondary = Color(0xFF2D221A);
  static const Color darkSecondaryContainer = Color(0xFF55473C);
  static const Color darkOnSecondaryContainer = Color(0xFFF3E8DD);

  static const Color darkTertiary = Color(0xFF8BA89A);
  static const Color darkOnTertiary = Color(0xFF0F2419);
  static const Color darkTertiaryContainer = Color(0xFF3E5C4C);
  static const Color darkOnTertiaryContainer = Color(0xFFE0F5E8);

  static const Color darkError = Color(0xFFD4908D);
  static const Color darkOnError = Color(0xFF3B1211);
  static const Color darkErrorContainer = Color(0xFF6E302E);
  static const Color darkOnErrorContainer = Color(0xFFFFE5E4);

  static const Color darkOutline = Color(0xFF3A3C40);
  static const Color darkOutlineVariant = Color(0xFF2A2C30);

  static const Color darkShadow = Color(0x1A000000);

  // ── ColorScheme factory ──────────────────────────────────────

  static ColorScheme lightColorScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: lightPrimary,
      onPrimary: lightOnPrimary,
      primaryContainer: lightPrimaryContainer,
      onPrimaryContainer: lightOnPrimaryContainer,
      secondary: lightSecondary,
      onSecondary: lightOnSecondary,
      secondaryContainer: lightSecondaryContainer,
      onSecondaryContainer: lightOnSecondaryContainer,
      tertiary: lightTertiary,
      onTertiary: lightOnTertiary,
      tertiaryContainer: lightTertiaryContainer,
      onTertiaryContainer: lightOnTertiaryContainer,
      error: lightError,
      onError: lightOnError,
      errorContainer: lightErrorContainer,
      onErrorContainer: lightOnErrorContainer,
      surface: lightSurface,
      onSurface: Color(0xFF1A1B1E),
      surfaceContainerHighest: lightSurfaceContainerHighest,
      onSurfaceVariant: Color(0xFF44474A),
      outline: lightOutline,
      outlineVariant: lightOutlineVariant,
      shadow: lightShadow,
      scrim: Color(0x33000000),
      inverseSurface: Color(0xFF2D2F33),
      onInverseSurface: Color(0xFFF0EEE9),
      inversePrimary: Color(0xFF8DA3B2),
    );
  }

  static ColorScheme darkColorScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: darkPrimary,
      onPrimary: darkOnPrimary,
      primaryContainer: darkPrimaryContainer,
      onPrimaryContainer: darkOnPrimaryContainer,
      secondary: darkSecondary,
      onSecondary: darkOnSecondary,
      secondaryContainer: darkSecondaryContainer,
      onSecondaryContainer: darkOnSecondaryContainer,
      tertiary: darkTertiary,
      onTertiary: darkOnTertiary,
      tertiaryContainer: darkTertiaryContainer,
      onTertiaryContainer: darkOnTertiaryContainer,
      error: darkError,
      onError: darkOnError,
      errorContainer: darkErrorContainer,
      onErrorContainer: darkOnErrorContainer,
      surface: darkSurface,
      onSurface: Color(0xFFE0DDD6),
      surfaceContainerHighest: darkSurfaceContainerHighest,
      onSurfaceVariant: Color(0xFFC0BCB5),
      outline: darkOutline,
      outlineVariant: darkOutlineVariant,
      shadow: darkShadow,
      scrim: Color(0x4D000000),
      inverseSurface: Color(0xFFE0DDD6),
      onInverseSurface: Color(0xFF1A1B1E),
      inversePrimary: Color(0xFF5B6E7A),
    );
  }
}
