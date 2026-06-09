import 'package:PiliNext/common/widgets/progress_bar/animated_progress_bar.dart';
import 'package:PiliNext/common/widgets/progress_bar/segment_progress_bar.dart';
import 'package:PiliNext/pages/video/controller.dart';
import 'package:PiliNext/plugin/pl_player/controller.dart';
import 'package:PiliNext/plugin/pl_player/player_tokens.dart';
import 'package:PiliNext/plugin/pl_player/view/view.dart';
import 'package:PiliNext/utils/extension/theme_ext.dart';
import 'package:PiliNext/utils/feed_back.dart';
import 'package:PiliNext/utils/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomControl extends StatelessWidget {
  const BottomControl({
    super.key,
    required this.maxWidth,
    required this.isFullScreen,
    required this.controller,
    required this.buildBottomControl,
    required this.videoDetailController,
  });

  final double maxWidth;
  final bool isFullScreen;
  final PlPlayerController controller;
  final ValueGetter<Widget> buildBottomControl;
  final VideoDetailController videoDetailController;

  void onDragStart(ThumbDragDetails duration) {
    feedBack();
    controller.onChangedSliderStart(duration.timeStamp);
  }

  void onDragUpdate(ThumbDragDetails duration) {
    if (!controller.isFileSource && controller.showSeekPreview) {
      final totalMs = controller.duration.value.inMilliseconds;
      final ratio =
          totalMs > 0 ? (duration.timeStamp.inMilliseconds / totalMs).clamp(0.0, 1.0) : 0.5;
      controller.updatePreviewIndex(duration.timeStamp.inSeconds, ratio: ratio);
    }
    controller.onUpdatedSliderProgress(duration.timeStamp);
  }

  void onSeek(Duration duration) {
    if (controller.showSeekPreview) {
      controller.showPreview.value = false;
    }
    controller
      ..onChangedSliderEnd()
      ..onChangedSlider(duration.inSeconds)
      ..seekTo(Duration(seconds: duration.inSeconds), isSeek: false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final primary = colorScheme.isLight
        ? colorScheme.inversePrimary
        : colorScheme.primary;
    final baseBarColor = colorScheme.onSurface.withValues(alpha: 0.12);
    final thumbGlowColor = primary.withAlpha(80);
    final bufferedBarColor = primary.withValues(alpha: 0.4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 7),
            child: Obx(
              () => Offstage(
                offstage: !controller.showControls.value,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Obx(() {
                      final int value = controller.sliderPositionSeconds.value;
                      final int max = controller.duration.value.inSeconds;
                      final bool isDragging =
                          controller.isSliderMoving.value;
                      return AnimatedProgressBar(
                        progress: Duration(seconds: value),
                        buffered: Duration(
                          seconds: controller.bufferedSeconds.value,
                        ),
                        total: Duration(seconds: max),
                        isDragging: isDragging,
                        progressBarColor: primary,
                        baseBarColor: baseBarColor,
                        bufferedBarColor: bufferedBarColor,
                        thumbColor: primary,
                        thumbGlowColor: thumbGlowColor,
                        onDragStart: onDragStart,
                        onDragUpdate: onDragUpdate,
                        onSeek: onSeek,
                      );
                    }),
                    if (controller.enableBlock &&
                        videoDetailController.segmentProgressList.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: PlayerTokens.segmentBarBottom,
                        child: SegmentProgressBar(
                          segments: videoDetailController.segmentProgressList,
                        ),
                      ),
                    if (controller.showViewPoints &&
                        videoDetailController.viewPointList.isNotEmpty &&
                        videoDetailController.showVP.value)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: PlayerTokens.viewPointBarBottom,
                        ),
                        child: ViewPointSegmentProgressBar(
                          segments: videoDetailController.viewPointList,
                          onSeek: PlatformUtils.isDesktop
                              ? (position) =>
                                    controller.seekTo(position, isSeek: false)
                              : null,
                        ),
                      ),
                    if (videoDetailController.showDmTrendChart.value)
                      if (videoDetailController.dmTrend.value?.dataOrNull
                          case final list?)
                        buildDmChart(primary, list, videoDetailController, 4.5),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: buildBottomControl(),
          ),
        ],
      ),
    );
  }
}
