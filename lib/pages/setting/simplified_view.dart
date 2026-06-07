import 'package:PiliNext/common/animation/animation.dart';
import 'package:PiliNext/models/common/dynamic/dynamic_badge_mode.dart';
import 'package:PiliNext/models/common/nav_bar_config.dart';
import 'package:PiliNext/models/common/reply/reply_sort_type.dart';
import 'package:PiliNext/models/common/theme/theme_type.dart';
import 'package:PiliNext/utils/storage.dart';
import 'package:PiliNext/utils/storage_key.dart';
import 'package:PiliNext/utils/theme_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Simplified settings page — PiliNext redesign.
///
/// All settings fit in one scrollable view with categorized sections.
/// From 200+ settings down to ~30. Each setting is a simple switch,
/// dropdown, or action — no nested sub-pages.
class SimplifiedSettingsPage extends StatefulWidget {
  const SimplifiedSettingsPage({super.key});

  @override
  State<SimplifiedSettingsPage> createState() => _SimplifiedSettingsPageState();
}

class _SimplifiedSettingsPageState extends State<SimplifiedSettingsPage> {
  late final _setting = GStorage.setting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: _staggerSettingsChildren([
          const _SectionHeader(title: '播放'),
          ..._playSettings(colorScheme),

          const _SectionHeader(title: '弹幕'),
          ..._danmakuSettings(colorScheme),

          const _SectionHeader(title: '外观'),
          ..._appearanceSettings(colorScheme),

          const _SectionHeader(title: '导航'),
          ..._navSettings(colorScheme),

          const _SectionHeader(title: '内容'),
          ..._contentSettings(colorScheme),

          const _SectionHeader(title: '消息'),
          ..._messageSettings(colorScheme),

          const _SectionHeader(title: '隐私'),
          ..._privacySettings(colorScheme),

          const _SectionHeader(title: '其他'),
          ..._otherSettings(colorScheme),

          const SizedBox(height: 32),
          _buildAboutTile(colorScheme),
        ]),
      ),
    );
  }

  List<Widget> _staggerSettingsChildren(List<Widget> children) {
    return children.indexed.map((entry) {
      final index = entry.$1;
      final child = entry.$2;
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 140 + (index.clamp(0, 12) * 12)),
        curve: FluidTokens.curveEnter,
        builder: (context, value, child) {
          final reduceMotion = FluidTokens.reduceMotionOf(context);
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: reduceMotion ? Offset.zero : Offset(0, (1 - value) * 8),
              child: child,
            ),
          );
        },
        child: child,
      );
    }).toList();
  }

  // ── Play Settings ────────────────────────────────────────────

  List<Widget> _playSettings(ColorScheme cs) {
    return [
      _DropdownTile<int>(
        icon: Icons.hd,
        label: '默认视频画质 (WiFi)',
        selectedValue: _setting.get(SettingBoxKey.defaultVideoQa) ?? 0,
        items: const {
          0: '自动',
          16: '360P',
          32: '480P',
          64: '720P',
          80: '1080P',
          116: '4K',
        },
        onChanged: (v) => _setting.put(SettingBoxKey.defaultVideoQa, v),
      ),
      _DropdownTile<int>(
        icon: Icons.signal_cellular_alt,
        label: '默认视频画质 (蜂窝)',
        selectedValue: _setting.get(SettingBoxKey.defaultVideoQaCellular) ?? 0,
        items: const {
          0: '自动',
          16: '360P',
          32: '480P',
          64: '720P',
        },
        onChanged: (v) => _setting.put(SettingBoxKey.defaultVideoQaCellular, v),
      ),
      const _SwitchTile(
        icon: Icons.headphones,
        label: '后台播放',
        storageKey: SettingBoxKey.enableBackgroundPlay,
      ),
      const _SwitchTile(
        icon: Icons.picture_in_picture,
        label: '自动画中画',
        storageKey: SettingBoxKey.autoPiP,
      ),
      const _SwitchTile(
        icon: Icons.skip_next,
        label: 'SponsorBlock 自动跳过',
        storageKey: SettingBoxKey.enableSponsorBlock,
      ),
    ];
  }

  // ── Danmaku Settings ─────────────────────────────────────────

  List<Widget> _danmakuSettings(ColorScheme cs) {
    return [
      const _SwitchTile(
        icon: Icons.closed_caption,
        label: '弹幕开关',
        storageKey: SettingBoxKey.enableShowDanmaku,
      ),
      _DropdownTile<double>(
        icon: Icons.density_medium,
        label: '弹幕密度',
        selectedValue: _danmakuShowArea(),
        items: {
          0.3: '少',
          0.5: '中',
          0.7: '多',
          1.0: '全屏',
        },
        onChanged: (v) => _setting.put(SettingBoxKey.danmakuShowArea, v),
      ),
      _DropdownTile<double>(
        icon: Icons.format_size,
        label: '弹幕字号',
        selectedValue:
            (_setting.get(SettingBoxKey.danmakuFontScale) as num?)
                ?.toDouble() ??
            1.0,
        items: {
          0.85: '小',
          1.0: '中',
          1.15: '大',
        },
        onChanged: (v) => _setting.put(SettingBoxKey.danmakuFontScale, v),
      ),
      _DropdownTile<double>(
        icon: Icons.opacity,
        label: '弹幕不透明度',
        selectedValue:
            (_setting.get(SettingBoxKey.danmakuOpacity) as num?)?.toDouble() ??
            0.7,
        items: {
          0.4: '低',
          0.7: '中',
          1.0: '高',
        },
        onChanged: (v) => _setting.put(SettingBoxKey.danmakuOpacity, v),
      ),
      _ActionTile(
        icon: Icons.translate,
        label: '字幕语言偏好',
        subtitle: '自动',
        onTap: () {},
      ),
    ];
  }

  double _danmakuShowArea() {
    final stored = _setting.get(SettingBoxKey.danmakuShowArea);
    if (stored is num) {
      final value = stored.toDouble();
      return value > 1 ? value / 100 : value;
    }
    return 0.5;
  }

  // ── Appearance Settings ──────────────────────────────────────

  List<Widget> _appearanceSettings(ColorScheme cs) {
    final currentTheme = _setting.get(SettingBoxKey.themeMode) ?? 0;
    return [
      _DropdownTile<int>(
        icon: Icons.brightness_6,
        label: '主题模式',
        selectedValue: currentTheme,
        items: {
          ThemeType.system.index: '跟随系统',
          ThemeType.light.index: '浅色',
          ThemeType.dark.index: '深色',
        },
        onChanged: (v) {
          _setting.put(SettingBoxKey.themeMode, v);
          Get.changeThemeMode(
            ThemeUtils.themeMode = ThemeType.values[v].toThemeMode,
          );
        },
      ),
    ];
  }

  // ── Navigation Settings ──────────────────────────────────────

  List<Widget> _navSettings(ColorScheme cs) {
    return [
      _ActionTile(
        icon: Icons.reorder,
        label: '导航栏项目顺序',
        subtitle: '拖拽排序',
        onTap: _showNavSortDialog,
      ),
      _DropdownTile<NavigationBarType>(
        icon: Icons.home,
        label: '首页默认 Tab',
        selectedValue: _defaultHomePage(),
        items: {
          for (final t in NavigationBarType.values) t: t.label,
        },
        onChanged: (v) => _setting.put(SettingBoxKey.defaultHomePage, v.index),
      ),
    ];
  }

  NavigationBarType _defaultHomePage() {
    final stored = _setting.get(SettingBoxKey.defaultHomePage);
    if (stored is int &&
        stored >= 0 &&
        stored < NavigationBarType.values.length) {
      return NavigationBarType.values[stored];
    }
    if (stored is NavigationBarType) return stored;
    return NavigationBarType.home;
  }

  void _showNavSortDialog() {
    // Deferred: full drag-to-reorder implementation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导航栏顺序'),
        content: const Text('长按拖拽排序功能将在后续版本中提供。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  // ── Content Settings ─────────────────────────────────────────

  List<Widget> _contentSettings(ColorScheme cs) {
    return [
      const _SwitchTile(
        icon: Icons.public,
        label: '推荐来源 (App 端)',
        subtitle: '关闭使用 WEB 端推荐',
        storageKey: SettingBoxKey.appRcmd,
      ),
      const _SwitchTile(
        icon: Icons.playlist_play,
        label: '视频页显示相关视频',
        storageKey: SettingBoxKey.showRelatedVideo,
      ),
      const _SwitchTile(
        icon: Icons.comment,
        label: '视频页显示评论',
        storageKey: SettingBoxKey.showVideoReply,
      ),
      _DropdownTile<int>(
        icon: Icons.sort,
        label: '评论排序方式',
        selectedValue: _setting.get(SettingBoxKey.replySortType) ?? 0,
        items: {
          ReplySortType.hot.index: '按热度',
          ReplySortType.time.index: '按时间',
        },
        onChanged: (v) => _setting.put(SettingBoxKey.replySortType, v),
      ),
      _ActionTile(
        icon: Icons.folder,
        label: '默认收藏夹',
        subtitle: '点击设置',
        onTap: () {},
      ),
    ];
  }

  // ── Message Settings ─────────────────────────────────────────

  List<Widget> _messageSettings(ColorScheme cs) {
    return [
      _ActionTile(
        icon: Icons.notifications,
        label: '消息通知类型',
        subtitle: '选择需要通知的消息',
        onTap: () {},
      ),
      _DropdownTile<int>(
        icon: Icons.badge,
        label: '消息角标样式',
        selectedValue: _setting.get(SettingBoxKey.msgBadgeMode) ?? 0,
        items: {
          DynamicBadgeMode.number.index: '数字',
          DynamicBadgeMode.point.index: '红点',
          DynamicBadgeMode.hidden.index: '隐藏',
        },
        onChanged: (v) => _setting.put(SettingBoxKey.msgBadgeMode, v),
      ),
    ];
  }

  // ── Privacy Settings ─────────────────────────────────────────

  List<Widget> _privacySettings(ColorScheme cs) {
    return [
      const _SwitchTile(
        icon: Icons.history,
        label: '搜索历史记录',
        storageKey: SettingBoxKey.recordSearchHistory,
      ),
      const _SwitchTile(
        icon: Icons.lightbulb,
        label: '搜索建议',
        storageKey: SettingBoxKey.searchSuggestion,
      ),
    ];
  }

  // ── Other Settings ───────────────────────────────────────────

  List<Widget> _otherSettings(ColorScheme cs) {
    return [
      _ActionTile(
        icon: Icons.storage,
        label: '缓存大小限制',
        subtitle: '${(_setting.get(SettingBoxKey.maxCacheSize) ?? 500)} MB',
        onTap: () {},
      ),
      const _SwitchTile(
        icon: Icons.auto_delete,
        label: '自动清除缓存',
        storageKey: SettingBoxKey.autoClearCache,
      ),
      const _SwitchTile(
        icon: Icons.vibration,
        label: '触觉反馈',
        storageKey: SettingBoxKey.feedBackEnable,
      ),
      const _SwitchTile(
        icon: Icons.system_update,
        label: '检查更新',
        storageKey: SettingBoxKey.autoUpdate,
      ),
      _ActionTile(
        icon: Icons.language,
        label: '语言',
        subtitle: '简体中文',
        onTap: () {},
      ),
      _ActionTile(
        icon: Icons.gesture,
        label: '重新显示手势引导',
        subtitle: '下次播放视频时显示',
        onTap: () {
          _setting.delete('gestureGuideShown');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('手势引导已重置')),
          );
        },
      ),
    ];
  }

  Widget _buildAboutTile(ColorScheme cs) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('关于 PiliNext'),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => Navigator.of(context).pushNamed('/about'),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Reusable setting tile widgets
// ═════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String storageKey;

  const _SwitchTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.storageKey,
  });

  @override
  State<_SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends State<_SwitchTile> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value =
        GStorage.setting.get(widget.storageKey) ??
        _defaultValue(widget.storageKey);
  }

  bool _defaultValue(String key) => switch (key) {
    SettingBoxKey.autoPiP ||
    SettingBoxKey.enableSponsorBlock ||
    SettingBoxKey.autoClearCache ||
    SettingBoxKey.feedBackEnable => false,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(widget.icon, size: 20),
      title: Text(widget.label, style: const TextStyle(fontSize: 15)),
      subtitle: widget.subtitle != null ? Text(widget.subtitle!) : null,
      value: _value,
      onChanged: (v) {
        setState(() => _value = v);
        GStorage.setting.put(widget.storageKey, v);
      },
    );
  }
}

class _DropdownTile<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final T selectedValue;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  const _DropdownTile({
    required this.icon,
    required this.label,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final validValue =
        items.keys.where((item) => item == selectedValue).length == 1
        ? selectedValue
        : null;

    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: DropdownButton<T>(
        value: validValue,
        items: items.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.subtitle = '',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
