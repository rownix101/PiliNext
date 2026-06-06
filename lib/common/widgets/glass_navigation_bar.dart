import 'package:PiliNext/common/animation/animation.dart';
import 'package:PiliNext/common/design/design_tokens.dart';
import 'package:flutter/material.dart';

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
/// - Adaptive layout: phone/tablet/desktop
/// - Auto-hide on scroll (via [visible] parameter)
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
  });

  /// Currently selected tab index.
  final int selectedIndex;

  /// Tab destinations (4 max recommended).
  final List<GlassNavigationDestination> destinations;

  /// Called when a tab is tapped.
  final ValueChanged<int> onDestinationSelected;

  /// Whether the bar is visible (for scroll-hide behavior).
  final bool visible;

  /// Override width. If null, auto-calculated from device type.
  final double? width;

  /// Override height. If null, auto-calculated from device type.
  final double? height;

  /// Override bottom padding (e.g., for system nav bar).
  final double? bottomPadding;

  @override
  State<GlassNavigationBar> createState() => _GlassNavigationBarState();
}

class _GlassNavigationBarState extends State<GlassNavigationBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _visibilityController;

  @override
  void initState() {
    super.initState();
    _visibilityController = AnimationController(
      vsync: this,
      duration: FluidTokens.durationMd,
      value: widget.visible ? 1.0 : 0.0,
    );
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
    super.dispose();
  }

  // ── Layout calculation ───────────────────────────────────────

  static const double _phoneItemWidth = 80;
  static const double _phoneHeight = 64;
  static const double _phoneBottomPad = 8;

  static const double _tabletItemWidth = 120;
  static const double _tabletHeight = 72;
  static const double _tabletBottomPad = 12;

  static const double _desktopItemWidth = 140;
  static const double _desktopHeight = 80;
  static const double _desktopBottomPad = 16;

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Determine device layout
    final (itemWidth, barHeight, bottomPad, barWidth) = _layoutForWidth(
      screenWidth,
    );
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
            : Curves.easeOutCubic.transform(_visibilityController.value);
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
      child: Padding(
        padding: EdgeInsets.only(
          left: _safeHorizontalPad(screenWidth, barWidth),
          right: _safeHorizontalPad(screenWidth, barWidth),
          bottom: effectiveBottomPad,
        ),
        child: ClipRRect(
          borderRadius: AppRadii.fullAll,
          child: GlassTokens.blurFilter(
            sigma: _blurForWidth(screenWidth),
            child: Container(
              width: barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(
                  alpha: GlassTokens.opacityFloating,
                ),
                borderRadius: AppRadii.fullAll,
                border: Border.fromBorderSide(
                  isDark
                      ? GlassTokens.borderDark(colorScheme.outlineVariant)
                      : GlassTokens.borderLight(colorScheme.outlineVariant),
                ),
                boxShadow: AppShadows.of(3, theme.brightness),
              ),
              child: Stack(
                children: [
                  // ── Highlight gradient (top reflection) ───────
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: AppRadii.fullAll,
                          gradient: GlassTokens.highlightGradient(
                            theme.brightness,
                          ),
                        ),
                      ),
                    ),
                  ),

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
                    children: List.generate(widget.destinations.length, (i) {
                      final dest = widget.destinations[i];
                      final isSelected = i == selectedIndex;

                      return Expanded(
                        child: Semantics(
                          button: true,
                          selected: isSelected,
                          label: dest.label,
                          child: InkResponse(
                            onTap: () => widget.onDestinationSelected(i),
                            containedInkWell: true,
                            radius: 36,
                            highlightShape: BoxShape.rectangle,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Icon with optional badge
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
                                      // Label
                                      Text(
                                        dest.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
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
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Layout helpers ───────────────────────────────────────────

  (double itemWidth, double barHeight, double bottomPad, double barWidth)
  _layoutForWidth(double screenWidth) {
    final tabCount = widget.destinations.length;
    final availableWidth = screenWidth - 32;

    if (screenWidth < 600) {
      return _layoutForDevice(
        tabCount: tabCount,
        preferredItemWidth: _phoneItemWidth,
        barHeight: widget.height ?? _phoneHeight,
        bottomPad: _phoneBottomPad,
        maxBarWidth: _maxBarWidth(availableWidth),
      );
    } else if (screenWidth <= 1024) {
      return _layoutForDevice(
        tabCount: tabCount,
        preferredItemWidth: _tabletItemWidth,
        barHeight: widget.height ?? _tabletHeight,
        bottomPad: _tabletBottomPad,
        maxBarWidth: _maxBarWidth(availableWidth),
      );
    } else {
      return _layoutForDevice(
        tabCount: tabCount,
        preferredItemWidth: _desktopItemWidth,
        barHeight: widget.height ?? _desktopHeight,
        bottomPad: _desktopBottomPad,
        maxBarWidth: _maxBarWidth(availableWidth),
      );
    }
  }

  double _maxBarWidth(double availableWidth) {
    final requestedWidth = widget.width;
    return requestedWidth == null
        ? availableWidth
        : requestedWidth.clamp(0.0, availableWidth).toDouble();
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
    // Center the bar, ensuring minimum side padding
    final available = screenWidth;
    final pad = (available - barWidth) / 2;
    return pad.clamp(16.0, double.infinity);
  }

  double _blurForWidth(double screenWidth) {
    // Tier management: cap blur on lower-end devices
    if (screenWidth < 600) return GlassTokens.blurFloating;
    if (screenWidth <= 1024) return GlassTokens.blurPanel;
    return GlassTokens.blurOverlay;
  }
}
