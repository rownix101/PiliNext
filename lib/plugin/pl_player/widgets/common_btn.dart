import 'package:PiliNext/common/animation/animation.dart';
import 'package:PiliNext/common/animation/fluid_tokens.dart';
import 'package:PiliNext/plugin/pl_player/player_tokens.dart';
import 'package:flutter/material.dart';

class ComBtn extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final double width;
  final double height;
  final String? tooltip;

  const ComBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.width = PlayerTokens.buttonSize,
    this.height = PlayerTokens.buttonSize,
    this.tooltip,
  });

  @override
  State<ComBtn> createState() => _ComBtnState();
}

class _ComBtnState extends State<ComBtn>
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

  void _handleLongPress() {
    if (!FluidTokens.reduceMotionOf(context)) {
      _bounceController
        ..reset()
        ..forward();
    }
    widget.onLongPress?.call();
  }

  void _handleSecondaryTap() {
    if (!FluidTokens.reduceMotionOf(context)) {
      _bounceController
        ..reset()
        ..forward();
    }
    widget.onSecondaryTap?.call();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: GestureDetector(
          onTap: widget.onTap != null ? _handleTap : null,
          onLongPress: widget.onLongPress != null ? _handleLongPress : null,
          onSecondaryTap:
              widget.onSecondaryTap != null ? _handleSecondaryTap : null,
          behavior: HitTestBehavior.opaque,
          child: widget.icon,
        ),
      ),
    );
    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip, child: child);
    }
    return child;
  }
}
