import 'package:PiliNext/common/animation/fluid_tokens.dart';
import 'package:PiliNext/utils/haptic_service.dart';
import 'package:flutter/material.dart';

/// A pressable wrapper that applies spring scale animation on press/release.
///
/// Maps Material 3 Expressive's "springy, tactile" feel to any widget.
/// Respects [FluidTokens.reduceMotionOf] — when motion is reduced,
/// the animation is skipped and the widget renders statically.
class SpringPressable extends StatefulWidget {
  const SpringPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.hapticLevel = HapticLevel.light,
    this.scaleAmount = 0.96,
    this.borderRadius,
    this.enabled = true,
    this.splashFactory,
    this.highlightColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final HapticLevel hapticLevel;
  final double scaleAmount;
  final BorderRadius? borderRadius;
  final bool enabled;
  final InteractiveInkFeatureFactory? splashFactory;
  final Color? highlightColor;

  @override
  State<SpringPressable> createState() => _SpringPressableState();
}

class _SpringPressableState extends State<SpringPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: FluidTokens.durationXs,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleAmount).animate(
      CurvedAnimation(parent: _controller, curve: FluidTokens.curveEnter),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    if (FluidTokens.reduceMotionOf(context)) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    if (FluidTokens.reduceMotionOf(context)) return;
    _controller.reverse();
  }

  void _onTapCancel() {
    if (!widget.enabled) return;
    if (FluidTokens.reduceMotionOf(context)) return;
    _controller.reverse();
  }

  void _handleTap() {
    HapticService.play(widget.hapticLevel);
    widget.onTap?.call();
  }

  void _handleLongPress() {
    HapticService.play(HapticLevel.medium);
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = FluidTokens.reduceMotionOf(context);

    final animated = reduceMotion
        ? widget.child
        : AnimatedBuilder(
            animation: _scale,
            builder: (context, child) => Transform.scale(
              scale: _scale.value,
              child: child,
            ),
            child: widget.child,
          );

    if (!widget.enabled) return animated;

    final effectiveRadius = widget.borderRadius;
    if (effectiveRadius != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          borderRadius: effectiveRadius,
          onTap: widget.onTap == null ? null : _handleTap,
          onLongPress: widget.onLongPress == null ? null : _handleLongPress,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          splashFactory: widget.splashFactory,
          highlightColor: widget.highlightColor,
          child: animated,
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap == null ? null : _handleTap,
      onLongPress:
          widget.onLongPress == null ? null : _handleLongPress,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: animated,
    );
  }
}

/// An [AnimatedContainer]-like widget that uses spring physics
/// for fluid size/position changes.
class SpringAnimatedContainer extends StatefulWidget {
  const SpringAnimatedContainer({
    super.key,
    this.width,
    this.height,
    this.decoration,
    this.padding,
    this.margin,
    this.alignment,
    this.duration,
    this.spring,
    required this.child,
  });

  final double? width;
  final double? height;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry? alignment;
  final SpringDescription? spring;
  final Duration? duration;
  final Widget child;

  @override
  State<SpringAnimatedContainer> createState() =>
      _SpringAnimatedContainerState();
}

class _SpringAnimatedContainerState extends State<SpringAnimatedContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double>? _widthAnim;
  Animation<double>? _heightAnim;

  double? _prevWidth;
  double? _prevHeight;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? FluidTokens.durationMd,
    );
  }

  @override
  void didUpdateWidget(SpringAnimatedContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width ||
        oldWidget.height != widget.height) {
      _setupAnimations();
      _controller.forward(from: 0);
    }
  }

  void _setupAnimations() {
    if (widget.width != null && widget.width != _prevWidth) {
      _widthAnim = Tween<double>(
        begin: _prevWidth ?? widget.width!,
        end: widget.width!,
      ).animate(_controller);
      _prevWidth = widget.width;
    }
    if (widget.height != null && widget.height != _prevHeight) {
      _heightAnim = Tween<double>(
        begin: _prevHeight ?? widget.height!,
        end: widget.height!,
      ).animate(_controller);
      _prevHeight = widget.height;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = FluidTokens.reduceMotionOf(context);

    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: widget.decoration,
        padding: widget.padding,
        margin: widget.margin,
        alignment: widget.alignment,
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: _widthAnim?.value ?? widget.width,
          height: _heightAnim?.value ?? widget.height,
          decoration: widget.decoration,
          padding: widget.padding,
          margin: widget.margin,
          alignment: widget.alignment,
          child: widget.child,
        );
      },
    );
  }
}
