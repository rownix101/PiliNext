import 'package:PiliNext/common/animation/animation.dart';
import 'package:PiliNext/common/design/design_tokens.dart';
import 'package:PiliNext/common/widgets/view_safe_area.dart';
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
    this.removeSafeArea = false,
    this.isFullScreen = false,
  });

  final Widget child;
  final bool visible;
  final double? height;
  final bool isTop;
  final bool removeSafeArea;
  final bool isFullScreen;

  @override
  State<GlassControlBar> createState() => _GlassControlBarState();
}

class _GlassControlBarState extends State<GlassControlBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late CurvedAnimation _curvedAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _noSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: FluidTokens.durationMd,
      value: widget.visible ? 1.0 : 0.0,
    );
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: FluidTokens.curveEnter,
    );
    _slideAnimation = _buildSlideAnimation();
    _noSlide = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(_curvedAnimation);
  }

  Animation<Offset> _buildSlideAnimation() {
    final beginOffset = widget.isTop
        ? const Offset(0, -FluidTokens.controlBarDy)
        : const Offset(0, FluidTokens.panelEnterDy);
    return Tween<Offset>(begin: beginOffset, end: Offset.zero)
        .animate(_curvedAnimation);
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
    if (widget.isTop != oldWidget.isTop) {
      _slideAnimation = _buildSlideAnimation();
    }
  }

  @override
  void dispose() {
    _curvedAnimation.dispose();
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

    final child = widget.removeSafeArea
        ? widget.child
        : ViewSafeArea(
            left: widget.isFullScreen,
            right: widget.isFullScreen,
            child: widget.child,
          );

    return FadeTransition(
      opacity: _curvedAnimation,
      child: SlideTransition(
        position: reduceMotion ? _noSlide : _slideAnimation,
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
            child: child,
          ),
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
