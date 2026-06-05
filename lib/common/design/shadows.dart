import 'package:flutter/material.dart';

/// PiliNext shadow system.
///
/// Subtle, layered shadows designed to complement glassmorphism.
/// Dark mode shadows use higher opacity (no ambient light to soften edges).
abstract final class AppShadows {
  AppShadows._();

  /// No shadow — content elements, text
  static const List<BoxShadow> level0 = [];

  /// Level 1 — subtle elevation: cards resting on surface
  static const List<BoxShadow> level1Light = [
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 3,
      color: Color(0x0A000000),
    ),
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 2,
      color: Color(0x0F000000),
    ),
  ];

  /// Level 2 — moderate elevation: floating elements, FAB
  static const List<BoxShadow> level2Light = [
    BoxShadow(
      offset: Offset(0, 4),
      blurRadius: 8,
      color: Color(0x0A000000),
    ),
    BoxShadow(
      offset: Offset(0, 2),
      blurRadius: 4,
      color: Color(0x0F000000),
    ),
  ];

  /// Level 3 — high elevation: sheets, panels, navigation bar
  static const List<BoxShadow> level3Light = [
    BoxShadow(
      offset: Offset(0, 8),
      blurRadius: 24,
      color: Color(0x0F000000),
    ),
    BoxShadow(
      offset: Offset(0, 4),
      blurRadius: 8,
      color: Color(0x0A000000),
    ),
  ];

  /// Level 4 — maximum elevation: modals, dialogs
  static const List<BoxShadow> level4Light = [
    BoxShadow(
      offset: Offset(0, 16),
      blurRadius: 48,
      color: Color(0x14000000),
    ),
    BoxShadow(
      offset: Offset(0, 8),
      blurRadius: 16,
      color: Color(0x0A000000),
    ),
  ];

  // ── Dark mode variants (higher opacity) ──────────────────────

  static const List<BoxShadow> level1Dark = [
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 3,
      color: Color(0x1A000000),
    ),
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 2,
      color: Color(0x1F000000),
    ),
  ];

  static const List<BoxShadow> level2Dark = [
    BoxShadow(
      offset: Offset(0, 4),
      blurRadius: 8,
      color: Color(0x1A000000),
    ),
    BoxShadow(
      offset: Offset(0, 2),
      blurRadius: 4,
      color: Color(0x1F000000),
    ),
  ];

  static const List<BoxShadow> level3Dark = [
    BoxShadow(
      offset: Offset(0, 8),
      blurRadius: 24,
      color: Color(0x26000000),
    ),
    BoxShadow(
      offset: Offset(0, 4),
      blurRadius: 8,
      color: Color(0x1A000000),
    ),
  ];

  static const List<BoxShadow> level4Dark = [
    BoxShadow(
      offset: Offset(0, 16),
      blurRadius: 48,
      color: Color(0x33000000),
    ),
    BoxShadow(
      offset: Offset(0, 8),
      blurRadius: 16,
      color: Color(0x1A000000),
    ),
  ];

  /// Returns shadows for the given [level] and [brightness].
  static List<BoxShadow> of(int level, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch ((level, isDark)) {
      (0, _) => level0,
      (1, false) => level1Light,
      (2, false) => level2Light,
      (3, false) => level3Light,
      (4, false) => level4Light,
      (1, true) => level1Dark,
      (2, true) => level2Dark,
      (3, true) => level3Dark,
      (4, true) => level4Dark,
      _ => level0,
    };
  }
}
