import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// PiliNext Fluid Animation System — Duration and Spring tokens.
///
/// Design philosophy:
/// - All animations are spring-based. No ease-in-out, no linear.
/// - Springs inherit velocity from gestures (velocity-aware).
/// - Duration tokens are for spring target hints, not fixed-duration curves.
/// - Every spring preset has a distinct "feel" matched to its use case.
///
/// Usage:
/// ```dart
/// // Instead of:
/// // AnimatedOpacity(duration: Duration(milliseconds: 300), curve: Curves.easeInOut, ...)
/// // Use:
/// // FluidTransition(opacity: 1.0, preset: FluidTokens.fadeIn, child: ...)
/// ```
abstract final class FluidTokens {
  FluidTokens._();

  // ═══════════════════════════════════════════════════════════════
  // Level 1: Duration Tokens
  // ═══════════════════════════════════════════════════════════════

  /// 100ms — Micro-interactions: ripple, icon state toggle, hover
  static const Duration durationXs = Duration(milliseconds: 100);

  /// 150ms — Small transitions: tooltips, tag switches, badge appear
  static const Duration durationSm = Duration(milliseconds: 150);

  /// 200ms — Medium transitions: control bar show/hide, FAB, chips
  static const Duration durationMd = Duration(milliseconds: 200);

  /// 300ms — Large transitions: page routes, bottom sheets, modals
  static const Duration durationLg = Duration(milliseconds: 300);

  /// 500ms — Heavy transitions: nav bar indicator, fullscreen enter/exit
  static const Duration durationXl = Duration(milliseconds: 500);

  // ═══════════════════════════════════════════════════════════════
  // Level 2: Spring Presets
  // ═══════════════════════════════════════════════════════════════

  /// Light, fast, with subtle bounce.
  /// Use: button feedback, switch toggle, micro-interactions.
  /// Feel: snappy click with a hint of liveliness.
  static final SpringDescription springSnappy = const SpringDescription(
    mass: 0.8,
    stiffness: 600,
    damping: 0.85,
  );

  /// Liquid flow, visible overshoot.
  /// Use: page transitions, panel slide-in, modal present.
  /// Feel: water-like flow with clear elastic overshoot.
  static final SpringDescription springFluid = const SpringDescription(
    mass: 1.0,
    stiffness: 350,
    damping: 0.75,
  );

  /// Jelly stretch-squish, high elasticity, long settle.
  /// Use: nav bar indicator, like burst, notification arrival.
  /// Feel: pudding-like with dramatic stretch and wobble.
  static final SpringDescription springJelly = const SpringDescription(
    mass: 1.2,
    stiffness: 250,
    damping: 0.65,
  );

  /// Heavy weight, slow but forceful, almost no bounce.
  /// Use: fullscreen enter/exit, heavy page transitions.
  /// Feel: massive object moving with authority.
  static final SpringDescription springHeavy = const SpringDescription(
    mass: 1.5,
    stiffness: 200,
    damping: 0.9,
  );

  /// Gentle, critically-damped, no bounce. Does not disturb.
  /// Use: fade in/out, list item appear, image load complete.
  /// Feel: whisper-quiet, barely noticeable.
  static final SpringDescription springGentle = const SpringDescription(
    mass: 0.5,
    stiffness: 500,
    damping: 1.0,
  );

  // ═══════════════════════════════════════════════════════════════
  // Level 3: Combo Presets (opacity + transform bundles)
  // ═══════════════════════════════════════════════════════════════

  /// Fade in: opacity 0→1, gentle spring
  static const _FadePreset fadeIn = _FadePreset(
    opacityBegin: 0.0,
    opacityEnd: 1.0,
    duration: durationMd,
    spring: springGentle,
  );

  /// Fade out: opacity 1→0, gentle spring
  static const _FadePreset fadeOut = _FadePreset(
    opacityBegin: 1.0,
    opacityEnd: 0.0,
    duration: durationSm,
    spring: springGentle,
  );

  /// Slide up + fade in: translateY(20→0), fluid spring
  static const _SlidePreset slideUp = _SlidePreset(
    offsetBegin: Offset(0, 20),
    offsetEnd: Offset.zero,
    duration: durationLg,
    spring: springFluid,
    fadeIn: true,
  );

  /// Slide down + fade out: translateY(0→20), fluid spring
  static const _SlidePreset slideDown = _SlidePreset(
    offsetBegin: Offset.zero,
    offsetEnd: Offset(0, 20),
    duration: durationMd,
    spring: springFluid,
    fadeOut: true,
  );

  /// Pop in: scale(0.85→1.05→1) + fade in, jelly spring
  static const _ScalePreset popIn = _ScalePreset(
    scaleBegin: 0.85,
    scaleEnd: 1.0,
    duration: durationMd,
    spring: springJelly,
    fadeIn: true,
  );

  /// Pop out: scale(1→0.9) + fade out, fluid spring
  static const _ScalePreset popOut = _ScalePreset(
    scaleBegin: 1.0,
    scaleEnd: 0.9,
    duration: durationSm,
    spring: springFluid,
    fadeOut: true,
  );

  /// Icon bounce: scale(1→1.3→0.9→1), jelly spring
  /// Use for like/bookmark/button press feedback
  static final SpringDescription iconBounceSpring = springJelly;

  // ═══════════════════════════════════════════════════════════════
  // Utility: SpringSimulation from preset + velocity
  // ═══════════════════════════════════════════════════════════════

  /// Creates a [SpringSimulation] from a preset, initial position,
  /// target position, and optional initial velocity.
  static SpringSimulation simulation({
    required SpringDescription spring,
    required double from,
    required double to,
    double velocity = 0,
  }) {
    return SpringSimulation(spring, from, to, velocity);
  }

  /// Creates a [SpringDescription] with quality/damping trade-off.
  /// Lower [quality] = more bouncy; higher = more settled.
  /// Default quality is 1.0 (standard response).
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

// ═════════════════════════════════════════════════════════════════
// Preset value types
// ═════════════════════════════════════════════════════════════════

class _FadePreset {
  final double opacityBegin;
  final double opacityEnd;
  final Duration duration;
  final SpringDescription spring;

  const _FadePreset({
    required this.opacityBegin,
    required this.opacityEnd,
    required this.duration,
    required this.spring,
  });
}

class _SlidePreset {
  final Offset offsetBegin;
  final Offset offsetEnd;
  final Duration duration;
  final SpringDescription spring;
  final bool fadeIn;
  final bool fadeOut;

  const _SlidePreset({
    required this.offsetBegin,
    required this.offsetEnd,
    required this.duration,
    required this.spring,
    this.fadeIn = false,
    this.fadeOut = false,
  });
}

class _ScalePreset {
  final double scaleBegin;
  final double scaleEnd;
  final Duration duration;
  final SpringDescription spring;
  final bool fadeIn;
  final bool fadeOut;

  const _ScalePreset({
    required this.scaleBegin,
    required this.scaleEnd,
    required this.duration,
    required this.spring,
    this.fadeIn = false,
    this.fadeOut = false,
  });
}
