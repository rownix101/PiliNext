import 'package:PiliNext/common/animation/animation.dart';
import 'package:PiliNext/common/design/design_tokens.dart';
import 'package:PiliNext/common/widgets/player_glass_surface.dart';
import 'package:PiliNext/plugin/pl_player/player_tokens.dart'
    show PlayerGlassStyle;
import 'package:PiliNext/utils/haptic_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tab configuration for [GlassNavigationBar].
class GlassNavigationDestination {
  const GlassNavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badge,
  });

  final String label;
  final Widget icon;
  final Widget selectedIcon;

  /// Optional badge widget (e.g., unread count).
  final Widget? badge;
}

/// PiliNext's signature bottom navigation bar — glassmorphism background
/// with a jelly-animated pill indicator.
///
/// Features:
/// - BackdropFilter blur background (glassmorphism)
/// - Semi-transparent surface with subtle border
/// - JellyIndicator for stretch-squish tab transitions
/// - Adaptive layout: phone/tablet/desktop with capped max width
/// - Auto-hide on scroll (via [visible] parameter)
/// - Keyboard navigation (arrow keys)
/// - Mouse hover feedback (desktop)
///
/// Usage:
/// ```dart
/// GlassNavigationBar(
///   selectedIndex: _currentIndex,
///   destinations: [...],
///   onDestinationSelected: (i) => setState(() => _currentIndex = i),
/// )
/// ```
class GlassNavigationBar extends StatefulWidget {
  const GlassNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    this.visible = true,
    this.width,
    this.height,
    this.bottomPadding,
    this.autofocus = false,
  });

  /// Currently selected tab index.
  final int selectedIndex;

  /// Tab destinations (4 max recommended).
  final List<GlassNavigationDestination> destinations;

  /// Called when a tab is tapped.
  final ValueChanged<int> onDestinationSelected;

  /// Whether the bar is visible (for scroll-hide behavior).
  final bool visible;

  /// Override width. If null, auto-calculated from device type
  /// with a max-width cap on desktop.
  final double? width;

  /// Override height. If null, auto-calculated from device type.
  final double? height;

  /// Override bottom padding (e.g., for system nav bar).
  final double? bottomPadding;

  /// Whether to request focus for keyboard navigation.
  final bool autofocus;

  @override
  State<GlassNavigationBar> createState() => _GlassNavigationBarState();
}

enum _Breakpoint { phone, tablet, desktop }

class _GlassNavigationBarState extends State<GlassNavigationBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _visibilityController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _visibilityController = AnimationController(
      vsync: this,
      duration: FluidTokens.durationMd,
      value: widget.visible ? 1.0 : 0.0,
    );
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(GlassNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _visibilityController.forward();
      } else {
        _visibilityController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _visibilityController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Layout breakpoints ────────────────────────────────────────

  static const double _phoneBreakpointMax = 600;
  static const double _tabletBreakpointMax = 1024;

  static _Breakpoint _breakpointForWidth(double screenWidth) {
    if (screenWidth < _phoneBreakpointMax) return _Breakpoint.phone;
    if (screenWidth <= _tabletBreakpointMax) return _Breakpoint.tablet;
    return _Breakpoint.desktop;
  }

  // ── Layout constants ──────────────────────────────────────────

  static const double _phoneItemWidth = 80;
  static const double _phoneHeight = 64;
  static const double _phoneBottomPad = 8;
  static const double _phoneFontSize = 11;

  static const double _tabletItemWidth = 120;
  static const double _tabletHeight = 72;
  static const double _tabletBottomPad = 12;
  static const double _tabletFontSize = 12;

  static const double _desktopItemWidth = 140;
  static const double _desktopHeight = 80;
  static const double _desktopBottomPad = 16;
  static const double _desktopFontSize = 13;

  /// Prevents the bar from stretching too wide on ultrawide monitors.
  static const double _desktopMaxBarWidth = 600;

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bp = _breakpointForWidth(screenWidth);
    final (itemWidth, barHeight, bottomPad, barWidth) = _layoutForWidth(
      screenWidth,
      bp,
    );
    final labelFontSize = _fontSizeForBreakpoint(bp);

    final selectedIndex = widget.destinations.isEmpty
        ? 0
        : widget.selectedIndex.clamp(0, widget.destinations.length - 1);

    final effectiveBottomPad = widget.bottomPadding ?? bottomPad;

    return AnimatedBuilder(
      animation: _visibilityController,
      builder: (context, child) {
        final reduceMotion = FluidTokens.reduceMotionOf(context);
        final visibilityValue = reduceMotion
            ? _visibilityController.value
            : FluidTokens.curveEnter.transform(_visibilityController.value);
        return Transform.translate(
          offset: Offset(
            0,
            reduceMotion
                ? 0
                : (1 - visibilityValue) * (barHeight + effectiveBottomPad + 20),
          ),
          child: Opacity(
            opacity: visibilityValue.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onKeyEvent: _handleKeyEvent,
        child: Padding(
          padding: EdgeInsets.only(
            left: _safeHorizontalPad(screenWidth, barWidth),
            right: _safeHorizontalPad(screenWidth, barWidth),
            bottom: effectiveBottomPad,
          ),
          child: PlayerGlassSurface(
            sigma: _blurForBreakpoint(bp),
            backgroundColor: colorScheme.surface.withValues(alpha: 0.30),
            borderRadius: AppRadii.fullAll,
            interactive: true,
            thickness: bp == _Breakpoint.desktop ? 1.2 : 1,
            style: PlayerGlassStyle.liquidGlass,
            border: Border.fromBorderSide(
              isDark
                  ? GlassTokens.borderDark(colorScheme.outlineVariant)
                  : GlassTokens.borderLight(colorScheme.outlineVariant),
            ),
            child: SizedBox(
              width: barWidth,
              height: barHeight,
              child: Stack(
                children: [
                  if (widget.destinations.isNotEmpty && itemWidth > 12)
                    // ── Jelly indicator ──────────────────────────
                    JellyIndicator(
                      currentIndex: selectedIndex,
                      itemCount: widget.destinations.length,
                      itemWidth: itemWidth,
                      indicatorHeight: barHeight - 12, // 6dp padding each side
                      indicatorColor: colorScheme.primary.withValues(
                        alpha: 0.18,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                    ),

                  // ── Tab items ─────────────────────────────────
                  Row(
                    children: () {
                      // Grow controller list to match current destination count
                      while (_tabStatesControllers.length <
                          widget.destinations.length) {
                        _tabStatesControllers.add(null);
                      }
                      return List.generate(
                        widget.destinations.length,
                        (i) {
                          final dest = widget.destinations[i];
                          final isSelected = i == selectedIndex;

                          final states = <WidgetState>{
                            if (isSelected) WidgetState.selected,
                          };

                          final effectiveMouseCursor = WidgetStateMouseCursor
                              .clickable
                              .resolve(states);

                          return Expanded(
                            child: Semantics(
                              button: true,
                              selected: isSelected,
                              label: dest.label,
                              child: InkWell(
                                onTap: () {
                                  HapticService.tap();
                                  widget.onDestinationSelected(i);
                                },
                                mouseCursor: effectiveMouseCursor,
                                borderRadius: BorderRadius.circular(
                                  barHeight,
                                ),
                                statesController: _tabStatesControllers[i] ??=
                                    WidgetStatesController(),
                                child: SizedBox(
                                  height: barHeight,
                                  child: AnimatedScale(
                                    scale: isSelected ? 1.0 : 0.96,
                                    duration: FluidTokens.effectiveDuration(
                                      context,
                                      FluidTokens.durationSm,
                                    ),
                                    curve: FluidTokens.curveEnter,
                                    child: AnimatedOpacity(
                                      opacity: isSelected ? 1.0 : 0.72,
                                      duration: FluidTokens.effectiveDuration(
                                        context,
                                        FluidTokens.durationSm,
                                      ),
                                      curve: FluidTokens.curveStandard,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: dest.badge != null
                                                ? Badge(
                                                    isLabelVisible: true,
                                                    label: dest.badge!,
                                                    child: isSelected
                                                        ? dest.selectedIcon
                                                        : dest.icon,
                                                  )
                                                : (isSelected
                                                      ? dest.selectedIcon
                                                      : dest.icon),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            dest.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: labelFontSize,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: isSelected
                                                  ? colorScheme.onSurface
                                                  : colorScheme.onSurface
                                                        .withValues(
                                                          alpha: 0.60,
                                                        ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Keyboard navigation ───────────────────────────────────────

  final List<WidgetStatesController?> _tabStatesControllers = List.filled(
    0,
    null,
    growable: true,
  );

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final destCount = widget.destinations.length;
    if (destCount <= 1) return KeyEventResult.ignored;

    final current = widget.selectedIndex.clamp(0, destCount - 1);
    final int next;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      next = current == 0 ? destCount - 1 : current - 1;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      next = current == destCount - 1 ? 0 : current + 1;
    } else {
      return KeyEventResult.ignored;
    }

    HapticService.tick();
    widget.onDestinationSelected(next);
    return KeyEventResult.handled;
  }

  // ── Layout helpers ───────────────────────────────────────────

  double _fontSizeForBreakpoint(_Breakpoint bp) => switch (bp) {
    _Breakpoint.phone => _phoneFontSize,
    _Breakpoint.tablet => _tabletFontSize,
    _Breakpoint.desktop => _desktopFontSize,
  };

  (double itemWidth, double barHeight, double bottomPad, double barWidth)
  _layoutForWidth(double screenWidth, _Breakpoint bp) {
    final tabCount = widget.destinations.length;
    final availableWidth = screenWidth - 32;

    return switch (bp) {
      _Breakpoint.phone => _layoutForDevice(
        tabCount: tabCount,
        preferredItemWidth: _phoneItemWidth,
        barHeight: widget.height ?? _phoneHeight,
        bottomPad: _phoneBottomPad,
        maxBarWidth: _effectiveMaxBarWidth(availableWidth),
      ),
      _Breakpoint.tablet => _layoutForDevice(
        tabCount: tabCount,
        preferredItemWidth: _tabletItemWidth,
        barHeight: widget.height ?? _tabletHeight,
        bottomPad: _tabletBottomPad,
        maxBarWidth: _effectiveMaxBarWidth(availableWidth),
      ),
      _Breakpoint.desktop => _layoutForDevice(
        tabCount: tabCount,
        preferredItemWidth: _desktopItemWidth,
        barHeight: widget.height ?? _desktopHeight,
        bottomPad: _desktopBottomPad,
        maxBarWidth: _effectiveMaxBarWidth(
          availableWidth,
          isDesktop: true,
        ),
      ),
    };
  }

  double _effectiveMaxBarWidth(
    double availableWidth, {
    bool isDesktop = false,
  }) {
    if (widget.width != null) {
      return widget.width!.clamp(0.0, availableWidth);
    }
    if (isDesktop) {
      return _desktopMaxBarWidth.clamp(0.0, availableWidth);
    }
    return availableWidth;
  }

  (double itemWidth, double barHeight, double bottomPad, double barWidth)
  _layoutForDevice({
    required int tabCount,
    required double preferredItemWidth,
    required double barHeight,
    required double bottomPad,
    required double maxBarWidth,
  }) {
    if (tabCount == 0) {
      return (0, barHeight, bottomPad, 0);
    }

    final preferredBarWidth = tabCount * preferredItemWidth;
    final barWidth = preferredBarWidth.clamp(0.0, maxBarWidth).toDouble();
    return (barWidth / tabCount, barHeight, bottomPad, barWidth);
  }

  double _safeHorizontalPad(double screenWidth, double barWidth) {
    final available = screenWidth;
    final pad = (available - barWidth) / 2;
    return pad.clamp(16.0, double.infinity);
  }

  double _blurForBreakpoint(_Breakpoint bp) => switch (bp) {
    _Breakpoint.phone => GlassTokens.blurFloating,
    _Breakpoint.tablet => GlassTokens.blurPanel,
    _Breakpoint.desktop => GlassTokens.blurOverlay,
  };
}
