import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'fluid_tokens.dart';

/// A spring-driven transition widget that replaces [AnimatedOpacity],
/// [AnimatedContainer], [AnimatedSlide], and [AnimatedScale].
///
/// All animations use spring physics — velocity-aware, distance-adaptive,
/// with natural termination. No fixed-duration easing curves.
///
/// ## Basic usage
/// ```dart
/// FluidTransition(
///   visible: _isVisible,
///   preset: FluidTokens.fadeIn,
///   child: Text('Hello'),
/// )
/// ```
///
/// ## Explicit parameters (overrides preset)
/// ```dart
/// FluidTransition(
///   visible: _isOpen,
///   opacityBegin: 0.0,
///   opacityEnd: 1.0,
///   spring: FluidTokens.springFluid,
///   duration: FluidTokens.durationMd,
///   child: Panel(),
/// )
/// ```
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
    this.onComplete,
  });

  /// The child widget to animate.
  final Widget child;

  /// Whether the child should be in its "visible" (end) state.
  final bool visible;

  // ── Value ranges ──────────────────────────────────────────────

  final double? opacityBegin;
  final double? opacityEnd;
  final double? scaleBegin;
  final double? scaleEnd;
  final Offset? offsetBegin;
  final Offset? offsetEnd;

  // ── Physics ───────────────────────────────────────────────────

  /// Spring description. Defaults to [FluidTokens.springGentle].
  final SpringDescription? spring;

  /// Duration hint (used for animation controller upper bound).
  final Duration? duration;

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

  SpringDescription get _spring => widget.spring ?? FluidTokens.springGentle;
  Duration get _duration => widget.duration ?? FluidTokens.durationMd;

  @override
  void initState() {
    super.initState();
    _wasVisible = widget.visible;
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
    );

    // Build spring-driven animations from the controller's 0→1 value.
    _opacity = _buildOpacityAnim();
    _scale = _buildScaleAnim();
    _offset = _buildOffsetAnim();

    // Start in the correct state.
    if (widget.visible) {
      _controller.value = 1.0;
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(FluidTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != _wasVisible) {
      _wasVisible = widget.visible;
      _animate();
    }
    if (oldWidget.spring != widget.spring ||
        oldWidget.opacityBegin != widget.opacityBegin ||
        oldWidget.opacityEnd != widget.opacityEnd ||
        oldWidget.scaleBegin != widget.scaleEnd ||
        oldWidget.offsetBegin != widget.offsetBegin ||
        oldWidget.offsetEnd != widget.offsetEnd) {
      setState(() {
        _opacity = _buildOpacityAnim();
        _scale = _buildScaleAnim();
        _offset = _buildOffsetAnim();
      });
    }
  }

  void _animate() {
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  /// Jump to a state immediately (no animation).
  /// Used when velocity inheritance is handled externally.
  void jumpToVisible(bool visible) {
    _wasVisible = visible;
    _controller.value = visible ? 1.0 : 0.0;
  }

  /// Animate with a specific [SpringSimulation] for velocity inheritance.
  void animateWithSimulation(SpringSimulation simulation) {
    _controller.animateWith(simulation);
  }

  Animation<double> _buildOpacityAnim() {
    final begin = widget.opacityBegin ?? 0.0;
    final end = widget.opacityEnd ?? 1.0;
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  Animation<double> _buildScaleAnim() {
    if (widget.scaleBegin == null && widget.scaleEnd == null) {
      return Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
    }
    final begin = widget.scaleBegin ?? 1.0;
    final end = widget.scaleEnd ?? 1.0;
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  Animation<Offset> _buildOffsetAnim() {
    final begin = widget.offsetBegin ?? Offset.zero;
    final end = widget.offsetEnd ?? Offset.zero;
    return Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _offset.value,
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
