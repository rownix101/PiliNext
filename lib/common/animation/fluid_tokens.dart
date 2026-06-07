import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// PiliNext Fluid Animation System — semantic motion tokens.
///
/// Motion is intentionally split by purpose instead of by raw duration:
/// utility interactions stay quiet, navigation gets directional structure,
/// and expressive spring motion is reserved for signature moments.
abstract final class FluidTokens {
  FluidTokens._();

  // ═══════════════════════════════════════════════════════════════
  // Duration tokens
  // ═══════════════════════════════════════════════════════════════

  /// 80ms — immediate press/release feedback.
  static const Duration durationInstant = Duration(milliseconds: 80);

  /// 120ms — icon toggles, hover/focus, tiny affordances.
  static const Duration durationXs = Duration(milliseconds: 120);

  /// 160ms — small utility transitions.
  static const Duration durationSm = Duration(milliseconds: 160);

  /// 220ms — default content/control motion.
  static const Duration durationMd = Duration(milliseconds: 220);

  /// 300ms — panels, sheets, navigation indicators.
  static const Duration durationLg = Duration(milliseconds: 300);

  /// 380ms — heavier transitions such as fullscreen/player state changes.
  static const Duration durationXl = Duration(milliseconds: 380);

  /// 500ms — full page transitions, launch/landing animations.
  static const Duration durationXxl = Duration(milliseconds: 500);

  /// 1000ms — deliberate slow reveals, skeleton shimmer cycles.
  static const Duration durationSlow = Duration(milliseconds: 1000);

  /// Reduced-motion fallback duration: short enough to avoid spatial motion,
  /// long enough that state changes do not feel like visual glitches.
  static const Duration durationReduced = Duration(milliseconds: 80);

  // ═══════════════════════════════════════════════════════════════
  // Curves
  // ═══════════════════════════════════════════════════════════════

  static const Curve curveEnter = Curves.easeOutCubic;
  static const Curve curveExit = Curves.easeInCubic;
  static const Curve curveStandard = Curves.easeInOutCubic;
  static const Curve curveEmphasized = Curves.easeInOutCubicEmphasized;

  // ═══════════════════════════════════════════════════════════════
  // Spring presets
  // ═══════════════════════════════════════════════════════════════

  /// Fast and tactile. Use for button press feedback and tiny toggles.
  static const SpringDescription springSnappy = SpringDescription(
    mass: 0.75,
    stiffness: 520,
    damping: 34,
  );

  /// Smooth, modern, low-overshoot movement. Use for content and navigation.
  static const SpringDescription springSmooth = SpringDescription(
    mass: 1.0,
    stiffness: 360,
    damping: 34,
  );

  /// Liquid but controlled. Use for panels and directional transitions.
  static const SpringDescription springFluid = SpringDescription(
    mass: 1.0,
    stiffness: 300,
    damping: 27,
  );

  /// Expressive signature motion. Use sparingly for nav pill / delight moments.
  static const SpringDescription springExpressive = SpringDescription(
    mass: 1.0,
    stiffness: 260,
    damping: 22,
  );

  /// Heavy state transitions, almost no bounce.
  static const SpringDescription springHeavy = SpringDescription(
    mass: 1.25,
    stiffness: 240,
    damping: 36,
  );

  /// Quiet fade/list-item motion.
  static const SpringDescription springGentle = SpringDescription(
    mass: 0.8,
    stiffness: 420,
    damping: 38,
  );

  /// Backwards-compatible alias for older code.
  static const SpringDescription springJelly = springExpressive;

  /// Backwards-compatible alias for older code.
  static const SpringDescription iconBounceSpring = springSnappy;

  // ═══════════════════════════════════════════════════════════════
  // Distances and scale values
  // ═══════════════════════════════════════════════════════════════

  static const double pressScale = 0.96;
  static const double contentEnterDy = 8;
  static const double navigationDx = 16;
  static const double panelEnterDy = 16;
  static const double controlBarDy = 12;

  // ═══════════════════════════════════════════════════════════════
  // Reduced motion
  // ═══════════════════════════════════════════════════════════════

  /// Whether motion should be reduced for this build context.
  static bool reduceMotionOf(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) return false;
    return mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
  }

  /// Returns [Duration.zero] for full reduction or a short fallback duration
  /// for state transitions that still need visual continuity.
  static Duration effectiveDuration(
    BuildContext context,
    Duration duration, {
    bool keepShortFade = true,
  }) {
    if (!reduceMotionOf(context)) return duration;
    return keepShortFade ? durationReduced : Duration.zero;
  }

  // ═══════════════════════════════════════════════════════════════
  // Utility: SpringSimulation from preset + velocity
  // ═══════════════════════════════════════════════════════════════

  static SpringSimulation simulation({
    required SpringDescription spring,
    required double from,
    required double to,
    double velocity = 0,
  }) {
    return SpringSimulation(spring, from, to, velocity);
  }

  /// Creates a [SpringDescription] with damping trade-off.
  /// Lower [quality] = more expressive; higher = more settled.
  static SpringDescription withQuality(
    SpringDescription base,
    double quality,
  ) {
    return SpringDescription(
      mass: base.mass,
      stiffness: base.stiffness,
      damping: base.damping * quality,
    );
  }
}
