import 'package:PiliNext/common/animation/animation.dart';
import 'package:PiliNext/common/widgets/progress_bar/audio_video_progress_bar.dart';
import 'package:PiliNext/utils/platform_utils.dart';
import 'package:flutter/material.dart';

export 'package:PiliNext/common/widgets/progress_bar/audio_video_progress_bar.dart'
    show ThumbDragDetails, ThumbDragStartCallback, ThumbDragUpdateCallback;

/// A progress bar that smoothly animates its bar height and thumb radius
/// when the user hovers (desktop) or drags (all platforms).
///
/// Wraps the existing [ProgressBar] render object, driving animated values
/// into it via rebuild. This gives a YouTube-style "expand on interact" feel.
class AnimatedProgressBar extends StatefulWidget {
  const AnimatedProgressBar({
    super.key,
    required this.progress,
    required this.total,
    this.buffered = Duration.zero,
    this.onSeek,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.isDragging = false,
    // Sizing
    this.barHeight = 3.5,
    this.hoverBarHeight = 4.5,
    this.expandedBarHeight = 5.5,
    this.thumbRadius = 7.0,
    this.hoverThumbRadius = 8.0,
    this.expandedThumbRadius = 10.0,
    this.thumbGlowRadius = 25.0,
    // Colors
    required this.progressBarColor,
    required this.baseBarColor,
    required this.bufferedBarColor,
    required this.thumbColor,
    required this.thumbGlowColor,
  });

  final Duration progress;
  final Duration total;
  final Duration buffered;

  final ValueChanged<Duration>? onSeek;
  final ThumbDragStartCallback? onDragStart;
  final ThumbDragUpdateCallback? onDragUpdate;
  final VoidCallback? onDragEnd;

  /// Whether the user is currently dragging the thumb.
  final bool isDragging;

  // ── Size tokens ──────────────────────────────────────────────
  final double barHeight;
  final double hoverBarHeight;
  final double expandedBarHeight;
  final double thumbRadius;
  final double hoverThumbRadius;
  final double expandedThumbRadius;
  final double thumbGlowRadius;

  // ── Colors ───────────────────────────────────────────────────
  final Color progressBarColor;
  final Color baseBarColor;
  final Color bufferedBarColor;
  final Color thumbColor;
  final Color thumbGlowColor;

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isHovering = false;

  // 0.0 = rest, 0.5 = hover, 1.0 = dragging
  double get _targetValue {
    if (widget.isDragging) return 1.0;
    if (_isHovering) return 0.5;
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: _targetValue,
      duration: FluidTokens.durationSm, // expand
      reverseDuration: FluidTokens.durationMd, // contract
    );
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDragging != oldWidget.isDragging) {
      _animateToTarget();
    }
  }

  void _animateToTarget() {
    final target = _targetValue;
    _controller.animateTo(
      target,
      duration: target > _controller.value
          ? FluidTokens.durationSm
          : FluidTokens.durationMd,
      curve: target > _controller.value
          ? FluidTokens.curveEnter
          : FluidTokens.curveExit,
    );
  }

  void _onEnter(PointerEvent _) {
    if (!widget.isDragging) {
      _isHovering = true;
      _animateToTarget();
    }
  }

  void _onExit(PointerEvent _) {
    _isHovering = false;
    if (!widget.isDragging) {
      _animateToTarget();
    }
  }

  double _lerpThreeWay(double rest, double hover, double expanded, double t) {
    if (t <= 0.5) {
      final localT = t * 2; // 0..1 within rest→hover
      return rest + (hover - rest) * localT;
    } else {
      final localT = (t - 0.5) * 2; // 0..1 within hover→expanded
      return hover + (expanded - hover) * localT;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final barH = _lerpThreeWay(
          widget.barHeight,
          widget.hoverBarHeight,
          widget.expandedBarHeight,
          t,
        );
        final thumbR = _lerpThreeWay(
          widget.thumbRadius,
          widget.hoverThumbRadius,
          widget.expandedThumbRadius,
          t,
        );
        return ProgressBar(
          progress: widget.progress,
          total: widget.total,
          buffered: widget.buffered,
          onSeek: widget.onSeek,
          onDragStart: widget.onDragStart,
          onDragUpdate: widget.onDragUpdate,
          onDragEnd: widget.onDragEnd,
          barHeight: barH,
          thumbRadius: thumbR,
          thumbGlowRadius: widget.thumbGlowRadius,
          progressBarColor: widget.progressBarColor,
          baseBarColor: widget.baseBarColor,
          bufferedBarColor: widget.bufferedBarColor,
          thumbColor: widget.thumbColor,
          thumbGlowColor: widget.thumbGlowColor,
        );
      },
    );

    if (PlatformUtils.isDesktop) {
      child = MouseRegion(
        onEnter: _onEnter,
        onExit: _onExit,
        hitTestBehavior: HitTestBehavior.translucent,
        child: child,
      );
    }

    return child;
  }
}
