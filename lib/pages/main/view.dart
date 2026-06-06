import 'dart:async';
import 'dart:io';

import 'package:PiliNext/common/animation/animation.dart';
import 'package:PiliNext/common/assets.dart';
import 'package:PiliNext/common/constants.dart';
import 'package:PiliNext/common/widgets/glass_navigation_bar.dart';
import 'package:PiliNext/common/widgets/flutter/pop_scope.dart';
import 'package:PiliNext/common/widgets/flutter/tabs.dart';
import 'package:PiliNext/common/widgets/image/network_img_layer.dart';
import 'package:PiliNext/common/widgets/route_aware_mixin.dart';
import 'package:PiliNext/models/common/nav_bar_config.dart';
import 'package:PiliNext/pages/main/controller.dart';
import 'package:PiliNext/plugin/pl_player/controller.dart';
import 'package:PiliNext/plugin/pl_player/models/play_status.dart';
import 'package:PiliNext/utils/android/android_helper.dart';
import 'package:PiliNext/utils/app_scheme.dart';
import 'package:PiliNext/utils/extension/theme_ext.dart';
import 'package:PiliNext/utils/mobile_observer.dart';
import 'package:PiliNext/utils/platform_utils.dart';
import 'package:PiliNext/utils/storage.dart';
import 'package:PiliNext/utils/storage_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:win32/win32.dart' as kernel32;
import 'package:window_manager/window_manager.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends PopScopeState<MainApp>
    with
        RouteAware,
        RouteAwareMixin,
        WidgetsBindingObserver,
        WindowListener,
        TrayListener {
  final _mainController = Get.put(MainController());
  late final _setting = GStorage.setting;
  late EdgeInsets _padding;
  late ThemeData theme;
  Timer? _saveWindowBoundsTimer;

  @override
  bool get initCanPop => false;

  @override
  void initState() {
    super.initState();
    addObserverMobile(this);
    if (PlatformUtils.isDesktop) {
      windowManager
        ..addListener(this)
        ..setPreventClose(true);
      if (_mainController.showTrayIcon) {
        trayManager.addListener(this);
        _handleTray();
      }
    } else {
      // FlutterSmartDialog throws
      PiliScheme.init();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _padding = MediaQuery.viewPaddingOf(context);
    theme = Theme.of(context);
    final brightness = theme.brightness;
    NetworkImgLayer.reduce =
        NetworkImgLayer.reduceLuxColor != null && brightness.isDark;
    if (PlatformUtils.isDesktop) {
      windowManager.setBrightness(brightness);
    }
    // PiliNext: always use bottom navigation, all orientations.
    _mainController.useBottomNav = true;
  }

  @override
  void didPopNext() {
    addObserverMobile(this);
    _mainController
      ..checkUnreadDynamic()
      ..checkDefaultSearch(true)
      ..checkUnread(_mainController.useBottomNav);
    super.didPopNext();
  }

  @override
  void didPushNext() {
    removeObserverMobile(this);
    super.didPushNext();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _mainController
        ..checkUnreadDynamic()
        ..checkDefaultSearch(true)
        ..checkUnread(_mainController.useBottomNav);
    }
  }

  @override
  void dispose() {
    if (PlatformUtils.isDesktop) {
      trayManager.removeListener(this);
      windowManager.removeListener(this);
    }
    _saveWindowBoundsTimer?.cancel();
    removeObserverMobile(this);
    PiliScheme.listener?.cancel();
    GStorage.close();
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    _setting.put(SettingBoxKey.isWindowMaximized, true);
  }

  @override
  void onWindowUnmaximize() {
    _setting.put(SettingBoxKey.isWindowMaximized, false);
  }

  @override
  void onWindowMoved() {
    _debounceSaveWindowBounds();
  }

  @override
  void onWindowResized() {
    _debounceSaveWindowBounds();
  }

  void _debounceSaveWindowBounds() {
    if (PlPlayerController.instance?.isDesktopPip ?? false) {
      return;
    }
    _saveWindowBoundsTimer?.cancel();
    _saveWindowBoundsTimer = Timer(
      const Duration(milliseconds: 400),
      _saveWindowBounds,
    );
  }

  Future<void> _saveWindowBounds() async {
    if (PlPlayerController.instance?.isDesktopPip ?? false) {
      return;
    }

    final bounds = await windowManager.getBounds();
    final size = [bounds.width, bounds.height];
    final position = [bounds.left, bounds.top];
    final currentSize = _doubleList(SettingBoxKey.windowSize);
    final currentPosition = _doubleList(SettingBoxKey.windowPosition);

    if (_listEquals(currentSize, size) &&
        _listEquals(currentPosition, position)) {
      return;
    }

    _setting.putAll({
      SettingBoxKey.windowSize: size,
      SettingBoxKey.windowPosition: position,
    });
  }

  List<double>? _doubleList(String key) {
    return (_setting.get(key) as List?)
        ?.map((item) => (item as num).toDouble())
        .toList();
  }

  bool _listEquals(List<double>? a, List<double> b) {
    return a != null &&
        a.length == b.length &&
        a.indexed.every((item) => item.$2 == b[item.$1]);
  }

  @override
  void onWindowClose() {
    if (_mainController.showTrayIcon && _mainController.minimizeOnExit) {
      windowManager.hide();
      _onHideWindow();
    } else {
      _onClose();
    }
  }

  Future<void> _onClose() async {
    await GStorage.compact();
    await GStorage.close();
    await trayManager.destroy();
    if (Platform.isWindows) {
      // flutter_inappwebview
      // 6.2.0-beta.2+ https://github.com/pichillilorenzo/flutter_inappwebview/issues/2482
      // 6.1.5 https://github.com/pichillilorenzo/flutter_inappwebview/issues/2512#issuecomment-3031039587
      final hProcess = kernel32.GetCurrentProcess();
      kernel32.TerminateProcess(hProcess, 0);
    } else {
      exit(0);
    }
  }

  @override
  void onWindowMinimize() {
    _onHideWindow();
  }

  @override
  void onWindowRestore() {
    _onShowWindow();
  }

  void _onHideWindow() {
    if (_mainController.pauseOnMinimize) {
      if (PlPlayerController.instance case final player?) {
        if (_mainController.isPlaying = player.playerStatus.isPlaying) {
          player.pause();
        }
      } else {
        _mainController.isPlaying = false;
      }
    }
  }

  void _onShowWindow() {
    if (_mainController.pauseOnMinimize && _mainController.isPlaying) {
      PlPlayerController.instance?.play();
    }
  }

  @override
  Future<void> onTrayIconMouseDown() async {
    if (await windowManager.isVisible()) {
      _onHideWindow();
      windowManager.hide();
    } else {
      _onShowWindow();
      windowManager.show();
    }
  }

  @override
  Future<void> onTrayIconRightMouseDown() async {
    // ignore: deprecated_member_use
    trayManager.popUpContextMenu(bringAppToFront: true);
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        windowManager.show();
      case 'exit':
        _onClose();
    }
  }

  Future<void> _handleTray() async {
    if (Platform.isWindows) {
      await trayManager.setIcon(Assets.logoIco);
    } else {
      await trayManager.setIcon(Assets.logoLarge);
    }
    if (!Platform.isLinux) {
      await trayManager.setToolTip(Constants.appName);
    }

    Menu trayMenu = Menu(
      items: [
        MenuItem(key: 'show', label: '显示窗口'),
        MenuItem.separator(),
        MenuItem(key: 'exit', label: '退出 ${Constants.appName}'),
      ],
    );
    await trayManager.setContextMenu(trayMenu);
  }

  @pragma('vm:prefer-inline')
  static void _onBack() {
    if (Platform.isAndroid) {
      PiliAndroidHelper.back();
    }
  }

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {
    if (_mainController.directExitOnBack) {
      _onBack();
    } else {
      if (_mainController.selectedIndex.value != 0) {
        _mainController
          ..setIndex(0)
          ..barOffset?.value = 0.0
          ..showBottomBar?.value = true
          ..setSearchBar();
      } else {
        _onBack();
      }
    }
  }

  Widget? get _bottomNav {
    if (_mainController.navigationBars.length <= 1) return null;

    return Obx(
      () {
        final visible = switch (_mainController.barHideType) {
          _ when !_mainController.hideBottomBar => true,
          .instant => _mainController.showBottomBar?.value ?? true,
          .sync => (_mainController.barOffset?.value ?? 0) == 0,
        };
        return GlassNavigationBar(
          selectedIndex: _mainController.selectedIndex.value,
          destinations: _mainController.navigationBars
              .map(
                (e) => GlassNavigationDestination(
                  label: e.label,
                  icon: _buildIcon(type: e),
                  selectedIcon: _buildIcon(type: e, selected: true),
                  badge: _badgeForType(e),
                ),
              )
              .toList(),
          onDestinationSelected: _mainController.setIndex,
          visible: visible,
        );
      },
    );
  }

  Widget? _badgeForType(NavigationBarType type) {
    if (type == NavigationBarType.dynamics) {
      return Obx(
        () {
          final count = _mainController.dynCount.value;
          return count > 0 ? Text(count.toString()) : const SizedBox.shrink();
        },
      );
    }
    return null;
  }

  Widget _buildTabContent() {
    final pages = _mainController.navigationBars.map((i) => i.page).toList();
    if (_mainController.mainTabBarView) {
      return CustomTabBarView(
        scrollDirection: Axis.horizontal, // always horizontal — bottom nav
        physics: const NeverScrollableScrollPhysics(),
        controller: _mainController.controller,
        children: pages,
      );
    }

    return Obx(() {
      final index = _mainController.selectedIndex.value.clamp(
        0,
        pages.length - 1,
      );
      return _DirectionalTabSwitcher(
        selectedIndex: index,
        children: pages,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child = _buildTabContent();

    // PiliNext: always bottom navigation, all devices.
    // Desktop users can optionally switch to left pill in settings.
    final bottomNav = _bottomNav;

    child = Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(toolbarHeight: 0),
      body: Padding(
        padding: EdgeInsets.only(
          left: _padding.left,
          right: _padding.right,
        ),
        child: child,
      ),
      bottomNavigationBar: bottomNav,
    );

    if (PlatformUtils.isMobile) {
      child = AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: theme.brightness.reverse,
        ),
        child: child,
      );
    }

    return child;
  }

  Widget _buildIcon({required NavigationBarType type, bool selected = false}) {
    final icon = selected ? type.selectIcon : type.icon;
    return type == .dynamics
        ? Obx(
            () {
              final dynCount = _mainController.dynCount.value;
              return Badge(
                isLabelVisible: dynCount > 0,
                label: _mainController.dynamicBadgeMode == .number
                    ? Text(dynCount.toString())
                    : null,
                padding: const .symmetric(horizontal: 6),
                child: icon,
              );
            },
          )
        : icon;
  }
}

class _DirectionalTabSwitcher extends StatefulWidget {
  const _DirectionalTabSwitcher({
    required this.selectedIndex,
    required this.children,
  });

  final int selectedIndex;
  final List<Widget> children;

  @override
  State<_DirectionalTabSwitcher> createState() =>
      _DirectionalTabSwitcherState();
}

class _DirectionalTabSwitcherState extends State<_DirectionalTabSwitcher> {
  int _previousIndex = 0;

  @override
  void didUpdateWidget(_DirectionalTabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = FluidTokens.reduceMotionOf(context);
    final direction = widget.selectedIndex >= _previousIndex ? 1.0 : -1.0;
    final duration = FluidTokens.effectiveDuration(
      context,
      FluidTokens.durationMd,
    );

    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: duration,
      switchInCurve: FluidTokens.curveEnter,
      switchOutCurve: FluidTokens.curveExit,
      transitionBuilder: (child, animation) {
        if (reduceMotion) {
          return FadeTransition(opacity: animation, child: child);
        }
        final isIncoming = child.key == ValueKey(widget.selectedIndex);
        final offsetDirection = isIncoming ? direction : -direction;
        final offset = Tween<Offset>(
          begin: Offset(0.035 * offsetDirection, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(widget.selectedIndex),
        child: widget.children[widget.selectedIndex],
      ),
    );
  }
}
