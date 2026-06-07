import 'package:PiliNext/common/design/design_tokens.dart';
import 'package:flutter/material.dart';

/// Liquid Glass surface — a reusable glassmorphism container.
///
/// Supports three depth levels: [GlassSurfaceLevel.floating] (nav bar),
/// [GlassSurfaceLevel.panel] (sheets, controls), and
/// [GlassSurfaceLevel.overlay] (modals, full-screen overlays).
///
/// Automatically adapts blur, opacity, and border to the ambient
/// [Brightness] from the nearest [Theme].
enum GlassSurfaceLevel {
  floating,
  panel,
  overlay,
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.level = GlassSurfaceLevel.floating,
    this.borderRadius,
    this.shadowLevel,
    this.showHighlight = true,
    this.clipBehavior = Clip.antiAlias,
    this.padding,
    this.margin,
  });

  final Widget child;
  final GlassSurfaceLevel level;
  final BorderRadius? borderRadius;
  final int? shadowLevel;
  final bool showHighlight;
  final Clip clipBehavior;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;

    final (blur, opacity) = _valuesForLevel(level);

    final effectiveRadius = borderRadius ??
        switch (level) {
          GlassSurfaceLevel.panel => const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          GlassSurfaceLevel.overlay => BorderRadius.circular(16),
          _ => null,
        };

    final shadows = shadowLevel != null
        ? AppShadows.of(shadowLevel!, brightness)
        : switch (level) {
            GlassSurfaceLevel.floating => AppShadows.of(3, brightness),
            GlassSurfaceLevel.panel => AppShadows.of(3, brightness),
            GlassSurfaceLevel.overlay => AppShadows.of(4, brightness),
          };

    Widget surface = GlassTokens.blurFilter(
      sigma: blur,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: opacity),
              borderRadius: effectiveRadius,
              border: Border.fromBorderSide(
                isDark
                    ? GlassTokens.borderDark(colorScheme.outlineVariant)
                    : GlassTokens.borderLight(colorScheme.outlineVariant),
              ),
              boxShadow: shadows,
            ),
          ),
          if (showHighlight && effectiveRadius != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: effectiveRadius,
                    gradient: GlassTokens.highlightGradient(brightness),
                  ),
                ),
              ),
            ),
          Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ],
      ),
    );

    if (effectiveRadius != null) {
      surface = ClipRRect(
        borderRadius: effectiveRadius,
        clipBehavior: clipBehavior,
        child: surface,
      );
    }

    if (margin != null) {
      surface = Padding(padding: margin!, child: surface);
    }

    return surface;
  }

  (double blur, double opacity) _valuesForLevel(GlassSurfaceLevel level) {
    return switch (level) {
      GlassSurfaceLevel.floating => (
          GlassTokens.blurFloating,
          GlassTokens.opacityFloating,
        ),
      GlassSurfaceLevel.panel => (
          GlassTokens.blurPanel,
          GlassTokens.opacityPanel,
        ),
      GlassSurfaceLevel.overlay => (
          GlassTokens.blurOverlay,
          GlassTokens.opacityOverlay,
        ),
    };
  }
}
