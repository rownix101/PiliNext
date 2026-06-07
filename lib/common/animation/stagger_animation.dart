import 'package:flutter/material.dart';

import 'package:PiliNext/common/animation/fluid_tokens.dart';

/// A single animation track within a [StaggerAnimation].
///
/// Each track defines its own timing (duration, curve, delay) and value range.
/// Tracks run against a shared controller — delays stagger execution while
/// durations and curves let each property move at its own pace.
class StaggerTrack {
  const StaggerTrack({
    this.begin = 0.0,
    this.end = 1.0,
    this.duration,
    this.curve,
    this.delay = Duration.zero,
  });

  /// Starting value (when the track timer is at 0 %).
  final double begin;

  /// Ending value (when the track timer reaches 100 %).
  final double end;

  /// Duration for this track. Defaults to [FluidTokens.durationMd].
  final Duration? duration;

  /// Curve for this track. Defaults to [FluidTokens.curveEnter].
  final Curve? curve;

  /// Delay before this track starts animating.
  final Duration delay;
}

/// Composable staggered animation widget.
///
/// Manages a list of [StaggerTrack]s on a single [AnimationController].
/// Each track can have its own duration, curve, and delay — the controller
/// duration is automatically computed as the maximum end-time across all tracks.
///
/// ```dart
/// StaggerAnimation(
///   visible: _show,
///   tracks: const [
///     StaggerTrack(duration: FluidTokens.durationSm, curve: FluidTokens.curveEnter),
///     StaggerTrack(
///       duration: FluidTokens.durationMd,
///       curve: FluidTokens.curveEnter,
///       delay: Duration(milliseconds: 60),
///     ),
///   ],
///   builder: (context, values, _) {
///     return Opacity(
///       opacity: values[0],
///       child: Transform.translate(
///         offset: Offset(0, (1 - values[1]) * 12),
///         child: content,
///       ),
///     );
///   },
/// )
/// ```
class StaggerAnimation extends StatefulWidget {
  const StaggerAnimation({
    super.key,
    required this.tracks,
    this.visible = true,
    required this.builder,
    this.onComplete,
    this.child,
    this.initialValue = 0.0,
  });

  /// Animation tracks that run in parallel with independent timing.
  final List<StaggerTrack> tracks;

  /// When true, tracks animate toward their [StaggerTrack.end] values.
  /// When false, tracks animate toward their [StaggerTrack.begin] values.
  final bool visible;

  /// Builder called on every frame with the current value (0–1) of each track.
  final Widget Function(BuildContext context, List<double> values, Widget? child)
      builder;

  /// Called when the full animation (forward or reverse) completes.
  final VoidCallback? onComplete;

  /// Optional static child passed through to [builder].
  final Widget? child;

  /// Initial animation value (0–1). Useful for starting at the end state.
  final double initialValue;

  @override
  State<StaggerAnimation> createState() => _StaggerAnimationState();
}

class _StaggerAnimationState extends State<StaggerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;
  bool _wasVisible = true;

  Duration get _totalDuration {
    Duration max = Duration.zero;
    for (final track in widget.tracks) {
      final end = track.delay + (track.duration ?? FluidTokens.durationMd);
      if (end > max) max = end;
    }
    return max;
  }

  @override
  void initState() {
    super.initState();
    _wasVisible = widget.visible;
    _controller = AnimationController(
      vsync: this,
      duration: _totalDuration,
      value: widget.initialValue,
    );
    _buildAnimations();
    _controller.addStatusListener(_onStatusChange);
  }

  void _onStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      widget.onComplete?.call();
    }
  }

  @override
  void didUpdateWidget(StaggerAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tracks != oldWidget.tracks) {
      _controller.duration = _totalDuration;
      _buildAnimations();
    }
    if (widget.visible != _wasVisible) {
      _wasVisible = widget.visible;
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  void _buildAnimations() {
    final total = _totalDuration;
    final totalMs = total.inMilliseconds.toDouble();
    if (totalMs == 0) {
      _animations = widget.tracks.map((t) {
        return Tween<double>(begin: t.end, end: t.end).animate(_controller);
      }).toList();
      return;
    }

    _animations = widget.tracks.map((track) {
      final duration =
          track.duration ?? FluidTokens.durationMd;
      final startFraction =
          track.delay.inMilliseconds.toDouble() / totalMs;
      final endFraction =
          (track.delay + duration).inMilliseconds.toDouble() / totalMs;

      return Tween<double>(begin: track.begin, end: track.end).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            startFraction.clamp(0.0, 1.0),
            endFraction.clamp(0.0, 1.0),
            curve: track.curve ?? FluidTokens.curveEnter,
          ),
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_onStatusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (FluidTokens.reduceMotionOf(context)) {
      final snap = widget.visible ? 1.0 : 0.0;
      final values = widget.tracks
          .map((t) => snap == 1.0 ? t.end : t.begin)
          .toList();
      return widget.builder(context, values, widget.child);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final values = _animations.map((a) => a.value).toList();
        return widget.builder(context, values, child);
      },
      child: widget.child,
    );
  }
}
