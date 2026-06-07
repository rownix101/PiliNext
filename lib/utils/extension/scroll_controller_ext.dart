import 'package:PiliNext/common/animation/fluid_tokens.dart';
import 'package:flutter/widgets.dart' show ScrollController;

extension ScrollControllerExt on ScrollController {
  void animToTop() => animTo(0);

  void animTo(
    double offset, {
    Duration duration = FluidTokens.durationXxl,
  }) {
    if (!hasClients) return;
    if ((offset - this.offset).abs() >= position.viewportDimension * 7) {
      jumpTo(offset);
    } else {
      animateTo(
        offset,
        duration: duration,
        curve: FluidTokens.curveStandard,
      );
    }
  }

  void jumpToTop() {
    if (!hasClients) return;
    jumpTo(0);
  }
}
