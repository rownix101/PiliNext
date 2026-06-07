import 'dart:ui';

import 'package:PiliNext/common/animation/animation.dart';
import 'package:PiliNext/common/design/design_tokens.dart';
import 'package:PiliNext/utils/storage.dart';
import 'package:flutter/material.dart';

/// First-use gesture guide overlay for the video player.
///
/// Shows a semi-transparent glass overlay with gesture zone hints.
/// Auto-dismisses after 3 seconds. Only shown once (Hive flag).
///
/// Zones:
/// - Left side: vertical swipe → brightness
/// - Right side: vertical swipe → volume
/// - Center: double tap → play/pause
/// - Left double tap: seek backward 10s
/// - Right double tap: seek forward 10s
class GestureGuideOverlay extends StatefulWidget {
  const GestureGuideOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  /// Check if the guide should be shown (first time only).
  static bool get shouldShow {
    return GStorage.setting.get('gestureGuideShown') != true;
  }

  /// Mark the guide as shown so it never appears again.
  static void markShown() {
    GStorage.setting.put('gestureGuideShown', true);
  }

  @override
  State<GestureGuideOverlay> createState() => _GestureGuideOverlayState();
}

class _GestureGuideOverlayState extends State<GestureGuideOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: const Interval(0.0, 0.1, curve: FluidTokens.curveEnter)),
        ),
        weight: 0.1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0).chain(
          CurveTween(curve: const Interval(0.1, 0.85, curve: Curves.linear)),
        ),
        weight: 0.75,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: const Interval(0.85, 1.0, curve: FluidTokens.curveExit)),
        ),
        weight: 0.15,
      ),
    ]).animate(_controller);

    // Auto-dismiss and mark as shown
    _controller.forward().then((_) {
      GestureGuideOverlay.markShown();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (context, child) {
        final reduceMotion = FluidTokens.reduceMotionOf(context);
        final opacity = _fadeAnim.value;
        if (opacity <= 0.01) return child!;
        final contentProgress = reduceMotion
            ? opacity
            : FluidTokens.curveEnter.transform(opacity.clamp(0.0, 1.0));
        return Stack(
          children: [
            child!,
            // Glass overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacity,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5 * opacity),
                    ),
                  ),
                ),
              ),
            ),
            // Gesture zone hints
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: reduceMotion
                        ? Offset.zero
                        : Offset(0, (1 - contentProgress) * 10),
                    child: Transform.scale(
                      scale: reduceMotion ? 1.0 : 0.96 + contentProgress * 0.04,
                      child: _buildHints(size),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }

  Widget _buildHints(Size size) {
    return const Column(
      children: [
        // Top: brightness / volume labels
        Expanded(
          child: Row(
            children: [
              // Left zone — brightness
              Expanded(
                child: Center(
                  child: _HintPill(
                    icon: Icons.brightness_6,
                    label: '亮度',
                    direction: Axis.vertical,
                  ),
                ),
              ),
              // Center zone — double tap play/pause
              Expanded(
                child: Center(
                  child: _HintPill(
                    icon: Icons.touch_app,
                    label: '双击 播放/暂停',
                  ),
                ),
              ),
              // Right zone — volume
              Expanded(
                child: Center(
                  child: _HintPill(
                    icon: Icons.volume_up,
                    label: '音量',
                    direction: Axis.vertical,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bottom: seek hints
        Padding(
          padding: EdgeInsets.only(bottom: 80),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _HintPill(
                icon: Icons.replay_10,
                label: '双击 快退',
              ),
              _HintPill(
                icon: Icons.forward_10,
                label: '双击 快进',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HintPill extends StatelessWidget {
  const _HintPill({
    required this.icon,
    required this.label,
    this.direction = Axis.horizontal,
  });

  final IconData icon;
  final String label;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    final children = [
      Icon(icon, color: Colors.white, size: 28),
      const SizedBox(height: 8),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: AppRadii.fullAll,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: direction == Axis.vertical
          ? Column(mainAxisSize: MainAxisSize.min, children: children)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}
