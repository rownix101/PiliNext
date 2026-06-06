import 'package:PiliNext/common/animation/animation.dart';
import 'package:PiliNext/common/style.dart';
import 'package:flutter/material.dart';

class ColorPalette extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool selected;
  final bool showBgColor;

  const ColorPalette({
    super.key,
    required this.colorScheme,
    required this.selected,
    this.showBgColor = true,
  });

  @override
  Widget build(BuildContext context) {
    final primary = colorScheme.primary;
    final tertiary = colorScheme.tertiary;
    final primaryContainer = colorScheme.primaryContainer;
    Widget child = ClipOval(
      child: Column(
        children: [
          _coloredBox(primary),
          Expanded(
            child: Row(
              children: [
                _coloredBox(tertiary),
                _coloredBox(primaryContainer),
              ],
            ),
          ),
        ],
      ),
    );

    child = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        child,
        AnimatedScale(
          scale: selected ? 1.0 : 0.72,
          duration: FluidTokens.effectiveDuration(
            context,
            FluidTokens.durationSm,
          ),
          curve: FluidTokens.curveEnter,
          child: AnimatedOpacity(
            opacity: selected ? 1.0 : 0.0,
            duration: FluidTokens.effectiveDuration(
              context,
              FluidTokens.durationSm,
            ),
            curve: FluidTokens.curveStandard,
            child: Container(
              width: 23,
              height: 23,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: primary,
                size: 12,
              ),
            ),
          ),
        ),
      ],
    );

    if (showBgColor) {
      return AnimatedScale(
        scale: selected ? 1.06 : 1.0,
        duration: FluidTokens.effectiveDuration(
          context,
          FluidTokens.durationSm,
        ),
        curve: FluidTokens.curveEnter,
        child: AnimatedContainer(
          duration: FluidTokens.effectiveDuration(
            context,
            FluidTokens.durationSm,
          ),
          curve: FluidTokens.curveStandard,
          width: 50,
          height: 50,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.onInverseSurface,
            borderRadius: Style.mdRadius,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      );
    }
    return child;
  }

  static Widget _coloredBox(Color color) => Expanded(
    child: ColoredBox(
      color: color,
      child: const SizedBox.expand(),
    ),
  );
}
