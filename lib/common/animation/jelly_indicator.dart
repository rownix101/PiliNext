import 'package:flutter/material.dart';

import 'package:PiliNext/common/animation/fluid_tokens.dart';

/// A liquid pill indicator for PiliNext navigation.
///
/// Instead of scaling one rectangle, the leading and trailing edges move on
/// slightly offset timing. The result feels like a modern liquid capsule: the
/// edge closest to the destination leads, the opposite edge follows, then both
/// settle without exaggerated wobble.
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

  double get _pillWidth => (widget.itemWidth - widget.padding.horizontal).clamp(
    0.0,
    double.infinity,
  );
  double get _startLeft =>
      _previousIndex * widget.itemWidth + widget.padding.left;
  double get _endLeft =>
      widget.currentIndex * widget.itemWidth + widget.padding.left;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: FluidTokens.durationLg,
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(JellyIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex ||
        widget.itemWidth != oldWidget.itemWidth) {
      _previousIndex = oldWidget.currentIndex.clamp(0, widget.itemCount - 1);
      final jump = (widget.currentIndex - _previousIndex).abs();
      _controller.duration = jump <= 1
          ? const Duration(milliseconds: 260)
          : const Duration(milliseconds: 320);
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.indicatorColor ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.20);
    final reduceMotion = FluidTokens.reduceMotionOf(context);

    if (reduceMotion) {
      return AnimatedPositioned(
        duration: FluidTokens.durationReduced,
        curve: FluidTokens.curveStandard,
        left: _endLeft,
        top: widget.padding.top,
        width: _pillWidth,
        height: widget.indicatorHeight,
        child: _Pill(color: color, height: widget.indicatorHeight),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final startRight = _startLeft + _pillWidth;
        final endRight = _endLeft + _pillWidth;
        final movingRight = _endLeft >= _startLeft;

        final leadProgress = _liquidEase((t / 0.72).clamp(0.0, 1.0));
        final followProgress = _liquidEase(((t - 0.12) / 0.78).clamp(0.0, 1.0));
        final settle = _settle(t);
        final overshoot = (1 - t).clamp(0.0, 1.0) * 3.0 * settle;

        double left;
        double right;
        if (movingRight) {
          right = _lerp(startRight, endRight, leadProgress) + overshoot;
          left = _lerp(_startLeft, _endLeft, followProgress);
        } else {
          left = _lerp(_startLeft, _endLeft, leadProgress) - overshoot;
          right = _lerp(startRight, endRight, followProgress);
        }

        final minWidth = _pillWidth * 0.78;
        if (right - left < minWidth) {
          final center = (left + right) / 2;
          left = center - minWidth / 2;
          right = center + minWidth / 2;
        }

        return Positioned(
          left: left,
          top: widget.padding.top,
          width: right - left,
          height: widget.indicatorHeight,
          child: _Pill(color: color, height: widget.indicatorHeight),
        );
      },
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double _liquidEase(double t) {
    return 1 - (1 - t) * (1 - t) * (1 - t);
  }

  static double _settle(double t) {
    if (t < 0.78) return 0;
    final p = (t - 0.78) / 0.22;
    return (1 - p).clamp(0.0, 1.0);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
