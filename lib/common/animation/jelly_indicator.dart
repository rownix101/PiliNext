import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'fluid_tokens.dart';

/// A pill-shaped indicator that animates between positions with a
/// jelly-like stretch-squish effect — the signature animation of
/// PiliNext's navigation bar.
///
/// The animation has 3 phases:
/// 1. **Stretch** (0–40%): indicator stretches from A toward B,
///    width grows to (distance × 1.3 + originalWidth), then begins
///    moving toward target.
/// 2. **Overshoot** (40–70%): indicator arrives at B, overshoots by
///    5–8dp, aspect ratio recovers from stretch.
/// 3. **Settle** (70–100%): indicator bounces back to exact B,
///    1–2 damped oscillations then stable.
///
/// Total duration: ~500ms (distance-dependent, longer for far jumps).
class JellyIndicator extends StatefulWidget {
  const JellyIndicator({
    super.key,
    required this.currentIndex,
    required this.itemCount,
    this.itemWidth = 64,
    this.indicatorHeight = 32,
    this.indicatorColor,
    this.padding = EdgeInsets.zero,
  });

  /// Currently selected tab index.
  final int currentIndex;

  /// Total number of tabs.
  final int itemCount;

  /// Width of each tab item (used to calculate indicator position).
  final double itemWidth;

  /// Height of the pill indicator.
  final double indicatorHeight;

  /// Color of the pill indicator.
  final Color? indicatorColor;

  /// Padding offset for the indicator within the bar.
  final EdgeInsets padding;

  @override
  State<JellyIndicator> createState() => _JellyIndicatorState();
}

class _JellyIndicatorState extends State<JellyIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _previousIndex = 0;

  // Computed positions
  double get _startX => _previousIndex * widget.itemWidth;
  double get _endX => widget.currentIndex * widget.itemWidth;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: FluidTokens.durationXl,
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(JellyIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _previousIndex && widget.currentIndex != oldWidget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.indicatorColor ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.20);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value; // 0 → 1
        final distance = _endX - _startX;

        // ── Phase decomposition ──────────────────────────────
        // Phase 1 (0.0 – 0.40): stretch
        // Phase 2 (0.40 – 0.70): overshoot
        // Phase 3 (0.70 – 1.00): settle

        double translateX;
        double scaleX;
        double scaleY;

        if (t < 0.40) {
          // Stretch phase
          final p = t / 0.40; // normalize to 0→1 within phase
          // Width stretches by up to 30% of distance
          scaleX = 1.0 + 0.3 * (1.0 - _easeOut(p)) * (distance.abs() / widget.itemWidth).clamp(0.0, 1.5);
          scaleY = 1.0 / scaleX; // preserve area (squish vertically)
          // Movement starts slow, accelerates
          translateX = _startX + distance * _easeInOut(p * 0.6);
        } else if (t < 0.70) {
          // Overshoot phase
          final p = (t - 0.40) / 0.30; // normalize to 0→1
          final overshoot = 8.0 * (1.0 - p); // 8dp → 0dp overshoot
          final overshootSign = distance >= 0 ? 1.0 : -1.0;
          translateX = _endX + overshoot * overshootSign;
          // Scale recovers from stretch to normal
          scaleX = 1.0 + 0.05 * (1.0 - p);
          scaleY = 1.0;
        } else {
          // Settle phase
          final p = (t - 0.70) / 0.30; // normalize to 0→1
          // Damped oscillation: 2 bounces
          final oscillation = _dampedOscillation(p, cycles: 2, damping: 0.7);
          translateX = _endX + oscillation * 3; // max 3dp wobble
          scaleX = 1.0 + oscillation.abs() * 0.03;
          scaleY = 1.0;
        }

        return Transform.translate(
          offset: Offset(
            translateX + widget.padding.left,
            widget.padding.top,
          ),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..scale(scaleX, scaleY),
            child: Container(
              width: widget.itemWidth - widget.padding.horizontal,
              height: widget.indicatorHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(widget.indicatorHeight / 2),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Easing helpers ──────────────────────────────────────────

  static double _easeOut(double t) {
    return 1.0 - (1.0 - t) * (1.0 - t);
  }

  static double _easeInOut(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  /// Damped sinusoidal oscillation.
  /// [cycles] = number of full cycles, [damping] = amplitude decay per cycle.
  static double _dampedOscillation(double t, {int cycles = 2, double damping = 0.7}) {
    if (t >= 1.0) return 0.0;
    final amplitude = (1.0 - t).clamp(0.0, 1.0) * damping;
    final frequency = cycles * 2 * 3.14159;
    return amplitude * math.sin(t * frequency);
  }
}
