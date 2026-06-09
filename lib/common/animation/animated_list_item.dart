import 'package:flutter/material.dart';

import 'package:PiliNext/common/animation/fluid_tokens.dart';

/// Direction from which list items enter.
enum ListItemDirection {
  /// Items slide up from below (vertical lists).
  fromBottom,

  /// Items slide in from the right (horizontal lists).
  fromRight,
}

/// A standardized stagger-entrance wrapper for list/grid items.
///
/// Wraps a child with a fade + translate animation that starts with a
/// per-index delay, creating a wave/stagger effect on first appearance.
///
/// Only the first [maxStaggerIndex] items receive a stagger delay — later
/// items animate immediately with no delay, so infinite lists don't
/// accumulate absurd wait times.
///
/// The entrance distance decays from [distance] to [decayEndDistance]
/// across the stagger range — early items travel farther, later items
/// barely shift. This gives the user's eye a clear entry point.
///
/// ```dart
/// SliverGrid.builder(
///   itemBuilder: (context, index) => AnimatedListItem(
///     index: index,
///     child: VideoCardV(videoItem: items[index]),
///   ),
/// )
/// ```
class AnimatedListItem extends StatefulWidget {
  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.direction = ListItemDirection.fromBottom,
    this.staggerInterval = const Duration(milliseconds: 35),
    this.maxStaggerIndex = 8,
    this.duration = FluidTokens.durationSm,
    this.distance,
    this.decayEndDistance,
  });

  /// Item index in the list — used to compute stagger delay.
  final int index;

  /// The widget to animate in.
  final Widget child;

  /// Direction of the entrance offset.
  final ListItemDirection direction;

  /// Delay between consecutive items.
  final Duration staggerInterval;

  /// Maximum index that receives stagger delay. Items beyond this
  /// animate with zero delay.
  final int maxStaggerIndex;

  /// Duration of each item's entrance animation.
  final Duration duration;

  /// Distance of the entrance offset for the first item (index 0),
  /// in logical pixels. Defaults to [FluidTokens.contentEnterDy].
  final double? distance;

  /// Entrance distance for the last stagger-eligible item. Items in
  /// between receive a linear interpolation. Defaults to 1/3 of [distance]
  /// or [FluidTokens.contentEnterDy] / 3.
  ///
  /// Smaller values create a stronger "wave front" effect where the
  /// leading items do most of the spatial work and trailing items
  /// barely move.
  final double? decayEndDistance;

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _offset;
  late final double _effectiveDistance;

  @override
  void initState() {
    super.initState();
    final staggerIndex = widget.index.clamp(0, widget.maxStaggerIndex);
    final delay = widget.staggerInterval * staggerIndex;
    final totalDuration = delay + widget.duration;

    final baseDistance = widget.distance ?? FluidTokens.contentEnterDy;
    final endDistance = widget.decayEndDistance ?? baseDistance / 3;
    final decayFraction =
        widget.maxStaggerIndex > 0 ? staggerIndex / widget.maxStaggerIndex : 0.0;
    _effectiveDistance =
        baseDistance + (endDistance - baseDistance) * decayFraction;

    _controller = AnimationController(
      vsync: this,
      duration: totalDuration,
    );

    final startFraction = totalDuration.inMilliseconds == 0
        ? 0.0
        : delay.inMilliseconds / totalDuration.inMilliseconds;

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        startFraction,
        1.0,
        curve: FluidTokens.curveEnter,
      ),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
    _offset = Tween<double>(begin: 1.0, end: 0.0).animate(curvedAnimation);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (FluidTokens.reduceMotionOf(context)) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = switch (widget.direction) {
          ListItemDirection.fromBottom =>
            Offset(0, _offset.value * _effectiveDistance),
          ListItemDirection.fromRight =>
            Offset(_offset.value * _effectiveDistance, 0),
        };
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(offset: offset, child: child),
        );
      },
      child: widget.child,
    );
  }
}
