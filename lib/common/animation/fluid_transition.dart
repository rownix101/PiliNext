import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'package:PiliNext/common/animation/fluid_tokens.dart';

/// A spring-driven transition widget for modern PiliNext motion.
///
/// It keeps the familiar opacity/scale/offset API, but state changes are driven
/// by [SpringSimulation] so interrupted animations inherit their current
/// velocity instead of restarting as fixed linear tweens.
class FluidTransition extends StatefulWidget {
  const FluidTransition({
    super.key,
    required this.child,
    this.visible = true,
    this.opacityBegin,
    this.opacityEnd,
    this.scaleBegin,
    this.scaleEnd,
    this.offsetBegin,
    this.offsetEnd,
    this.spring,
    this.duration,
    this.initialVelocity = 0,
    this.reduceMotion = true,
    this.onComplete,
  });

  /// The child widget to animate.
  final Widget child;

  /// Whether the child should be in its "visible" (end) state.
  final bool visible;

  final double? opacityBegin;
  final double? opacityEnd;
  final double? scaleBegin;
  final double? scaleEnd;
  final Offset? offsetBegin;
  final Offset? offsetEnd;

  /// Spring description. Defaults to [FluidTokens.springGentle].
  final SpringDescription? spring;

  /// Duration fallback used when animations are reduced.
  final Duration? duration;

  /// Optional velocity supplied by gesture-driven callers.
  final double initialVelocity;

  /// Whether to honor system reduced-motion settings.
  final bool reduceMotion;

  /// Called when the transition completes (settles).
  final VoidCallback? onComplete;

  @override
  State<FluidTransition> createState() => _FluidTransitionState();
}

class _FluidTransitionState extends State<FluidTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<Offset> _offset;

  bool _wasVisible = true;
  double _lastControllerValue = 0;
  Duration get _duration => widget.duration ?? FluidTokens.durationMd;
  SpringDescription get _spring => widget.spring ?? FluidTokens.springGentle;

  @override
  void initState() {
    super.initState();
    _wasVisible = widget.visible;
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
      value: widget.visible ? 1.0 : 0.0,
    );
    _lastControllerValue = _controller.value;
    _rebuildAnimations();

    _controller
      ..addListener(() {
        _lastControllerValue = _controller.value;
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          widget.onComplete?.call();
        }
      });
  }

  @override
  void didUpdateWidget(FluidTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = _duration;
    }
    if (oldWidget.spring != widget.spring ||
        oldWidget.opacityBegin != widget.opacityBegin ||
        oldWidget.opacityEnd != widget.opacityEnd ||
        oldWidget.scaleBegin != widget.scaleBegin ||
        oldWidget.scaleEnd != widget.scaleEnd ||
        oldWidget.offsetBegin != widget.offsetBegin ||
        oldWidget.offsetEnd != widget.offsetEnd) {
      _rebuildAnimations();
    }
    if (widget.visible != _wasVisible) {
      _wasVisible = widget.visible;
      _animate();
    }
  }

  void _rebuildAnimations() {
    _opacity = Tween<double>(
      begin: widget.opacityBegin ?? 0.0,
      end: widget.opacityEnd ?? 1.0,
    ).animate(_controller);
    _scale = Tween<double>(
      begin: widget.scaleBegin ?? 1.0,
      end: widget.scaleEnd ?? 1.0,
    ).animate(_controller);
    _offset = Tween<Offset>(
      begin: widget.offsetBegin ?? Offset.zero,
      end: widget.offsetEnd ?? Offset.zero,
    ).animate(_controller);
  }

  void _animate() {
    if (!mounted) return;
    final target = widget.visible ? 1.0 : 0.0;
    final inferredVelocity = (_controller.value - _lastControllerValue) * 60;
    final velocity = widget.initialVelocity != 0
        ? widget.initialVelocity
        : inferredVelocity;

    _controller
      ..stop()
      ..animateWith(
      FluidTokens.simulation(
        spring: _spring,
        from: _controller.value,
        to: target,
        velocity: velocity,
      ),
    );
  }

  /// Jump to a state immediately (no animation).
  void jumpToVisible(bool visible) {
    _wasVisible = visible;
    _controller.value = visible ? 1.0 : 0.0;
  }

  /// Animate with a specific [SpringSimulation] for velocity inheritance.
  void animateWithSimulation(SpringSimulation simulation) {
    _controller.animateWith(simulation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion && FluidTokens.reduceMotionOf(context)) {
      final opacity = widget.visible
          ? (widget.opacityEnd ?? 1.0)
          : (widget.opacityBegin ?? 0.0);
      return AnimatedOpacity(
        opacity: opacity,
        duration: FluidTokens.durationReduced,
        curve: FluidTokens.curveStandard,
        child: widget.child,
      );
    }

    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedBuilder(
          animation: _offset,
          builder: (context, child) {
            return Transform.translate(
              offset: _offset.value,
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
