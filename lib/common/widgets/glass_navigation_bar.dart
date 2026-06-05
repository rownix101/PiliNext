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
    final (itemWidth, barHeight, bottomPad, barWidth) =
        _layoutForWidth(screenWidth);

    final effectiveBottomPad = widget.bottomPadding ?? bottomPad;

    return AnimatedBuilder(
      animation: _visibilityController,
      builder: (context, child) {
        final visibilityValue = _visibilityController.value;
        return Transform.translate(
          offset: Offset(0, (1 - visibilityValue) * (barHeight + effectiveBottomPad + 20)),
          child: Opacity(
            opacity: visibilityValue,
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
        child: GlassTokens.blurFilter(
          sigma: _blurForWidth(screenWidth),
          child: Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: GlassTokens.opacityFloating),
              borderRadius: AppRadii.fullAll,
              border: Border.fromBorderSide(
                isDark
                    ? GlassTokens.borderDark(colorScheme.outlineVariant)
                    : GlassTokens.borderLight(colorScheme.outlineVariant),
              ),
              boxShadow: AppShadows.of(3, theme.brightness),
            ),
            child: ClipRRect(
              borderRadius: AppRadii.fullAll,
              child: Stack(
                children: [
                  // ── Highlight gradient (top reflection) ───────
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: AppRadii.fullAll,
                          gradient: GlassTokens.highlightGradient(theme.brightness),
                        ),
                      ),
                    ),
                  ),

                  // ── Jelly indicator ──────────────────────────
                  Positioned.fill(
                    child: JellyIndicator(
                      currentIndex: widget.selectedIndex,
                      itemCount: widget.destinations.length,
                      itemWidth: itemWidth,
                      indicatorHeight: barHeight - 12, // 6dp padding each side
                      indicatorColor: colorScheme.primary.withValues(alpha: 0.18),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                    ),
                  ),

                  // ── Tab items ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.destinations.length, (i) {
                      final dest = widget.destinations[i];
                      final isSelected = i == widget.selectedIndex;

                      return GestureDetector(
                        onTap: () => widget.onDestinationSelected(i),
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: itemWidth,
                          height: barHeight,
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
                                        child: isSelected ? dest.selectedIcon : dest.icon,
                                      )
                                    : (isSelected ? dest.selectedIcon : dest.icon),
                              ),
                              const SizedBox(height: 4),
                              // Label
                              Text(
                                dest.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
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

    if (screenWidth < 600) {
      // Phone
      return (
        _phoneItemWidth,
        _phoneHeight,
        _phoneBottomPad,
        tabCount * _phoneItemWidth,
      );
    } else if (screenWidth <= 1024) {
      // Tablet
      return (
        _tabletItemWidth,
        _tabletHeight,
        _tabletBottomPad,
        (tabCount * _tabletItemWidth).clamp(0, screenWidth * 0.6),
      );
    } else {
      // Desktop
      return (
        _desktopItemWidth,
        _desktopHeight,
        _desktopBottomPad,
        (tabCount * _desktopItemWidth).clamp(0, screenWidth * 0.4),
      );
    }
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
