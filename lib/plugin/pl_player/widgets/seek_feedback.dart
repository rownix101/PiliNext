import 'dart:math' as math;

import 'package:PiliNext/common/animation/animation.dart';
import 'package:PiliNext/plugin/pl_player/player_tokens.dart';
import 'package:flutter/material.dart';

class SeekFeedback extends StatelessWidget {
  const SeekFeedback({
    super.key,
    required this.duration,
    required this.forward,
    required this.onTap,
  });

  final Duration duration;
  final bool forward;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = FluidTokens.reduceMotionOf(context);
    final sign = forward ? '+' : '-';
    final alignment = forward ? Alignment.centerRight : Alignment.centerLeft;
    final gradientBegin = forward
        ? Alignment.centerLeft
        : Alignment.centerRight;
    final gradientEnd = forward ? Alignment.centerRight : Alignment.centerLeft;
    final icon = forward
        ? Icons.keyboard_double_arrow_right
        : Icons.keyboard_double_arrow_left;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        splashColor: Colors.white.withValues(alpha: 0.10),
        highlightColor: Colors.white.withValues(alpha: 0.04),
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          key: ValueKey('${forward}_${duration.inMilliseconds}'),
          tween: Tween(begin: 0, end: 1),
          duration: FluidTokens.effectiveDuration(
            context,
            FluidTokens.durationMd,
          ),
          curve: FluidTokens.curveEnter,
          builder: (context, value, child) {
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: gradientBegin,
                  end: gradientEnd,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.16 + value * 0.20),
                  ],
                ),
              ),
              child: Stack(
                alignment: alignment,
                children: [
                  if (!reduceMotion)
                    Positioned(
                      left: forward ? null : -48,
                      right: forward ? -48 : null,
                      child: Transform.scale(
                        scale: 0.8 + value * 1.4,
                        child: Opacity(
                          opacity: (1 - value).clamp(0.0, 1.0) * 0.22,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: forward ? 0 : 34,
                      right: forward ? 34 : 0,
                    ),
                    child: Transform.translate(
                      offset: reduceMotion
                          ? Offset.zero
                          : Offset((forward ? 1 : -1) * (1 - value) * 14, 0),
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ArrowBurst(icon: icon, forward: forward),
                            const SizedBox(height: 10),
                            Transform.scale(
                              scale: reduceMotion ? 1.0 : 0.92 + value * 0.08,
                        child: Text(
                          '$sign${duration.inSeconds}s',
                          style: PlayerTokens.seekFeedbackText,
                        ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ArrowBurst extends StatelessWidget {
  const _ArrowBurst({required this.icon, required this.forward});

  final IconData icon;
  final bool forward;

  @override
  Widget build(BuildContext context) {
    final children = List.generate(3, (index) {
      final opacity = 0.35 + index * 0.25;
      return Transform.translate(
        offset: Offset((forward ? 1 : -1) * index * 3, 0),
        child: Icon(
          icon,
          size: 24 + math.min(index, 1) * 2,
          color: Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
          shadows: const [
            Shadow(color: Colors.black45, blurRadius: 6),
          ],
        ),
      );
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: forward ? children : children.reversed.toList(),
    );
  }
}
