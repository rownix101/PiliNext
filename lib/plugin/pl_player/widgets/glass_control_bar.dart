import 'package:PiliNext/common/animation/animation.dart';
import 'package:PiliNext/common/design/design_tokens.dart';
import 'package:flutter/material.dart';

/// A glassmorphism player control bar wrapper.
///
/// Applies BackdropFilter blur + semi-transparent surface + subtle border
/// to any player control bar content. Use as a drop-in background for
/// [bottom_control.dart] and [header_control.dart].
class GlassControlBar extends StatefulWidget {
  const GlassControlBar({
    super.key,
    required this.child,
    this.visible = true,
    this.height,
    this.isTop = false,
  });

  final Widget child;
  final bool visible;
  final double? height;
  final bool isTop;

  @override
  State<GlassControlBar> createState() => _GlassControlBarState();
}

class _GlassControlBarState extends State<GlassControlBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: FluidTokens.durationMd,
      value: widget.visible ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(GlassControlBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = FluidTokens.reduceMotionOf(context);
    final border = isDark
        ? GlassTokens.borderDark(colorScheme.outlineVariant)
        : GlassTokens.borderLight(colorScheme.outlineVariant);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = FluidTokens.curveEnter.transform(_controller.value);
        final dy = widget.isTop
            ? -FluidTokens.controlBarDy * (1 - value)
            : FluidTokens.panelEnterDy * (1 - value);
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: reduceMotion ? Offset.zero : Offset(0, dy),
            child: child,
          ),
        );
      },
      child: GlassTokens.blurFilter(
        sigma: GlassTokens.blurFloating,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(
              alpha: GlassTokens.opacityFloating,
            ),
            border: Border(
              top: widget.isTop ? BorderSide.none : border,
              bottom: widget.isTop ? border : BorderSide.none,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A player button with short tactile feedback on press.
class BouncePlayerButton extends StatefulWidget {
  const BouncePlayerButton({
    super.key,
    required this.icon,
    this.size = 40,
    this.onTap,
    this.tooltip,
    this.color,
  });

  final Widget icon;
  final double size;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? color;

  @override
  State<BouncePlayerButton> createState() => _BouncePlayerButtonState();
}

class _BouncePlayerButtonState extends State<BouncePlayerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: FluidTokens.durationSm,
      value: 1.0,
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: FluidTokens.pressScale,
        ).chain(CurveTween(curve: FluidTokens.curveExit)),
        weight: 0.35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: FluidTokens.pressScale,
          end: 1.0,
        ).chain(CurveTween(curve: FluidTokens.curveEnter)),
        weight: 0.65,
      ),
    ]).animate(_bounceController);
  }

  void _handleTap() {
    if (!FluidTokens.reduceMotionOf(context)) {
      _bounceController
        ..reset()
        ..forward();
    }
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: IconButton(
          onPressed: _handleTap,
          icon: widget.icon,
          iconSize: widget.size * 0.55,
          color: widget.color,
          tooltip: widget.tooltip,
          splashRadius: widget.size * 0.5,
        ),
      ),
    );
  }
}
