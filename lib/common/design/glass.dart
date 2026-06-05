import 'package:flutter/material.dart';

/// PiliNext glassmorphism depth levels.
///
/// Each level defines blur intensity, background opacity,
/// border treatment, and highlight gradient for glass surfaces.
///
/// Performance: BackdropFilter blur is hardware-accelerated on
/// all target devices (Adreno 6xx+, Apple A14+, desktop GPUs).
/// Tier 2 devices cap at 20px blur; no blur-less fallback exists
/// because all 2023+ devices support it.
abstract final class GlassTokens {
  GlassTokens._();

  // ── Blur values ──────────────────────────────────────────────

  /// Level 1 — Floating (navigation bar, search bar)
  static const double blurFloating = 12;
  static const double opacityFloating = 0.80;

  /// Level 2 — Panel (bottom sheets, player controls)
  static const double blurPanel = 20;
  static const double opacityPanel = 0.85;

  /// Level 3 — Overlay (modals, full-screen viewers)
  static const double blurOverlay = 30;
  static const double opacityOverlay = 0.90;

  // ── Blur cap for Tier 2 devices ──────────────────────────────

  static const double blurCapTier2 = 20;

  // ── Border ───────────────────────────────────────────────────

  /// All glass surfaces share this border treatment.
  /// 1px outlineVariant at 8% opacity simulates glass edge refraction.
  static BorderSide borderLight(Color outlineVariant) {
    return BorderSide(
      color: outlineVariant.withValues(alpha: 0.08),
      width: 1,
    );
  }

  static BorderSide borderDark(Color outlineVariant) {
    return BorderSide(
      color: outlineVariant.withValues(alpha: 0.12),
      width: 1,
    );
  }

  // ── Highlight gradient (top light reflection) ──────────────────

  /// Subtle white gradient at the top of glass surfaces
  /// to simulate ambient light reflection on glass.
  static LinearGradient highlightGradient(Brightness brightness) {
    final stop = brightness == Brightness.light ? 0.02 : 0.03;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: stop),
        Colors.white.withValues(alpha: 0.0),
      ],
    );
  }

  // ── BackdropFilter wrapper ────────────────────────────────────

  /// Creates a [BackdropFilter] with the given blur [sigma].
  /// Use for glass backgrounds.
  static BackdropFilter blurFilter({
    required double sigma,
    required Widget child,
    Key? key,
  }) {
    return BackdropFilter(
      key: key,
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }
}
