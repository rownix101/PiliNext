import 'dart:async' show Timer;
import 'dart:convert' show jsonDecode, utf8;
import 'dart:io' show Platform, File;
import 'dart:typed_data' show Uint8List;

import 'package:PiliNext/common/constants.dart';
import 'package:PiliNext/common/design/design_tokens.dart';
import 'package:PiliNext/common/widgets/button/icon_button.dart';
import 'package:PiliNext/common/widgets/custom_icon.dart';
import 'package:PiliNext/common/widgets/dialog/report.dart';
import 'package:PiliNext/common/widgets/marquee.dart';
import 'package:PiliNext/http/danmaku.dart';
import 'package:PiliNext/http/danmaku_block.dart';
import 'package:PiliNext/http/init.dart';
import 'package:PiliNext/http/live.dart';
import 'package:PiliNext/http/loading_state.dart';
import 'package:PiliNext/http/video.dart';
import 'package:PiliNext/models/common/super_resolution_type.dart';
import 'package:PiliNext/models/common/video/audio_quality.dart';
import 'package:PiliNext/models/common/video/cdn_type.dart';
import 'package:PiliNext/models/common/video/video_decode_type.dart';
import 'package:PiliNext/models/common/video/video_quality.dart';
import 'package:PiliNext/models/video/play/url.dart';
import 'package:PiliNext/models_new/video/video_play_info/subtitle.dart';
import 'package:PiliNext/pages/common/common_intro_controller.dart';
import 'package:PiliNext/pages/danmaku/danmaku_model.dart';
import 'package:PiliNext/pages/setting/widgets/select_dialog.dart';
import 'package:PiliNext/pages/video/controller.dart';
import 'package:PiliNext/pages/video/introduction/local/controller.dart';
import 'package:PiliNext/pages/video/introduction/pgc/controller.dart';
import 'package:PiliNext/pages/video/introduction/ugc/controller.dart';
import 'package:PiliNext/pages/video/introduction/ugc/widgets/action_item.dart';
import 'package:PiliNext/pages/video/widgets/header_mixin.dart';
import 'package:PiliNext/plugin/pl_player/controller.dart';
import 'package:PiliNext/plugin/pl_player/models/data_source.dart';
import 'package:PiliNext/plugin/pl_player/models/play_repeat.dart';
import 'package:PiliNext/plugin/pl_player/player_tokens.dart'
    show PlayerGlassStyle, PlayerTokens;
import 'package:PiliNext/plugin/pl_player/utils/danmaku_options.dart';
import 'package:PiliNext/plugin/pl_player/widgets/settings_panel.dart';
import 'package:PiliNext/services/shutdown_timer_service.dart'
    show shutdownTimerService;
import 'package:PiliNext/utils/accounts.dart';
import 'package:PiliNext/utils/accounts/account.dart';
import 'package:PiliNext/utils/android/bindings.g.dart';
import 'package:PiliNext/utils/connectivity_utils.dart';
import 'package:PiliNext/utils/extension/num_ext.dart';
import 'package:PiliNext/utils/extension/string_ext.dart';
import 'package:PiliNext/utils/image_utils.dart';
import 'package:PiliNext/utils/page_utils.dart';
import 'package:PiliNext/utils/platform_utils.dart';
import 'package:PiliNext/utils/storage.dart';
import 'package:PiliNext/utils/storage_key.dart';
import 'package:PiliNext/utils/storage_pref.dart';
import 'package:PiliNext/utils/storage_utils.dart';
import 'package:PiliNext/utils/utils.dart';
import 'package:PiliNext/utils/video_utils.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart' hide showBottomSheet;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

mixin TimeBatteryMixin<T extends StatefulWidget> on State<T> {
  PlPlayerController get plPlayerController;
  late final titleKey = GlobalKey();
  ContextSingleTicker? provider;
  ContextSingleTicker get effectiveProvider => provider ??= ContextSingleTicker(
    context,
    autoStart: () =>
        plPlayerController.showControls.value &&
        !plPlayerController.controlsLock.value,
  );

  bool get isPortrait;
  bool get isFullScreen;
  bool get horizontalScreen;

  Timer? _clock;
  RxString now = ''.obs;

  static final _format = DateFormat('HH:mm');

  @override
  void dispose() {
    stopClock();
    super.dispose();
  }

  void startClock() {
    if (!_showCurrTime) return;
    if (_clock == null) {
      now.value = _format.format(DateTime.now());
      _clock ??= Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if (!mounted) {
          stopClock();
          return;
        }
        now.value = _format.format(DateTime.now());
      });
    }
  }

  void stopClock() {
    _clock?.cancel();
    _clock = null;
  }

  bool _showCurrTime = false;
  void showCurrTimeIfNeeded(bool isFullScreen) {
    _showCurrTime = !isPortrait && (isFullScreen || !horizontalScreen);
    if (!_showCurrTime) {
      stopClock();
    }
  }

  late final _battery = Battery();
  late final RxnInt _batteryLevel = RxnInt();
  late final _showBatteryLevel = Pref.showBatteryLevel;
  void getBatteryLevelIfNeeded() {
    if (!_showCurrTime || !_showBatteryLevel) return;
    EasyThrottle.throttle(
      'getBatteryLevel$hashCode',
      const Duration(seconds: 30),
      () async {
        try {
          _batteryLevel.value = await _battery.batteryLevel;
        } catch (_) {}
      },
    );
  }

  List<Widget>? get timeBatteryWidgets {
    if (_showCurrTime) {
      return [
        if (_showBatteryLevel) ...[
          Obx(
            () {
              final batteryLevel = _batteryLevel.value;
              if (batteryLevel == null) {
                return const SizedBox.shrink();
              }
              return Text(
                '$batteryLevel%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
        Obx(
          () => Text(
            now.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ),
      ];
    }
    return null;
  }
}

class HeaderControl extends StatefulWidget {
  const HeaderControl({
    required this.isPortrait,
    required this.controller,
    required this.videoDetailCtr,
    required this.heroTag,
    super.key,
  });

  final bool isPortrait;
  final PlPlayerController controller;
  final VideoDetailController videoDetailCtr;
  final String heroTag;

  @override
  State<HeaderControl> createState() => HeaderControlState();

  static Future<bool> likeDanmaku(VideoDanmaku extra, int cid) async {
    if (!Accounts.main.isLogin) {
      SmartDialog.showToast('请先登录');
      return false;
    }
    final isLike = !extra.isLike;
    final res = await DanmakuHttp.danmakuLike(
      isLike: isLike,
      cid: cid,
      id: extra.id,
    );
    if (res.isSuccess) {
      extra.isLike = isLike;
      if (isLike) {
        extra.like++;
      } else {
        extra.like--;
      }
      SmartDialog.showToast('${isLike ? '' : '取消'}点赞成功');
      return true;
    } else {
      res.toast();
      if (res case Error(:final code)) {
        if (code == 65006) {
          extra.isLike = true;
          return true;
        }
        if (code == 65004) {
          extra.isLike = false;
          return true;
        }
      }
      return false;
    }
  }

  static Future<bool> deleteDanmaku(int id, int cid) async {
    final res = await DanmakuHttp.danmakuRecall(
      cid: cid,
      id: id,
    );
    if (res.isSuccess) {
      SmartDialog.showToast('删除成功');
      return true;
    } else {
      res.toast();
      return false;
    }
  }

  static Future<void> reportDanmaku(
    BuildContext context, {
    required VideoDanmaku extra,
    required PlPlayerController ctr,
  }) {
    if (Accounts.main.isLogin) {
      return autoWrapReportDialog(
        context,
        ReportOptions.danmakuReport,
        (reasonType, reasonDesc, banUid) {
          if (banUid) {
            final filter = ctr.filters;
            if (filter.dmUid.add(extra.mid)) {
              filter.count++;
              GStorage.localCache.put(
                LocalCacheKey.danmakuFilterRules,
                filter,
              );
            }
            DanmakuFilterHttp.danmakuFilterAdd(
              filter: extra.mid,
              type: 2,
            );
          }
          return DanmakuHttp.danmakuReport(
            reason: reasonType == 0 ? 11 : reasonType,
            cid: ctr.cid!,
            id: extra.id,
            content: reasonType == 0 ? reasonDesc : null,
          );
        },
      );
    } else {
      return SmartDialog.showToast('请先登录');
    }
  }

  static Future<void> reportLiveDanmaku(
    BuildContext context, {
    required int roomId,
    required String msg,
    required LiveDanmaku extra,
  }) {
    if (Accounts.main.isLogin) {
      return autoWrapReportDialog(
        context,
        ban: false,
        ReportOptions.liveDanmakuReport,
        (reasonType, reasonDesc, banUid) {
          // if (banUid) {
          //   final filter = ctr.filters;
          //   if (filter.dmUid.add(extra.mid)) {
          //     filter.count++;
          //     GStorage.localCache.put(
          //       LocalCacheKey.danmakuFilterRules,
          //       filter,
          //     );
          //   }
          //   DanmakuFilterHttp.danmakuFilterAdd(
          //     filter: extra.mid,
          //     type: 2,
          //   );
          // }
          return LiveHttp.liveDmReport(
            roomId: roomId,
            mid: extra.mid,
            msg: msg,
            reason: ReportOptions.liveDanmakuReport['']![reasonType]!,
            reasonId: reasonType,
            dmType: extra.dmType,
            idStr: extra.id,
            ts: extra.ts,
            sign: extra.ct,
          );
        },
      );
    } else {
      return SmartDialog.showToast('请先登录');
    }
  }
}

class HeaderControlState extends State<HeaderControl>
    with HeaderMixin, TimeBatteryMixin {
  @override
  late final PlPlayerController plPlayerController = widget.controller;
  late final VideoDetailController videoDetailCtr = widget.videoDetailCtr;
  late final PlayUrlModel videoInfo = videoDetailCtr.data;
  static const TextStyle subTitleStyle = TextStyle(fontSize: 12);
  static const TextStyle titleStyle = TextStyle(fontSize: 14);

  String get heroTag => widget.heroTag;
  late final UgcIntroController ugcIntroController;
  late final PgcIntroController pgcIntroController;
  late final LocalIntroController localIntroController;
  late CommonIntroController introController = isFileSource
      ? localIntroController
      : videoDetailCtr.isUgc
      ? ugcIntroController
      : pgcIntroController;

  @override
  bool get isPortrait => widget.isPortrait;
  @override
  late final horizontalScreen = videoDetailCtr.horizontalScreen;

  Box setting = GStorage.setting;

  @override
  void initState() {
    super.initState();
    if (isFileSource) {
      introController = Get.find<LocalIntroController>(tag: heroTag);
    } else if (videoDetailCtr.isUgc) {
      introController = Get.find<UgcIntroController>(tag: heroTag);
    } else {
      introController = Get.find<PgcIntroController>(tag: heroTag);
    }
  }

  /// 获取当前播放器区域的 Size（用于右侧面板定位）。
  Size get _playerSize {
    final ctx = context;
    final box = ctx.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      // AppBar 本身很小，向上走到真正的播放器容器尺寸。
      // 我们用屏幕尺寸作为保守估计，面板本身 Positioned 在 Overlay 内。
    }
    final mq = MediaQuery.sizeOf(ctx);
    return mq;
  }

  /// 设置面板
  ///
  /// 全屏（横屏）时：YouTube 风格右侧滑出玻璃面板。
  /// 竖屏 / 非全屏时：沿用现有 bottom sheet。
  void showSettingSheet() {
    _showGlassSettingsPanel();
  }

  /// YouTube-style right-side glass panel（全屏模式）
  void _showGlassSettingsPanel() {
    late final OverlayEntry entry;
    void dismiss() {
      if (entry.mounted) entry.remove();
    }

    final tiles = _buildSettingsTiles(dismiss);
    entry = OverlayEntry(
      builder: (_) => GlassSettingsPanel(
        playerSize: _playerSize,
        rootTitle: '设置',
        rootTiles: tiles,
        onDismissed: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  /// Builds the flat list of [SettingsTile] entries for the glass panel.
  List<SettingsTile> _buildSettingsTiles(VoidCallback dismiss) {
    return [
      // ── 稍后再看 ────────────────────────────────────────────────────────────
      ActionTile(
        icon: const Icon(Icons.watch_later_outlined),
        title: '添加至「稍后再看」',
        onTap: () {
          dismiss();
          introController.viewLater();
        },
      ),

      // ── 查看笔记 ─────────────────────────────────────────────────────────────
      if (videoDetailCtr.epId == null)
        ActionTile(
          icon: const Icon(Icons.note_alt_outlined),
          title: '查看笔记',
          onTap: () {
            dismiss();
            videoDetailCtr.showNoteList(context);
          },
        ),

      // ── 离线缓存 ─────────────────────────────────────────────────────────────
      if (!isFileSource)
        ActionTile(
          icon: const Icon(MdiIcons.folderDownloadOutline),
          title: '离线缓存',
          onTap: () {
            dismiss();
            videoDetailCtr.onDownload(context);
          },
        ),

      // ── 保存封面 ─────────────────────────────────────────────────────────────
      if (widget.videoDetailCtr.cover.value.isNotEmpty)
        ActionTile(
          icon: const Icon(Icons.image_outlined),
          title: '保存封面',
          onTap: () {
            dismiss();
            ImageUtils.downloadImg([widget.videoDetailCtr.cover.value]);
          },
        ),

      // ── 定时关闭 ─────────────────────────────────────────────────────────────
      ActionTile(
        icon: const Icon(Icons.hourglass_top_outlined),
        title: '定时关闭',
        onTap: () {
          dismiss();
          shutdownTimerService.showScheduleExitDialog(
            context,
            isFullScreen: isFullScreen,
          );
        },
      ),

      // ── 播放地址 / 重载 ────────────────────────────────────────────────────────
      if (!isFileSource) ...[
        ActionTile(
          icon: const Icon(Icons.link),
          title: '播放地址',
          onTap: () {
            dismiss();
            videoDetailCtr.editPlayUrl();
          },
        ),
        ActionTile(
          icon: const Icon(Icons.refresh_outlined),
          title: '重载视频',
          onTap: () {
            dismiss();
            videoDetailCtr.queryVideoUrl(
              defaultST: videoDetailCtr.playedTime,
              fromReset: true,
            );
          },
        ),
      ],

      // ── 超分辨率 ──────────────────────────────────────────────────────────────
      SelectionTile<SuperResolutionType>(
        icon: const Icon(Icons.stay_current_landscape_outlined),
        title: '超分辨率',
        getValue: () => plPlayerController.superResolutionType.value,
        labelOf: (v) => v.label,
        items: SuperResolutionType.values,
        onSelect: (v, pop) {
          plPlayerController.setShader(v);
          pop();
        },
      ),

      // ── CDN 设置 ──────────────────────────────────────────────────────────────
      if (!isFileSource)
        ActionTile(
          icon: const Icon(MdiIcons.cloudPlusOutline),
          title: 'CDN 设置',
          subtitle: '当前：${VideoUtils.cdnService.desc}',
          onTap: () async {
            dismiss();
            final result = await showDialog<CDNService>(
              context: context,
              builder: (context) =>
                  CdnSelectDialog(sample: videoInfo.dash?.video?.firstOrNull),
            );
            if (result != null) {
              VideoUtils.cdnService = result;
              setting.put(SettingBoxKey.CDNService, result.name);
              SmartDialog.showToast('已设置为 ${result.desc}，正在重载视频');
              videoDetailCtr.queryVideoUrl(
                defaultST: videoDetailCtr.playedTime,
                fromReset: true,
              );
            }
          },
        ),

      // ── 画质 ──────────────────────────────────────────────────────────────────
      if (!isFileSource && videoDetailCtr.currentVideoQa.value != null)
        CustomSubPageTile(
          icon: const Icon(Icons.hd_outlined),
          title: '选择画质',
          trailing: '当前 ${videoDetailCtr.currentVideoQa.value?.desc}',
          subPageBuilder: (nav) => _buildVideoQaList(nav, dismiss),
        ),

      // ── 音质 ──────────────────────────────────────────────────────────────────
      if (!isFileSource && videoDetailCtr.currentAudioQa != null)
        CustomSubPageTile(
          icon: const Icon(Icons.album_outlined),
          title: '选择音质',
          trailing: '当前 ${videoDetailCtr.currentAudioQa!.desc}',
          subPageBuilder: (nav) => _buildAudioQaList(nav, dismiss),
        ),

      // ── 解码格式 ──────────────────────────────────────────────────────────────
      if (!isFileSource)
        CustomSubPageTile(
          icon: const Icon(Icons.av_timer_outlined),
          title: '解码格式',
          trailing: videoDetailCtr.currentDecodeFormats.description,
          subPageBuilder: (nav) => _buildDecodeFormatsList(nav, dismiss),
        ),

      // ── 播放顺序 ──────────────────────────────────────────────────────────────
      SelectionTile<PlayRepeat>(
        icon: const Icon(Icons.repeat),
        title: '播放顺序',
        getValue: () => plPlayerController.playRepeat,
        labelOf: (v) => v.label,
        items: PlayRepeat.values,
        onSelect: (v, pop) {
          plPlayerController.setPlayRepeat(v);
          pop();
        },
      ),

      // ── 弹幕列表 ──────────────────────────────────────────────────────────────
      CustomSubPageTile(
        icon: const Icon(CustomIcons.dm_on),
        title: '弹幕列表',
        trailing: null,
        subPageBuilder: _buildDanmakuPoolPage,
      ),

      // ── 弹幕设置 ──────────────────────────────────────────────────────────────
      CustomSubPageTile(
        icon: const Icon(CustomIcons.dm_settings),
        title: '弹幕设置',
        trailing: null,
        subPageBuilder: _buildDanmakuSettingsPage,
      ),

      // ── 字幕设置 ──────────────────────────────────────────────────────────────
      CustomSubPageTile(
        icon: const Icon(Icons.subtitles_outlined),
        title: '字幕设置',
        trailing: null,
        subPageBuilder: (nav) => SettingsSubPageScaffold(
          title: '字幕设置',
          nav: nav,
          child: _SubtitleSettingsContent(
            controller: plPlayerController,
          ),
        ),
      ),

      // ── 加载字幕 ──────────────────────────────────────────────────────────────
      if (!videoDetailCtr.isFileSource)
        ActionTile(
          icon: const Icon(Icons.file_upload_outlined),
          title: '加载字幕',
          onTap: () {
            dismiss();
            _loadSubtitleFile();
          },
        ),

      // ── 左右翻转 ──────────────────────────────────────────────────────────────
      ActionTile(
        icon: const Icon(Icons.flip),
        title: '左右翻转',
        onTap: () {
          dismiss();
          plPlayerController.flipX.value = !plPlayerController.flipX.value;
        },
      ),

      // ── 上下翻转 ──────────────────────────────────────────────────────────────
      ActionTile(
        icon: const Icon(CustomIcons.flip_rotate_90),
        title: '上下翻转',
        onTap: () {
          dismiss();
          plPlayerController.flipY.value = !plPlayerController.flipY.value;
        },
      ),

      // ── 听视频 ────────────────────────────────────────────────────────────────
      if ((isFileSource &&
              !(plPlayerController.dataSource as FileSource).isMp4) ||
          (!isFileSource && videoDetailCtr.audioUrl?.isNotEmpty == true))
        ActionTile(
          icon: const Icon(Icons.headphones),
          title: '听视频',
          onTap: () {
            dismiss();
            plPlayerController.onlyPlayAudio.value =
                !plPlayerController.onlyPlayAudio.value;
            widget.videoDetailCtr.playerInit();
          },
        ),

      // ── 玻璃材质 ─────────────────────────────────────────────────────────
      SelectionTile<PlayerGlassStyle>(
        icon: const Icon(Icons.blur_on_outlined),
        title: '玻璃材质',
        getValue: () {
          final idx = GStorage.setting.get(
            SettingBoxKey.playerGlassStyle,
            defaultValue: PlayerGlassStyle.liquidGlass.index,
          );
          return PlayerGlassStyle.values[idx.clamp(
            0,
            PlayerGlassStyle.values.length - 1,
          )];
        },
        labelOf: (v) => switch (v) {
          PlayerGlassStyle.transparent => '透明',
          PlayerGlassStyle.frostedGlass => '毛玻璃',
          PlayerGlassStyle.liquidGlass => '液态玻璃',
        },
        items: PlayerGlassStyle.values,
        onSelect: (v, pop) {
          GStorage.setting.put(SettingBoxKey.playerGlassStyle, v.index);
          pop();
        },
      ),

      // ── 后台播放 ──────────────────────────────────────────────────────────────
      if (PlatformUtils.isMobile)
        ActionTile(
          icon: const Icon(Icons.phone_android_outlined),
          title: '后台播放',
          onTap: () {
            dismiss();
            plPlayerController.setContinuePlayInBackground();
          },
        ),

      // ── 保存字幕 ──────────────────────────────────────────────────────────────
      if (!videoDetailCtr.isFileSource && videoDetailCtr.subtitles.isNotEmpty)
        ActionTile(
          icon: const Icon(Icons.download_outlined),
          title: '保存字幕',
          onTap: () {
            dismiss();
            onExportSubtitle();
          },
        ),

      // ── 播放信息 ──────────────────────────────────────────────────────────────
      ActionTile(
        icon: const Icon(Icons.info_outline),
        title: '播放信息',
        onTap: () => showPlayerInfo(
          context,
          plPlayerController: plPlayerController,
        ),
      ),

      // ── 举报 ──────────────────────────────────────────────────────────────────
      ActionTile(
        icon: const Icon(Icons.error_outline),
        title: '举报',
        onTap: () {
          if (!Accounts.main.isLogin) {
            SmartDialog.showToast('账号未登录');
            return;
          }
          dismiss();
          PageUtils.reportVideo(videoDetailCtr.aid);
        },
      ),
    ];
  }

  // ─── Glass sub-page builders ────────────────────────────────────────────────

  Widget _buildVideoQaList(SettingsPanelNavController nav, VoidCallback dismiss) {
    if (videoInfo.dash == null) {
      return SettingsSubPageScaffold(
        title: '选择画质',
        nav: nav,
        child: const Center(
          child: Text(
            '当前视频不支持选择画质',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      );
    }
    final VideoQuality? currentVideoQa = videoDetailCtr.currentVideoQa.value;
    if (currentVideoQa == null) {
      return SettingsSubPageScaffold(
        title: '选择画质',
        nav: nav,
        child: const SizedBox.shrink(),
      );
    }
    final List<FormatItem> videoFormat = videoInfo.supportFormats!;
    final List<VideoItem> video = videoInfo.dash!.video!;
    final Set<int> idSet = {};
    for (final VideoItem item in video) {
      idSet.add(item.id!);
    }
    final int usefulQaSam = idSet.length;

    return SettingsSubPageScaffold(
      title: '选择画质',
      nav: nav,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: videoFormat.length,
        itemBuilder: (_, i) {
          final item = videoFormat[i];
          final isCurr = currentVideoQa.code == item.quality;
          final enabled = i >= videoFormat.length - usefulQaSam;
          return _GlassSelectionTile(
            label: item.newDesc!,
            subtitle: item.format,
            isSelected: isCurr,
            enabled: enabled,
            onTap: enabled && !isCurr
                ? () async {
                    dismiss();
                    final int quality = item.quality!;
                    final newQa = VideoQuality.fromCode(quality);
                    videoDetailCtr
                      ..plPlayerController.cacheVideoQa = newQa.code
                      ..currentVideoQa.value = newQa
                      ..updatePlayer();
                    SmartDialog.showToast("画质已变为：${newQa.desc}");
                    if (!plPlayerController.tempPlayerConf) {
                      final isWifi = await ConnectivityUtils.isWiFi;
                      setting.put(
                        isWifi
                            ? SettingBoxKey.defaultVideoQa
                            : SettingBoxKey.defaultVideoQaCellular,
                        quality,
                      );
                    }
                  }
                : null,
          );
        },
      ),
    );
  }

  Widget _buildAudioQaList(SettingsPanelNavController nav, VoidCallback dismiss) {
    final AudioQuality currentAudioQa = videoDetailCtr.currentAudioQa!;
    final List<AudioItem> audio = videoInfo.dash!.audio!;

    return SettingsSubPageScaffold(
      title: '选择音质',
      nav: nav,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: audio.length,
        itemBuilder: (_, i) {
          final item = audio[i];
          final isCurr = currentAudioQa.code == item.id;
          return _GlassSelectionTile(
            label: item.quality!,
            subtitle: item.codecs,
            isSelected: isCurr,
            enabled: true,
            onTap: isCurr
                ? null
                : () async {
                    dismiss();
                    final int quality = item.id!;
                    final newQa = AudioQuality.fromCode(quality);
                    videoDetailCtr
                      ..plPlayerController.cacheAudioQa = newQa.code
                      ..currentAudioQa = newQa
                      ..updatePlayer();
                    SmartDialog.showToast("音质已变为：${newQa.desc}");
                    if (!plPlayerController.tempPlayerConf) {
                      final isWifi = await ConnectivityUtils.isWiFi;
                      setting.put(
                        isWifi
                            ? SettingBoxKey.defaultAudioQa
                            : SettingBoxKey.defaultAudioQaCellular,
                        quality,
                      );
                    }
                  },
          );
        },
      ),
    );
  }

  Widget _buildDecodeFormatsList(
      SettingsPanelNavController nav, VoidCallback dismiss) {
    final VideoItem firstVideo = videoDetailCtr.firstVideo;
    final List<FormatItem> videoFormat = videoInfo.supportFormats!;
    final List<String>? list = videoFormat
        .firstWhere((FormatItem e) => e.quality == firstVideo.quality.code)
        .codecs;
    if (list == null) {
      return SettingsSubPageScaffold(
        title: '解码格式',
        nav: nav,
        child: const Center(
          child: Text(
            '当前视频不支持选择解码格式',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      );
    }
    final VideoDecodeFormatType currentDecodeFormats =
        videoDetailCtr.currentDecodeFormats;

    return SettingsSubPageScaffold(
      title: '解码格式',
      nav: nav,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final item = list[i];
          final format = VideoDecodeFormatType.fromString(item);
          final isCurr = currentDecodeFormats.codes.any(item.startsWith);
          return _GlassSelectionTile(
            label: format.description,
            subtitle: item,
            isSelected: isCurr,
            enabled: true,
            onTap: isCurr
                ? null
                : () {
                    dismiss();
                    videoDetailCtr
                      ..currentDecodeFormats = format
                      ..updatePlayer();
                  },
          );
        },
      ),
    );
  }

  Widget _buildDanmakuPoolPage(SettingsPanelNavController nav) {
    final ctr = plPlayerController.danmakuController;
    if (ctr == null) {
      return SettingsSubPageScaffold(
        title: '弹幕列表',
        nav: nav,
        child: const SizedBox.shrink(),
      );
    }

    return SettingsSubPageScaffold(
      title: '弹幕列表',
      nav: nav,
      child: _DanmakuPoolContent(
        danmakuController: ctr,
        plPlayerController: plPlayerController,
        onLikeDanmaku: (extra) async {
          if (plPlayerController.cid != null) {
            final ok = await HeaderControl.likeDanmaku(
              extra,
              plPlayerController.cid!,
            );
            return ok;
          }
          return false;
        },
        onDeleteDanmaku: (id) async {
          if (plPlayerController.cid != null) {
            await HeaderControl.deleteDanmaku(id, plPlayerController.cid!);
          }
        },
        onReportDanmaku: (extra) {
          HeaderControl.reportDanmaku(
            context,
            extra: extra,
            ctr: plPlayerController,
          );
        },
      ),
    );
  }

  Widget _buildDanmakuSettingsPage(SettingsPanelNavController nav) {
    final danmakuController = plPlayerController.danmakuController;
    return SettingsSubPageScaffold(
      title: '弹幕设置',
      nav: nav,
      child: _DanmakuSettingsContent(
        plPlayerController: plPlayerController,
        danmakuController: danmakuController,
        isFullScreen: isFullScreen,
      ),
    );
  }

  Future<void> _loadSubtitleFile() async {
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['json', 'vtt', 'srt', 'ass'],
      );
      if (result != null) {
        final file = result.xFile;
        final path = file.path;
        final name = file.name;
        final length = videoDetailCtr.subtitles.length;
        if (name.endsWith('.json')) {
          final file = File(path);
          final stream = file.openRead().transform(utf8.decoder);
          final buffer = StringBuffer();
          await for (final chunk in stream) {
            if (!mounted) return;
            buffer.write(chunk);
          }
          if (!mounted) return;
          String sub = buffer.toString();
          sub = await compute<List, String>(
            VideoHttp.processList,
            jsonDecode(sub)['body'],
          );
          if (!mounted) return;
          videoDetailCtr.vttSubtitles[length] = (isData: true, id: sub);
        } else {
          videoDetailCtr.vttSubtitles[length] = (isData: false, id: path);
        }
        videoDetailCtr.subtitles.add(
          Subtitle(lan: '', lanDoc: name.split('.').firstOrNull ?? name),
        );
        await videoDetailCtr.setSubtitle(length + 1);
      }
    } catch (e) {
      SmartDialog.showToast('加载失败: $e');
    }
  }

  static void showPlayerInfo(
    BuildContext context, {
    required PlPlayerController plPlayerController,
  }) {
    final player = plPlayerController.videoPlayerController;
    if (player == null) {
      SmartDialog.showToast('播放器未初始化');
      return;
    }
    final hwdec = player.getProperty('hwdec-current');
    showDialog(
      context: context,
      builder: (context) {
        final state = player.state;
        final colorScheme = ColorScheme.of(context);
        return AlertDialog(
          title: const Text('播放信息'),
          contentPadding: const EdgeInsets.only(top: 16),
          content: Material(
            type: MaterialType.transparency,
            child: ListTileTheme(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      title: const Text("Resolution"),
                      subtitle: Text(
                        '${state.width}x${state.height}',
                      ),
                      onTap: () => Utils.copyText(
                        'Resolution\n${state.width}x${state.height}',
                      ),
                    ),
                    ListTile(
                      dense: true,
                      title: const Text("VideoParams"),
                      subtitle: Text(
                        state.videoParams.toString(),
                      ),
                      onTap: () => Utils.copyText(
                        'VideoParams\n${state.videoParams}',
                      ),
                    ),
                    ListTile(
                      dense: true,
                      title: const Text("AudioParams"),
                      subtitle: Text(
                        state.audioParams.toString(),
                      ),
                      onTap: () => Utils.copyText(
                        'AudioParams\n${state.audioParams}',
                      ),
                    ),
                    ListTile(
                      dense: true,
                      title: const Text("Media"),
                      subtitle: Text(
                        state.playlist.toString(),
                      ),
                      onTap: () => Utils.copyText(
                        'Media\n${state.playlist}',
                      ),
                    ),
                    ListTile(
                      dense: true,
                      title: const Text("AudioTrack"),
                      subtitle: Text(
                        state.track.audio.toString(),
                      ),
                      onTap: () => Utils.copyText(
                        'AudioTrack\n${state.track.audio}',
                      ),
                    ),
                    ListTile(
                      dense: true,
                      title: const Text("VideoTrack"),
                      subtitle: Text(
                        state.track.video.toString(),
                      ),
                      onTap: () => Utils.copyText(
                        'VideoTrack\n${state.track.audio}',
                      ),
                    ),
                    ListTile(
                      dense: true,
                      title: const Text("pitch"),
                      subtitle: Text(state.pitch.toString()),
                      onTap: () => Utils.copyText(
                        'pitch\n${state.pitch}',
                      ),
                    ),
                    ListTile(
                      dense: true,
                      title: const Text("rate"),
                      subtitle: Text(state.rate.toString()),
                      onTap: () => Utils.copyText('rate\n${state.rate}'),
                    ),
                    ListTile(
                      dense: true,
                      title: const Text("Volume"),
                      subtitle: Text(
                        state.volume.toString(),
                      ),
                      onTap: () => Utils.copyText(
                        'Volume\n${state.volume}',
                      ),
                    ),
                    ListTile(
                      dense: true,
                      title: const Text('hwdec'),
                      subtitle: Text(hwdec),
                      onTap: () => Utils.copyText('hwdec\n$hwdec'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: Get.back,
              child: Text(
                '确定',
                style: TextStyle(color: colorScheme.outline),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 选择画质
  void showSetVideoQa() {
    if (videoInfo.dash == null) {
      SmartDialog.showToast('当前视频不支持选择画质');
      return;
    }
    final VideoQuality? currentVideoQa = videoDetailCtr.currentVideoQa.value;
    if (currentVideoQa == null) return;

    final List<FormatItem> videoFormat = videoInfo.supportFormats!;

    /// 总质量分类
    final int totalQaSam = videoFormat.length;

    /// 可用的质量分类
    int usefulQaSam = 0;
    final List<VideoItem> video = videoInfo.dash!.video!;
    final Set<int> idSet = {};
    for (final VideoItem item in video) {
      final int id = item.id!;
      if (!idSet.contains(id)) {
        idSet.add(id);
        usefulQaSam++;
      }
    }

    showBottomSheet(
      (context, setState) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            clipBehavior: Clip.hardEdge,
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 45,
                    child: GestureDetector(
                      onTap: () => SmartDialog.showToast(
                        '标灰画质需要bilibili会员（已是会员？请关闭无痕模式）；4k和杜比视界播放效果可能不佳',
                      ),
                      child: Row(
                        spacing: 8,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('选择画质', style: titleStyle),
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: theme.colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: totalQaSam,
                  itemBuilder: (context, index) {
                    final item = videoFormat[index];
                    final isCurr = currentVideoQa.code == item.quality;
                    return ListTile(
                      dense: true,
                      onTap: () async {
                        if (isCurr) {
                          return;
                        }
                        Get.back();
                        final int quality = item.quality!;
                        final newQa = VideoQuality.fromCode(quality);
                        videoDetailCtr
                          ..plPlayerController.cacheVideoQa = newQa.code
                          ..currentVideoQa.value = newQa
                          ..updatePlayer();

                        SmartDialog.showToast("画质已变为：${newQa.desc}");

                        // update
                        if (!plPlayerController.tempPlayerConf) {
                          setting.put(
                            await ConnectivityUtils.isWiFi
                                ? SettingBoxKey.defaultVideoQa
                                : SettingBoxKey.defaultVideoQaCellular,
                            quality,
                          );
                        }
                      },
                      // 可能包含会员解锁画质
                      enabled: index >= totalQaSam - usefulQaSam,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      title: Text(item.newDesc!),
                      trailing: isCurr
                          ? Icon(
                              Icons.done,
                              color: theme.colorScheme.primary,
                            )
                          : Text(
                              item.format!,
                              style: subTitleStyle,
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 选择音质
  void showSetAudioQa() {
    final AudioQuality currentAudioQa = videoDetailCtr.currentAudioQa!;
    final List<AudioItem> audio = videoInfo.dash!.audio!;
    showBottomSheet(
      (context, setState) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            clipBehavior: Clip.hardEdge,
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 45,
                    child: Center(
                      child: Text('选择音质', style: titleStyle),
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: audio.length,
                  itemBuilder: (context, index) {
                    final item = audio[index];
                    final isCurr = currentAudioQa.code == item.id;
                    return ListTile(
                      dense: true,
                      onTap: () async {
                        if (isCurr) {
                          return;
                        }
                        Get.back();
                        final int quality = item.id!;
                        final newQa = AudioQuality.fromCode(quality);
                        videoDetailCtr
                          ..plPlayerController.cacheAudioQa = newQa.code
                          ..currentAudioQa = newQa
                          ..updatePlayer();

                        SmartDialog.showToast("音质已变为：${newQa.desc}");

                        // update
                        if (!plPlayerController.tempPlayerConf) {
                          setting.put(
                            await ConnectivityUtils.isWiFi
                                ? SettingBoxKey.defaultAudioQa
                                : SettingBoxKey.defaultAudioQaCellular,
                            quality,
                          );
                        }
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      title: Text(item.quality),
                      subtitle: Text(
                        item.codecs!,
                        style: subTitleStyle,
                      ),
                      trailing: isCurr
                          ? Icon(
                              Icons.done,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 选择解码格式
  void showSetDecodeFormats() {
    final VideoItem firstVideo = videoDetailCtr.firstVideo;
    // 当前视频可用的解码格式
    final List<FormatItem> videoFormat = videoInfo.supportFormats!;
    final List<String>? list = videoFormat
        .firstWhere((FormatItem e) => e.quality == firstVideo.quality.code)
        .codecs;
    if (list == null) {
      SmartDialog.showToast('当前视频不支持选择解码格式');
      return;
    }

    // 当前选中的解码格式
    final VideoDecodeFormatType currentDecodeFormats =
        videoDetailCtr.currentDecodeFormats;
    showBottomSheet(
      (context, setState) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            clipBehavior: Clip.hardEdge,
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: Column(
              children: [
                const SizedBox(
                  height: 45,
                  child: Center(
                    child: Text('选择解码格式', style: titleStyle),
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverList.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final format = VideoDecodeFormatType.fromString(item);
                          final isCurr = currentDecodeFormats.codes.any(
                            item.startsWith,
                          );
                          return ListTile(
                            dense: true,
                            onTap: () {
                              if (isCurr) {
                                return;
                              }
                              Get.back();
                              videoDetailCtr
                                ..currentDecodeFormats = format
                                ..updatePlayer();
                            },
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            title: Text(format.description),
                            subtitle: Text(item, style: subTitleStyle),
                            trailing: isCurr
                                ? Icon(
                                    Icons.done,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void onExportSubtitle() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        clipBehavior: Clip.hardEdge,
        contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
        title: const Text('保存字幕'),
        content: SingleChildScrollView(
          child: Column(
            children: videoDetailCtr.subtitles
                .map(
                  (item) => ListTile(
                    dense: true,
                    onTap: () async {
                      Get.back();
                      final url = item.subtitleUrl;
                      if (url == null || url.isEmpty) return;
                      try {
                        final res = await Request.dio.get<Uint8List>(
                          url.http2https,
                          options: Options(
                            responseType: ResponseType.bytes,
                            headers: Constants.baseHeaders,
                            extra: {'account': const NoAccount()},
                          ),
                        );
                        if (res.statusCode == 200) {
                          final bytes = Uint8List.fromList(
                            Request.responseBytesDecoder(
                              res.data!,
                              res.headers.map,
                            ),
                          );
                          String name =
                              '${introController.videoDetail.value.title}-${videoDetailCtr.bvid}-${videoDetailCtr.cid.value}-${item.lanDoc}.json';
                          if (Platform.isWindows) {
                            // Reserved characters may not be used in file names. See: https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file#naming-conventions
                            name = name.replaceAll(
                              RegExp(r'[<>:/\\|?*"]'),
                              '',
                            );
                          }
                          StorageUtils.saveBytes2File(
                            name: name,
                            bytes: bytes,
                            allowedExtensions: const ['json'],
                          );
                        }
                      } catch (e, s) {
                        Utils.reportError(e, s);
                        SmartDialog.showToast(e.toString());
                      }
                    },
                    title: Text(
                      item.lanDoc!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  double get subtitleFontScale => plPlayerController.subtitleFontScale;
  double get subtitleFontScaleFS => plPlayerController.subtitleFontScaleFS;
  int get subtitlePaddingH => plPlayerController.subtitlePaddingH;
  int get subtitlePaddingB => plPlayerController.subtitlePaddingB;
  double get subtitleBgOpacity => plPlayerController.subtitleBgOpacity;
  double get subtitleStrokeWidth => plPlayerController.subtitleStrokeWidth;
  int get subtitleFontWeight => plPlayerController.subtitleFontWeight;

  /// 字幕设置
  void showSetSubtitle() {
    showBottomSheet(
      padding: () => isFullScreen ? const .only(bottom: 70) : .zero,
      (context, setState) {
        final theme = Theme.of(context);

        final sliderTheme = SliderThemeData(
          trackHeight: 10,
          trackShape: const MSliderTrackShape(),
          thumbColor: theme.colorScheme.primary,
          activeTrackColor: theme.colorScheme.primary,
          inactiveTrackColor: theme.colorScheme.onInverseSurface,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
        );

        void updateStrokeWidth(double val) {
          plPlayerController
            ..subtitleStrokeWidth = val
            ..updateSubtitleStyle();
          setState(() {});
        }

        void updateOpacity(double val) {
          plPlayerController
            ..subtitleBgOpacity = val.toPrecision(2)
            ..updateSubtitleStyle();
          setState(() {});
        }

        void updateBottomPadding(double val) {
          plPlayerController
            ..subtitlePaddingB = val.round()
            ..updateSubtitleStyle();
          setState(() {});
        }

        void updateHorizontalPadding(double val) {
          plPlayerController
            ..subtitlePaddingH = val.round()
            ..updateSubtitleStyle();
          setState(() {});
        }

        void updateFontScaleFS(double val) {
          plPlayerController
            ..subtitleFontScaleFS = val
            ..updateSubtitleStyle();
          setState(() {});
        }

        void updateFontScale(double val) {
          plPlayerController
            ..subtitleFontScale = val
            ..updateSubtitleStyle();
          setState(() {});
        }

        void updateFontWeight(double val) {
          plPlayerController
            ..subtitleFontWeight = val.toInt()
            ..updateSubtitleStyle();
          setState(() {});
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            clipBehavior: Clip.hardEdge,
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(
                    height: 45,
                    child: Center(child: Text('字幕设置', style: titleStyle)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '字体大小 ${(subtitleFontScale * 100).toStringAsFixed(1)}%',
                      ),
                      resetBtn(theme, '100.0%', () => updateFontScale(1.0)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0.5,
                        max: 2.5,
                        value: subtitleFontScale,
                        divisions: 20,
                        label:
                            '${(subtitleFontScale * 100).toStringAsFixed(1)}%',
                        onChanged: updateFontScale,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '全屏字体大小 ${(subtitleFontScaleFS * 100).toStringAsFixed(1)}%',
                      ),
                      resetBtn(theme, '150.0%', () => updateFontScaleFS(1.5)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0.5,
                        max: 2.5,
                        value: subtitleFontScaleFS,
                        divisions: 20,
                        label:
                            '${(subtitleFontScaleFS * 100).toStringAsFixed(1)}%',
                        onChanged: updateFontScaleFS,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('字体粗细 ${subtitleFontWeight + 1}（可能无法精确调节）'),
                      resetBtn(theme, 6, () => updateFontWeight(5)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0,
                        max: 8,
                        value: subtitleFontWeight.toDouble(),
                        divisions: 8,
                        label: '${subtitleFontWeight + 1}',
                        onChanged: updateFontWeight,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('描边粗细 $subtitleStrokeWidth'),
                      resetBtn(theme, 2.0, () => updateStrokeWidth(2.0)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0,
                        max: 5,
                        value: subtitleStrokeWidth,
                        divisions: 10,
                        label: '$subtitleStrokeWidth',
                        onChanged: updateStrokeWidth,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('左右边距 $subtitlePaddingH'),
                      resetBtn(theme, 24, () => updateHorizontalPadding(24)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0,
                        max: 100,
                        value: subtitlePaddingH.toDouble(),
                        divisions: 100,
                        label: '$subtitlePaddingH',
                        onChanged: updateHorizontalPadding,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('底部边距 $subtitlePaddingB'),
                      resetBtn(theme, 24, () => updateBottomPadding(24)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0,
                        max: 200,
                        value: subtitlePaddingB.toDouble(),
                        divisions: 200,
                        label: '$subtitlePaddingB',
                        onChanged: updateBottomPadding,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('背景不透明度 ${(subtitleBgOpacity * 100).toInt()}%'),
                      resetBtn(theme, '67%', () => updateOpacity(0.67)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0,
                        max: 1,
                        value: subtitleBgOpacity,
                        onChanged: updateOpacity,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    )?.whenComplete(plPlayerController.putSubtitleSettings);
  }

  void showDanmakuPool() {
    final ctr = plPlayerController.danmakuController;
    if (ctr == null) return;
    showBottomSheet((context, setState) {
      final theme = Theme.of(context);
      return Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Column(
          children: [
            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('弹幕列表'),
                  iconButton(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Material(
                type: .transparency,
                clipBehavior: .hardEdge,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                child: CustomScrollView(
                  slivers: [
                    ?_buildDanmakuList(ctr.staticDanmaku.nonNulls.toList()),
                    ?_buildDanmakuList(
                      ctr.scrollDanmaku.expand((e) => e).toList(),
                    ),
                    ?_buildDanmakuList(ctr.specialDanmaku.toList()),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget? _buildDanmakuList(List<DanmakuItem<DanmakuExtra>> list) {
    if (list.isEmpty) return null;

    return SliverList.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final extra = item.content.extra! as VideoDanmaku;
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          onLongPress: () => Utils.copyText(item.content.text),
          title: Text(
            item.content.text,
            style: const TextStyle(fontSize: 14),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (context) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    iconButton(
                      onPressed: () async {
                        if (await HeaderControl.likeDanmaku(
                              extra,
                              plPlayerController.cid!,
                            ) &&
                            context.mounted) {
                          (context as Element).markNeedsBuild();
                        }
                      },
                      icon: extra.isLike
                          ? const Icon(CustomIcons.player_dm_tip_like_solid)
                          : const Icon(CustomIcons.player_dm_tip_like),
                    ),
                    if (extra.like > 0)
                      Positioned(
                        left: 24.5,
                        top: 1.5,
                        child: Text(
                          extra.like.toString(),
                          style: const TextStyle(
                            fontSize: 10.5,
                            letterSpacing: 0,
                            // fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (item.content.selfSend)
                iconButton(
                  onPressed: () => HeaderControl.deleteDanmaku(
                    extra.id,
                    plPlayerController.cid!,
                  ).then((_) => item.expired = true),
                  icon: const Icon(CustomIcons.player_dm_tip_recall),
                )
              else
                iconButton(
                  onPressed: () => HeaderControl.reportDanmaku(
                    context,
                    extra: extra,
                    ctr: plPlayerController,
                  ),
                  icon: const Icon(CustomIcons.player_dm_tip_back),
                ),
            ],
          ),
        );
      },
    );
  }

  late final isFileSource = videoDetailCtr.isFileSource;

  @override
  Widget build(BuildContext context) {
    final isFullScreen = this.isFullScreen;
    final isFSOrPip = isFullScreen || plPlayerController.isDesktopPip;
    final showFSActionItem =
        !isFileSource && plPlayerController.showFSActionItem && isFSOrPip;
    showCurrTimeIfNeeded(isFullScreen);
    Widget title;
    if (introController.videoDetail.value.title != null &&
        (isFullScreen ||
            ((!horizontalScreen || plPlayerController.isDesktopPip) &&
                !isPortrait))) {
      title = Padding(
        key: titleKey,
        padding: isPortrait
            ? EdgeInsets.zero
            : const EdgeInsets.only(right: 10),
        child: Obx(
          () {
            final videoDetail = introController.videoDetail.value;
            final String title;
            if (isFileSource || videoDetail.videos == 1) {
              title = videoDetail.title!;
            } else {
              title =
                  videoDetail.pages
                      ?.firstWhereOrNull(
                        (e) => e.cid == videoDetailCtr.cid.value,
                      )
                      ?.part ??
                  videoDetail.title!;
            }
            return MarqueeText(
              title,
              spacing: 30,
              velocity: 30,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              provider: effectiveProvider,
            );
          },
        ),
      );
      if (introController.isShowOnlineTotal) {
        title = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            Obx(
              () => Text(
                '${introController.total.value}人正在看',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        );
      }
      title = Expanded(child: title);
    } else {
      title = const Spacer();
    }

    const btnWidth = 40.0;
    const btnHeight = 34.0;
    const btnStyle = ButtonStyle(padding: WidgetStatePropertyAll(.zero));

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      primary: false,
      automaticallyImplyLeading: false,
      toolbarHeight: showFSActionItem ? 112 : null,
      flexibleSpace: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 11),
          Row(
            children: [
              SizedBox(
                width: btnWidth,
                height: btnHeight,
                child: IconButton(
                  tooltip: '返回',
                  style: btnStyle,
                  icon: const Icon(
                    FontAwesomeIcons.arrowLeft,
                    size: 15,
                    color: Colors.white,
                  ),
                  onPressed: () =>
                      plPlayerController.onPopInvokedWithResult(false, null),
                ),
              ),
              if (!plPlayerController.isDesktopPip &&
                  (!isFullScreen || !isPortrait))
                SizedBox(
                  width: btnWidth,
                  height: btnHeight,
                  child: IconButton(
                    tooltip: '返回主页',
                    style: btnStyle,
                    icon: const Icon(
                      FontAwesomeIcons.house,
                      size: 15,
                      color: Colors.white,
                    ),
                    onPressed: plPlayerController.onCloseAll,
                  ),
                ),
              title,
              // show current datetime
              ...?timeBatteryWidgets,
              if (PlatformUtils.isDesktop && !plPlayerController.isDesktopPip)
                Obx(() {
                  final isAlwaysOnTop = plPlayerController.isAlwaysOnTop.value;
                  return SizedBox(
                    width: btnWidth,
                    height: btnHeight,
                    child: IconButton(
                      style: btnStyle,
                      tooltip: '${isAlwaysOnTop ? '取消' : ''}置顶',
                      onPressed: () =>
                          plPlayerController.setAlwaysOnTop(!isAlwaysOnTop),
                      icon: isAlwaysOnTop
                          ? const Icon(
                              size: 19,
                              Icons.push_pin,
                              color: Colors.white,
                            )
                          : const Icon(
                              size: 19,
                              Icons.push_pin_outlined,
                              color: Colors.white,
                            ),
                    ),
                  );
                }),
              if (!isFileSource) ...[
                if (!isFSOrPip) ...[
                  if (videoDetailCtr.isUgc)
                    SizedBox(
                      width: btnWidth,
                      height: btnHeight,
                      child: IconButton(
                        tooltip: '听音频',
                        style: btnStyle,
                        onPressed: videoDetailCtr.toAudioPage,
                        icon: const Icon(
                          Icons.headphones_outlined,
                          size: 19,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: btnWidth,
                    height: btnHeight,
                    child: IconButton(
                      tooltip: '投屏',
                      style: btnStyle,
                      onPressed: videoDetailCtr.onCast,
                      icon: const Icon(
                        Icons.cast,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (plPlayerController.enableSponsorBlock)
                  SizedBox(
                    width: btnWidth,
                    height: btnHeight,
                    child: IconButton(
                      tooltip: '提交片段',
                      style: btnStyle,
                      onPressed: () => videoDetailCtr.onBlock(context),
                      icon: const Icon(
                        CustomIcons.shield_play_arrow,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Obx(
                  () => videoDetailCtr.segmentProgressList.isNotEmpty
                      ? SizedBox(
                          width: btnWidth,
                          height: btnHeight,
                          child: IconButton(
                            tooltip: '片段信息',
                            style: btnStyle,
                            onPressed: videoDetailCtr.showSBDetail,
                            icon: const Icon(
                              MdiIcons.advertisements,
                              size: 19,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
              if (!isPortrait || isFullScreen || PlatformUtils.isDesktop) ...[
                SizedBox(
                  width: btnWidth,
                  height: btnHeight,
                  child: IconButton(
                    tooltip: '发弹幕',
                    style: btnStyle,
                    onPressed: videoDetailCtr.showShootDanmakuSheet,
                    icon: const Icon(
                      Icons.comment_outlined,
                      size: 19,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  width: btnWidth,
                  height: btnHeight,
                  child: Obx(
                    () {
                      final enableShowDanmaku =
                          plPlayerController.enableShowDanmaku.value;
                      return IconButton(
                        tooltip: "${enableShowDanmaku ? '关闭' : '开启'}弹幕",
                        style: btnStyle,
                        onPressed: () {
                          final newVal = !enableShowDanmaku;
                          plPlayerController.enableShowDanmaku.value = newVal;
                          if (!plPlayerController.tempPlayerConf) {
                            setting.put(
                              SettingBoxKey.enableShowDanmaku,
                              newVal,
                            );
                          }
                        },
                        icon: enableShowDanmaku
                            ? const Icon(
                                size: 20,
                                CustomIcons.dm_on,
                                color: Colors.white,
                              )
                            : const Icon(
                                size: 20,
                                CustomIcons.dm_off,
                                color: Colors.white,
                              ),
                      );
                    },
                  ),
                ),
              ],
              SizedBox(
                width: btnWidth,
                height: btnHeight,
                child: IconButton(
                  tooltip: '弹幕设置',
                  style: btnStyle,
                  onPressed: showSetDanmaku,
                  icon: const Icon(
                    size: 20,
                    CustomIcons.dm_settings,
                    color: Colors.white,
                  ),
                ),
              ),
              if (Platform.isAndroid ||
                  (PlatformUtils.isDesktop && !isFullScreen))
                SizedBox(
                  width: btnWidth,
                  height: btnHeight,
                  child: IconButton(
                    tooltip: '画中画',
                    style: btnStyle,
                    onPressed: () {
                      if (PlatformUtils.isDesktop) {
                        plPlayerController.toggleDesktopPip();
                        return;
                      }
                      if (AndroidHelper.isPipAvailable) {
                        plPlayerController.enterPip();
                      }
                    },
                    icon: const Icon(
                      Icons.picture_in_picture_outlined,
                      size: 19,
                      color: Colors.white,
                    ),
                  ),
                ),
              SizedBox(
                width: btnWidth,
                height: btnHeight,
                child: IconButton(
                  tooltip: "更多设置",
                  style: btnStyle,
                  onPressed: showSettingSheet,
                  icon: const Icon(
                    Icons.more_vert_outlined,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (showFSActionItem)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: btnWidth,
                  height: btnHeight,
                  child: Obx(
                    () => ActionItem(
                      expand: false,
                      icon: const Icon(
                        FontAwesomeIcons.thumbsUp,
                        color: Colors.white,
                      ),
                      selectIcon: const Icon(
                        FontAwesomeIcons.solidThumbsUp,
                      ),
                      selectStatus: introController.hasLike.value,
                      semanticsLabel: '点赞',
                      animation: introController.tripleAnimation,
                      onStartTriple: () {
                        plPlayerController.tripling = true;
                        introController.onStartTriple();
                      },
                      onCancelTriple: ([bool isTapUp = false]) {
                        plPlayerController
                          ..tripling = false
                          ..hideTaskControls();
                        introController.onCancelTriple(isTapUp);
                      },
                    ),
                  ),
                ),
                if (introController case final UgcIntroController ugc)
                  SizedBox(
                    width: btnWidth,
                    height: btnHeight,
                    child: Obx(
                      () => ActionItem(
                        expand: false,
                        icon: const Icon(
                          FontAwesomeIcons.thumbsDown,
                          color: Colors.white,
                        ),
                        selectIcon: const Icon(
                          FontAwesomeIcons.solidThumbsDown,
                        ),
                        onTap: () => ugc.handleAction(ugc.actionDislikeVideo),
                        selectStatus: ugc.hasDislike.value,
                        semanticsLabel: '点踩',
                      ),
                    ),
                  ),
                SizedBox(
                  width: btnWidth,
                  height: btnHeight,
                  child: Obx(
                    () => ActionItem(
                      expand: false,
                      animation: introController.tripleAnimation,
                      icon: const Icon(
                        FontAwesomeIcons.b,
                        color: Colors.white,
                      ),
                      selectIcon: const Icon(FontAwesomeIcons.b),
                      onTap: introController.actionCoinVideo,
                      selectStatus: introController.hasCoin,
                      semanticsLabel: '投币',
                    ),
                  ),
                ),
                SizedBox(
                  width: btnWidth,
                  height: btnHeight,
                  child: Obx(
                    () => ActionItem(
                      expand: false,
                      animation: introController.tripleAnimation,
                      icon: const Icon(
                        FontAwesomeIcons.star,
                        color: Colors.white,
                      ),
                      selectIcon: const Icon(FontAwesomeIcons.solidStar),
                      onTap: () => introController.showFavBottomSheet(context),
                      onLongPress: () => introController.showFavBottomSheet(
                        context,
                        isLongPress: true,
                      ),
                      selectStatus: introController.hasFav.value,
                      semanticsLabel: '收藏',
                    ),
                  ),
                ),
                SizedBox(
                  width: btnWidth,
                  height: btnHeight,
                  child: ActionItem(
                    expand: false,
                    icon: const Icon(
                      FontAwesomeIcons.shareFromSquare,
                      color: Colors.white,
                    ),
                    onTap: () => introController.actionShareVideo(context),
                    semanticsLabel: '分享',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Subtitle Settings Glass Sub-Page ────────────────────────────────────────

class _SubtitleSettingsContent extends StatefulWidget {
  const _SubtitleSettingsContent({required this.controller});

  final PlPlayerController controller;

  @override
  State<_SubtitleSettingsContent> createState() =>
      _SubtitleSettingsContentState();
}

class _SubtitleSettingsContentState extends State<_SubtitleSettingsContent> {
  PlPlayerController get ctr => widget.controller;

  double get subtitleFontScale => ctr.subtitleFontScale;
  double get subtitleFontScaleFS => ctr.subtitleFontScaleFS;
  int get subtitlePaddingH => ctr.subtitlePaddingH;
  int get subtitlePaddingB => ctr.subtitlePaddingB;
  double get subtitleBgOpacity => ctr.subtitleBgOpacity;
  double get subtitleStrokeWidth => ctr.subtitleStrokeWidth;
  int get subtitleFontWeight => ctr.subtitleFontWeight;

  static const _sliderTheme = SliderThemeData(
    trackHeight: 6,
    trackShape: MSliderTrackShape(),
    thumbColor: Colors.white,
    activeTrackColor: Colors.white,
    inactiveTrackColor: Color(0x33FFFFFF),
    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5.0),
  );

  void _updateFontScale(double val) {
    ctr
      ..subtitleFontScale = val
      ..updateSubtitleStyle();
    setState(() {});
  }

  void _updateFontScaleFS(double val) {
    ctr
      ..subtitleFontScaleFS = val
      ..updateSubtitleStyle();
    setState(() {});
  }

  void _updateFontWeight(double val) {
    ctr
      ..subtitleFontWeight = val.toInt()
      ..updateSubtitleStyle();
    setState(() {});
  }

  void _updateStrokeWidth(double val) {
    ctr
      ..subtitleStrokeWidth = val
      ..updateSubtitleStyle();
    setState(() {});
  }

  void _updateHorizontalPadding(double val) {
    ctr
      ..subtitlePaddingH = val.round()
      ..updateSubtitleStyle();
    setState(() {});
  }

  void _updateBottomPadding(double val) {
    ctr
      ..subtitlePaddingB = val.round()
      ..updateSubtitleStyle();
    setState(() {});
  }

  void _updateOpacity(double val) {
    ctr
      ..subtitleBgOpacity = val.toPrecision(2)
      ..updateSubtitleStyle();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildSliderTile(
          label: '字体大小 ${(subtitleFontScale * 100).toStringAsFixed(1)}%',
          tooltip: '默认值: 100.0%',
          defaultValue: '100.0%',
          onReset: () => _updateFontScale(1.0),
          slider: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              min: 0.5,
              max: 2.5,
              value: subtitleFontScale,
              divisions: 20,
              label: '${(subtitleFontScale * 100).toStringAsFixed(1)}%',
              onChanged: _updateFontScale,
            ),
          ),
        ),
        _buildSliderTile(
          label:
              '全屏字体大小 ${(subtitleFontScaleFS * 100).toStringAsFixed(1)}%',
          tooltip: '默认值: 150.0%',
          defaultValue: '150.0%',
          onReset: () => _updateFontScaleFS(1.5),
          slider: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              min: 0.5,
              max: 2.5,
              value: subtitleFontScaleFS,
              divisions: 20,
              label: '${(subtitleFontScaleFS * 100).toStringAsFixed(1)}%',
              onChanged: _updateFontScaleFS,
            ),
          ),
        ),
        _buildSliderTile(
          label: '字体粗细 ${subtitleFontWeight + 1}（可能无法精确调节）',
          tooltip: '默认值: 6',
          defaultValue: 6,
          onReset: () => _updateFontWeight(5),
          slider: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              min: 0,
              max: 8,
              value: subtitleFontWeight.toDouble(),
              divisions: 8,
              label: '${subtitleFontWeight + 1}',
              onChanged: _updateFontWeight,
            ),
          ),
        ),
        _buildSliderTile(
          label: '描边粗细 $subtitleStrokeWidth',
          tooltip: '默认值: 2.0',
          defaultValue: 2.0,
          onReset: () => _updateStrokeWidth(2.0),
          slider: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              min: 0,
              max: 5,
              value: subtitleStrokeWidth,
              divisions: 10,
              label: '$subtitleStrokeWidth',
              onChanged: _updateStrokeWidth,
            ),
          ),
        ),
        _buildSliderTile(
          label: '左右边距 $subtitlePaddingH',
          tooltip: '默认值: 24',
          defaultValue: 24,
          onReset: () => _updateHorizontalPadding(24),
          slider: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              min: 0,
              max: 100,
              value: subtitlePaddingH.toDouble(),
              divisions: 100,
              label: '$subtitlePaddingH',
              onChanged: _updateHorizontalPadding,
            ),
          ),
        ),
        _buildSliderTile(
          label: '底部边距 $subtitlePaddingB',
          tooltip: '默认值: 24',
          defaultValue: 24,
          onReset: () => _updateBottomPadding(24),
          slider: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              min: 0,
              max: 200,
              value: subtitlePaddingB.toDouble(),
              divisions: 200,
              label: '$subtitlePaddingB',
              onChanged: _updateBottomPadding,
            ),
          ),
        ),
        _buildSliderTile(
          label: '背景不透明度 ${(subtitleBgOpacity * 100).toInt()}%',
          tooltip: '默认值: 67%',
          defaultValue: '67%',
          onReset: () => _updateOpacity(0.67),
          slider: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              min: 0,
              max: 1,
              value: subtitleBgOpacity,
              onChanged: _updateOpacity,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSliderTile({
    required String label,
    required String tooltip,
    required Object defaultValue,
    required VoidCallback onReset,
    required Widget slider,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: PlayerTokens.settingsTileLabel,
                ),
              ),
              _GlassResetBtn(
                tooltip: tooltip,
                onTap: onReset,
              ),
            ],
          ),
          slider,
        ],
      ),
    );
  }
}

class _GlassResetBtn extends StatelessWidget {
  const _GlassResetBtn({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.xsAll,
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.refresh,
            size: 18,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ─── Glass Selection Tile (shared by video/audio/decode lists) ────────────────

class _GlassSelectionTile extends StatelessWidget {
  const _GlassSelectionTile({
    required this.label,
    this.subtitle,
    required this.isSelected,
    this.enabled = true,
    this.onTap,
  });

  final String label;
  final String? subtitle;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withValues(alpha: 0.08),
      highlightColor: Colors.white.withValues(alpha: 0.05),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.38,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: PlayerTokens.settingsTileLabel.fontSize,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: PlayerTokens.settingsSubtitle,
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_rounded, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Danmaku Pool Sub-Page ────────────────────────────────────────────────────

class _DanmakuPoolContent extends StatefulWidget {
  const _DanmakuPoolContent({
    required this.danmakuController,
    required this.plPlayerController,
    required this.onLikeDanmaku,
    required this.onDeleteDanmaku,
    required this.onReportDanmaku,
  });

  final DanmakuController danmakuController;
  final PlPlayerController plPlayerController;
  final Future<bool> Function(VideoDanmaku extra) onLikeDanmaku;
  final Future<void> Function(int id) onDeleteDanmaku;
  final void Function(VideoDanmaku extra) onReportDanmaku;

  @override
  State<_DanmakuPoolContent> createState() => _DanmakuPoolContentState();
}

class _DanmakuPoolContentState extends State<_DanmakuPoolContent> {
  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final ctr = widget.danmakuController;
    final slivers = <Widget>[];
    void addList(List<DanmakuItem<dynamic>> items) {
      if (items.isNotEmpty) {
        slivers.add(
          _buildDanmakuList(items.cast<DanmakuItem<DanmakuExtra>>()),
        );
      }
    }

    addList(ctr.staticDanmaku.nonNulls.toList());
    addList(ctr.scrollDanmaku.expand((e) => e).toList());
    addList(ctr.specialDanmaku.toList());
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 12)));

    return CustomScrollView(slivers: slivers);
  }

  Widget _buildDanmakuList(List<DanmakuItem<DanmakuExtra>> list) {
    return SliverList.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final extra = item.content.extra! as VideoDanmaku;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: InkWell(
            onLongPress: () => Utils.copyText(item.content.text),
            borderRadius: AppRadii.smAll,
            splashColor: Colors.white.withValues(alpha: 0.08),
            highlightColor: Colors.white.withValues(alpha: 0.04),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.content.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _GlassIconBtn(
                        icon: extra.isLike
                            ? CustomIcons.player_dm_tip_like_solid
                            : CustomIcons.player_dm_tip_like,
                        tooltip: '点赞',
                        onTap: () async {
                          final ok =
                              await widget.onLikeDanmaku(extra);
                          if (ok) _rebuild();
                        },
                      ),
                      if (extra.like > 0)
                        Text(
                          extra.like.toString(),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (item.content.selfSend)
                        _GlassIconBtn(
                          icon: CustomIcons.player_dm_tip_recall,
                          tooltip: '撤回',
                          onTap: () async {
                            await widget.onDeleteDanmaku(extra.id);
                            item.expired = true;
                            _rebuild();
                          },
                        )
                      else
                        _GlassIconBtn(
                          icon: CustomIcons.player_dm_tip_back,
                          tooltip: '举报',
                          onTap: () =>
                              widget.onReportDanmaku(extra),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlassIconBtn extends StatelessWidget {
  const _GlassIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.xsAll,
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 18,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

// ─── Danmaku Settings Sub-Page ────────────────────────────────────────────────

class _DanmakuSettingsContent extends StatefulWidget {
  const _DanmakuSettingsContent({
    required this.plPlayerController,
    required this.danmakuController,
    required this.isFullScreen,
  });

  final PlPlayerController plPlayerController;
  final DanmakuController? danmakuController;
  final bool isFullScreen;

  @override
  State<_DanmakuSettingsContent> createState() =>
      _DanmakuSettingsContentState();
}

class _DanmakuSettingsContentState extends State<_DanmakuSettingsContent> {
  static const _sliderTheme = SliderThemeData(
    trackHeight: 6,
    trackShape: MSliderTrackShape(),
    thumbColor: Colors.white,
    activeTrackColor: Colors.white,
    inactiveTrackColor: Color(0x33FFFFFF),
    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5.0),
  );

  void _setOptions() => widget.danmakuController?.updateOption(
    DanmakuOptions.get(
      notFullscreen: !widget.isFullScreen,
      speed: widget.plPlayerController.playbackSpeed,
    ),
  );

  void _setStateAndApply() {
    setState(() {});
    _setOptions();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildSliderTile(
          label: '智能云屏蔽 ${DanmakuOptions.danmakuWeight} 级',
          tooltip: '默认值: 0',
          defaultValue: 0,
          onReset: () {
            DanmakuOptions.danmakuWeight = 0;
            _setStateAndApply();
          },
          trailing: _GlassTextBtn(
            label:
                '屏蔽管理(${widget.plPlayerController.filters.count})',
            onTap: () {
              Get
                ..back()
                ..toNamed(
                  '/danmakuBlock',
                  arguments: widget.plPlayerController,
                );
            },
          ),
          slider: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              min: 0,
              max: 11,
              value: DanmakuOptions.danmakuWeight.toDouble(),
              divisions: 11,
              label: DanmakuOptions.danmakuWeight.toString(),
              onChanged: (v) {
                DanmakuOptions.danmakuWeight = v.toInt();
                _setStateAndApply();
              },
            ),
          ),
        ),

        _sectionHeader('按类型屏蔽'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: const [
              (value: 2, label: '滚动'),
              (value: 5, label: '顶部'),
              (value: 4, label: '底部'),
              (value: 6, label: '彩色'),
              (value: 7, label: '高级'),
            ].map((e) {
              final blocked =
                  DanmakuOptions.blockTypes.contains(e.value);
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _GlassToggleChip(
                  label: e.label,
                  isSelected: blocked,
                  onTap: () {
                    if (blocked) {
                      DanmakuOptions.blockTypes.remove(e.value);
                    } else {
                      DanmakuOptions.blockTypes.add(e.value);
                    }
                    DanmakuOptions.blockColorful =
                        DanmakuOptions.blockTypes.contains(6);
                    _setStateAndApply();
                  },
                ),
              );
            }).toList(),
          ),
        ),

        _sectionHeader('其他'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _GlassToggleChip(
                label: '海量弹幕',
                isSelected: DanmakuOptions.danmakuMassiveMode,
                onTap: () {
                  DanmakuOptions.danmakuMassiveMode =
                      !DanmakuOptions.danmakuMassiveMode;
                  _setStateAndApply();
                },
              ),
              const SizedBox(width: 10),
              _GlassToggleChip(
                label: '固定转滚动',
                isSelected: DanmakuOptions.danmakuStatic2Scroll,
                onTap: () {
                  DanmakuOptions.danmakuStatic2Scroll =
                      !DanmakuOptions.danmakuStatic2Scroll;
                  _setStateAndApply();
                },
              ),
              const SizedBox(width: 10),
              _GlassToggleChip(
                label: '滚动弹幕固定速度',
                isSelected: DanmakuOptions.danmakuFixedV,
                onTap: () {
                  DanmakuOptions.danmakuFixedV =
                      !DanmakuOptions.danmakuFixedV;
                  _setStateAndApply();
                },
              ),
            ],
          ),
        ),

        _buildSliderTile(
          label:
              '显示区域 ${(DanmakuOptions.danmakuShowArea * 100).toStringAsFixed(0)}%',
          tooltip: '默认值: 50.0%',
          defaultValue: '50.0%',
          onReset: () {
            DanmakuOptions.danmakuShowArea = 0.5;
            _setStateAndApply();
          },
          slider: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              min: 0.1,
              max: 1,
              value: DanmakuOptions.danmakuShowArea,
              divisions: 9,
              label:
                  '${(DanmakuOptions.danmakuShowArea * 100).toStringAsFixed(0)}%',
              onChanged: (v) {
                DanmakuOptions.danmakuShowArea = v.toPrecision(1);
                _setStateAndApply();
              },
            ),
          ),
        ),

        _buildSliderTile(
          label:
              '不透明度 ${(widget.plPlayerController.danmakuOpacity.value * 100).toStringAsFixed(0)}%',
          tooltip: '默认值: 100.0%',
          defaultValue: '100.0%',
          onReset: () {
            widget.plPlayerController.danmakuOpacity.value = 1.0;
            setState(() {});
          },
          slider: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              min: 0,
              max: 1,
              value: widget.plPlayerController.danmakuOpacity.value,
              divisions: 10,
              label:
                  '${(widget.plPlayerController.danmakuOpacity.value * 100).toStringAsFixed(0)}%',
              onChanged: (v) {
                widget.plPlayerController.danmakuOpacity.value = v;
                setState(() {});
              },
            ),
          ),
        ),

        _buildSliderTile(
          label:
              '字体粗细 ${DanmakuOptions.danmakuFontWeight + 1}（可能无法精确调节）',
          tooltip: '默认值: 6',
          defaultValue: 6,
          onReset: () {
            DanmakuOptions.danmakuFontWeight = 5;
            _setStateAndApply();
          },
          slider: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              min: 0,
              max: 8,
              value: DanmakuOptions.danmakuFontWeight.toDouble(),
              divisions: 8,
              label: '${DanmakuOptions.danmakuFontWeight + 1}',
              onChanged: (v) {
                DanmakuOptions.danmakuFontWeight = v.toInt();
                _setStateAndApply();
              },
            ),
          ),
        ),

        _buildSliderTile(
          label: '描边粗细 ${DanmakuOptions.danmakuStrokeWidth}',
          tooltip: '默认值: 1.5',
          defaultValue: 1.5,
          onReset: () {
            DanmakuOptions.danmakuStrokeWidth = 1.5;
            _setStateAndApply();
          },
          slider: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              min: 0,
              max: 5,
              value: DanmakuOptions.danmakuStrokeWidth,
              divisions: 10,
              label: DanmakuOptions.danmakuStrokeWidth.toStringAsFixed(0),
              onChanged: (v) {
                DanmakuOptions.danmakuStrokeWidth = v;
                _setStateAndApply();
              },
            ),
          ),
        ),

        _buildSliderTile(
          label:
              '字体大小 ${(DanmakuOptions.danmakuFontScale * 100).toStringAsFixed(1)}%',
          tooltip: '默认值: 100.0%',
          defaultValue: '100.0%',
          onReset: () {
            DanmakuOptions.danmakuFontScale = 1.0;
            _setStateAndApply();
          },
          slider: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              min: 0.5,
              max: 2.5,
              value: DanmakuOptions.danmakuFontScale,
              divisions: 20,
              label:
                  '${(DanmakuOptions.danmakuFontScale * 100).toStringAsFixed(1)}%',
              onChanged: (v) {
                DanmakuOptions.danmakuFontScale = v;
                _setStateAndApply();
              },
            ),
          ),
        ),

        _buildSliderTile(
          label:
              '全屏字体大小 ${(DanmakuOptions.danmakuFontScaleFS * 100).toStringAsFixed(1)}%',
          tooltip: '默认值: 120.0%',
          defaultValue: '120.0%',
          onReset: () {
            DanmakuOptions.danmakuFontScaleFS = 1.2;
            _setStateAndApply();
          },
          slider: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              min: 0.5,
              max: 2.5,
              value: DanmakuOptions.danmakuFontScaleFS,
              divisions: 20,
              label:
                  '${(DanmakuOptions.danmakuFontScaleFS * 100).toStringAsFixed(1)}%',
              onChanged: (v) {
                DanmakuOptions.danmakuFontScaleFS = v;
                _setStateAndApply();
              },
            ),
          ),
        ),

        _buildSliderTile(
          label: '滚动弹幕时长 ${DanmakuOptions.danmakuDuration} 秒',
          tooltip: '默认值: 7.0',
          defaultValue: 7.0,
          onReset: () {
            DanmakuOptions.danmakuDuration = 7.0;
            _setStateAndApply();
          },
          slider: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              min: 1,
              max: 50,
              value: DanmakuOptions.danmakuDuration,
              divisions: 49,
              label: DanmakuOptions.danmakuDuration.toString(),
              onChanged: (v) {
                DanmakuOptions.danmakuDuration = v.toPrecision(1);
                _setStateAndApply();
              },
            ),
          ),
        ),

        _buildSliderTile(
          label: '静态弹幕时长 ${DanmakuOptions.danmakuStaticDuration} 秒',
          tooltip: '默认值: 4.0',
          defaultValue: 4.0,
          onReset: () {
            DanmakuOptions.danmakuStaticDuration = 4.0;
            _setStateAndApply();
          },
          slider: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              min: 1,
              max: 50,
              value: DanmakuOptions.danmakuStaticDuration,
              divisions: 49,
              label: DanmakuOptions.danmakuStaticDuration.toString(),
              onChanged: (v) {
                DanmakuOptions.danmakuStaticDuration = v.toPrecision(1);
                _setStateAndApply();
              },
            ),
          ),
        ),

        _buildSliderTile(
          label: '弹幕行高 ${DanmakuOptions.danmakuLineHeight}',
          tooltip: '默认值: 1.6',
          defaultValue: 1.6,
          onReset: () {
            DanmakuOptions.danmakuLineHeight = 1.6;
            _setStateAndApply();
          },
          slider: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              min: 1.0,
              max: 3.0,
              value: DanmakuOptions.danmakuLineHeight,
              onChanged: (v) {
                DanmakuOptions.danmakuLineHeight = v.toPrecision(1);
                _setStateAndApply();
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xB3FFFFFF),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSliderTile({
    required String label,
    required String tooltip,
    required Object defaultValue,
    required VoidCallback onReset,
    required Widget slider,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: PlayerTokens.settingsTileLabel,
                ),
              ),
              if (trailing != null) trailing,
              _GlassResetBtn(tooltip: tooltip, onTap: onReset),
            ],
          ),
          slider,
        ],
      ),
    );
  }
}

class _GlassToggleChip extends StatelessWidget {
  const _GlassToggleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.smAll,
      splashColor: Colors.white.withValues(alpha: 0.08),
      highlightColor: Colors.white.withValues(alpha: 0.04),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: AppRadii.smAll,
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _GlassTextBtn extends StatelessWidget {
  const _GlassTextBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.xsAll,
      splashColor: Colors.white.withValues(alpha: 0.08),
      highlightColor: Colors.white.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xB3FFFFFF),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
