import 'package:PiliNext/utils/storage_pref.dart';
import 'package:flutter/services.dart' show HapticFeedback;

/// Haptic feedback levels matching Material 3 Expressive patterns.
///
/// * [light] — subtle press feedback (buttons, tabs, toggles)
/// * [medium] — confirmation feedback (delete, save, actions)
/// * [heavy] — significant state changes (lock, power, reset)
/// * [selection] — selection / tick feedback (date picker, slider detents)
/// * [none] — bypass haptic entirely (used for silent interactions)
enum HapticLevel {
  none,
  light,
  medium,
  heavy,
  selection,
}

/// Central haptic service wrapping [HapticFeedback].
///
/// Respects the user's `feedBackEnable` preference from [Pref].
/// All haptic calls are gated behind this toggle.
abstract final class HapticService {
  HapticService._();

  /// Whether haptic feedback is currently enabled.
  static bool get enabled => Pref.feedBackEnable;

  /// Play haptic at the given [level]. Silently ignored if disabled.
  static void play(HapticLevel level) {
    if (!enabled) return;
    switch (level) {
      case HapticLevel.none:
        break;
      case HapticLevel.light:
        HapticFeedback.lightImpact();
      case HapticLevel.medium:
        HapticFeedback.mediumImpact();
      case HapticLevel.heavy:
        HapticFeedback.heavyImpact();
      case HapticLevel.selection:
        HapticFeedback.selectionClick();
    }
  }

  /// Legacy alias — equivalent to [play](HapticLevel.light).
  /// Maintained for backward compatibility with `feedBack()` call sites.
  static void light() => play(HapticLevel.light);

  /// Convenience: tap / press interaction.
  static void tap() => play(HapticLevel.light);

  /// Convenience: confirmed action (like, save, delete).
  static void confirm() => play(HapticLevel.medium);

  /// Convenience: major state change.
  static void major() => play(HapticLevel.heavy);

  /// Convenience: selection tick (date/time picker).
  static void tick() => play(HapticLevel.selection);
}
