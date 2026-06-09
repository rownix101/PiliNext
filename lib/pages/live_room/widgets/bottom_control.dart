import 'package:PiliNext/common/widgets/custom_icon.dart';
import 'package:PiliNext/pages/live_room/controller.dart';
import 'package:PiliNext/pages/video/widgets/header_mixin.dart';
import 'package:PiliNext/plugin/pl_player/controller.dart';
import 'package:PiliNext/plugin/pl_player/models/video_fit_type.dart';
import 'package:PiliNext/plugin/pl_player/player_tokens.dart';
import 'package:PiliNext/plugin/pl_player/widgets/common_btn.dart';
import 'package:PiliNext/plugin/pl_player/widgets/player_popover.dart';
import 'package:PiliNext/plugin/pl_player/widgets/play_pause_btn.dart';
import 'package:PiliNext/utils/storage.dart';
import 'package:PiliNext/utils/storage_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class BottomControl extends StatefulWidget {
  const BottomControl({
    super.key,
    required this.plPlayerController,
    required this.liveRoomCtr,
    required this.onRefresh,
    this.subTitleStyle = const TextStyle(fontSize: 12),
    this.titleStyle = const TextStyle(fontSize: 14),
  });

  final PlPlayerController plPlayerController;
  final LiveRoomController liveRoomCtr;
  final VoidCallback onRefresh;

  final TextStyle subTitleStyle;
  final TextStyle titleStyle;

  @override
  State<BottomControl> createState() => _BottomControlState();
}

class _BottomControlState extends State<BottomControl> with HeaderMixin {
  late final LiveRoomController liveRoomCtr = widget.liveRoomCtr;
  @override
  late final PlPlayerController plPlayerController = widget.plPlayerController;

  @override
  Widget build(BuildContext context) {
    final isFullScreen = plPlayerController.isFullScreen.value;
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      primary: false,
      automaticallyImplyLeading: false,
      titleSpacing: 14,
      title: Row(
        children: [
          PlayOrPauseButton(plPlayerController: plPlayerController),
          ComBtn(
            tooltip: '刷新',
            icon: const Icon(
              Icons.refresh,
              size: PlayerTokens.iconSizeSm,
              color: Colors.white,
            ),
            onTap: widget.onRefresh,
          ),
          const Spacer(),
          ComBtn(
            tooltip: '屏蔽',
            icon: const Icon(
              size: PlayerTokens.iconSizeSm,
              Icons.block,
              color: Colors.white,
            ),
            onTap: () {
              if (liveRoomCtr.isLogin) {
                Get.toNamed(
                  '/liveDmBlockPage',
                  parameters: {
                    'roomId': liveRoomCtr.roomId.toString(),
                  },
                );
              } else {
                SmartDialog.showToast('账号未登录');
              }
            },
          ),
          const SizedBox(width: 3),
          Obx(
            () {
              final enableShowLiveDanmaku =
                  plPlayerController.enableShowDanmaku.value;
              return ComBtn(
                tooltip: "${enableShowLiveDanmaku ? '关闭' : '开启'}弹幕",
                icon: enableShowLiveDanmaku
                    ? const Icon(
                        size: PlayerTokens.iconSizeSm,
                        CustomIcons.dm_on,
                        color: Colors.white,
                      )
                    : const Icon(
                        size: PlayerTokens.iconSizeSm,
                        CustomIcons.dm_off,
                        color: Colors.white,
                      ),
                onTap: () {
                  final newVal = !enableShowLiveDanmaku;
                  plPlayerController.enableShowDanmaku.value = newVal;
                  if (!plPlayerController.tempPlayerConf) {
                    GStorage.setting.put(
                      SettingBoxKey.enableShowLiveDanmaku,
                      newVal,
                    );
                  }
                },
              );
            },
          ),
          ComBtn(
            tooltip: '弹幕设置',
            icon: const Icon(
              size: PlayerTokens.iconSizeSm,
              CustomIcons.dm_settings,
              color: Colors.white,
            ),
            onTap: () => showSetDanmaku(isLive: true),
          ),
          Obx(
            () {
              final fit = plPlayerController.videoFit.value;
              return PlayerPopover<VideoFitType>.items(
                tooltip: '画面比例',
                trigger: (open) => Padding(
                  padding: PlayerTokens.popupTriggerPadding,
                  child: GestureDetector(
                    onTap: open,
                    child: Text(
                      fit.desc,
                      style: PlayerTokens.popupTrigger,
                    ),
                  ),
                ),
                selectedValue: fit,
                labelOf: (v) => v.desc,
                items: VideoFitType.values,
                onSelect: plPlayerController.toggleVideoFit,
              );
            },
          ),
          Obx(
            () {
              final currentQn = liveRoomCtr.currentQn;
              final desc = liveRoomCtr.currentQnDesc.value;
              final acceptQnList = liveRoomCtr.acceptQnList;
              return PlayerPopover.builder(
                tooltip: '画质',
                trigger: (open) => Padding(
                  padding: PlayerTokens.popupTriggerPadding,
                  child: GestureDetector(
                    onTap: open,
                    child: Text(
                      desc,
                      style: PlayerTokens.popupTrigger,
                    ),
                  ),
                ),
                builder: (ctx, close) {
                  final cs = ColorScheme.of(ctx);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: acceptQnList.map((e) {
                      final isSelected = e.code == currentQn;
                      return InkWell(
                        onTap: () {
                          close();
                          liveRoomCtr.changeQn(e.code);
                        },
                        splashColor: Colors.white.withValues(alpha: 0.08),
                        highlightColor: Colors.white.withValues(alpha: 0.04),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.desc,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: cs.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
          if (!plPlayerController.isDesktopPip)
            ComBtn(
              tooltip: isFullScreen ? '退出全屏' : '全屏',
              icon: isFullScreen
                  ? const Icon(
                      Icons.fullscreen_exit,
                      size: PlayerTokens.iconSizeLg,
                      color: Colors.white,
                    )
                  : const Icon(
                      Icons.fullscreen,
                      size: PlayerTokens.iconSizeLg,
                      color: Colors.white,
                    ),
              onTap: () =>
                  plPlayerController.triggerFullScreen(status: !isFullScreen),
              onSecondaryTap: () => plPlayerController.triggerFullScreen(
                status: !isFullScreen,
                inAppFullScreen: true,
              ),
            ),
        ],
      ),
    );
  }
}
