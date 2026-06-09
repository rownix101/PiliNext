import 'package:PiliNext/common/assets.dart';
import 'package:PiliNext/plugin/pl_player/controller.dart';
import 'package:PiliNext/plugin/pl_player/models/data_status.dart';
import 'package:PiliNext/plugin/pl_player/models/play_status.dart';
import 'package:PiliNext/plugin/pl_player/player_tokens.dart';
import 'package:PiliNext/utils/extension/num_ext.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Loading and error status overlay for the player.
///
/// Shows a buffering spinner when loading and an error message
/// when playback fails. Both are centered with a glass pill.
class PlayerStatusOverlay extends StatelessWidget {
  const PlayerStatusOverlay({
    super.key,
    required this.plPlayerController,
  });

  final PlPlayerController plPlayerController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final colorScheme = ColorScheme.of(context);
      if (plPlayerController.dataStatus.loading ||
          (plPlayerController.isBuffering.value &&
              plPlayerController.playerStatus.isPlaying)) {
        return _buildLoading(context, colorScheme);
      } else if (plPlayerController.dataStatus.error) {
        return _buildError(context, colorScheme);
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildLoading(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: GestureDetector(
        onTap: plPlayerController.refreshPlayer,
        child: Container(
          padding: PlayerTokens.statusContainerPadding,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(
              alpha: PlayerTokens.containerOpacity,
            ),
            borderRadius: PlayerTokens.statusContainerRadius,
            boxShadow: const [PlayerTokens.statusContainerShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                Assets.buffering,
                height: PlayerTokens.indicatorIconSize,
                cacheHeight: PlayerTokens.indicatorIconSize.toInt()
                    .cacheSize(context),
                semanticLabel: '加载中',
                color: colorScheme.primary,
              ),
              Obx(() {
                if (plPlayerController.bufferedSeconds.value == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '加载中...',
                      style: PlayerTokens.statusText(context),
                    ),
                  );
                }
                final bufferStr = plPlayerController.buffered.toString();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    bufferStr.substring(0, bufferStr.length - 3),
                    style: PlayerTokens.statusText(context),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: GestureDetector(
        onTap: plPlayerController.refreshPlayer,
        child: Container(
          padding: PlayerTokens.errorContainerPadding,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(
              alpha: PlayerTokens.containerOpacity,
            ),
            borderRadius: PlayerTokens.statusContainerRadius,
            boxShadow: const [PlayerTokens.statusContainerShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: PlayerTokens.indicatorIconSize,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '加载失败，点击重试',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
