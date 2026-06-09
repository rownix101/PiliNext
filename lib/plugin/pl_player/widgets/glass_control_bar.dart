import 'package:PiliNext/common/animation/animation.dart';
import 'package:PiliNext/common/design/design_tokens.dart';
import 'package:PiliNext/common/widgets/player_glass_surface.dart';
import 'package:PiliNext/common/widgets/view_safe_area.dart';
import 'package:PiliNext/plugin/pl_player/player_tokens.dart';
import 'package:flutter/material.dart';

/// Animates player control bars in and out.
///
/// The control bar no longer paints a full-width background; individual
/// control groups should opt into [PlayerControlSurface] instead.
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
    _noSlide = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_curvedAnimation);
  }

  Animation<Offset> _buildSlideAnimation() {
    final beginOffset = widget.isTop
        ? const Offset(0, -FluidTokens.controlBarDy)
        : const Offset(0, FluidTokens.panelEnterDy);
    return Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(_curvedAnimation);
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
    final reduceMotion = FluidTokens.reduceMotionOf(context);

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
        child: SizedBox(
          height: widget.height,
          child: child,
        ),
      ),
    );
  }
}

/// Local contrast surface for a related group of player controls.
class PlayerControlSurface extends StatelessWidget {
  const PlayerControlSurface({
    super.key,
    required this.child,
    this.padding = PlayerTokens.controlSurfacePadding,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return PlayerGlassSurface(
      sigma: GlassTokens.blurFloating,
      backgroundColor: PlayerTokens.surfaceFill,
      borderRadius: PlayerTokens.controlSurfaceRadius,
      interactive: true,
      border: Border.all(
        color: ColorScheme.of(context).outlineVariant.withValues(alpha: 0.08),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Unified contrast layer behind visible player controls.
class PlayerOverlayScrim extends StatelessWidget {
  const PlayerOverlayScrim({
    super.key,
    required this.visible,
  });

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: FluidTokens.durationMd,
        curve: FluidTokens.curveStandard,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.48),
                Colors.black.withValues(alpha: 0.08),
                Colors.black.withValues(alpha: 0.10),
                Colors.black.withValues(alpha: 0.56),
              ],
              stops: const [0.0, 0.28, 0.58, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
