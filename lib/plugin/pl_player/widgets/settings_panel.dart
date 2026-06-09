import 'package:PiliNext/common/animation/fluid_tokens.dart';
import 'package:PiliNext/common/widgets/player_glass_surface.dart';
import 'package:PiliNext/plugin/pl_player/player_tokens.dart';
import 'package:flutter/material.dart';

/// YouTube-style settings panel that slides in from the right edge of the
/// player and supports a two-level menu hierarchy with push/pop animations.
///
/// Usage:
/// ```dart
/// GlassSettingsPanel.show(
///   context,
///   playerSize: Size(maxWidth, maxHeight),
///   builder: (ctx, pop) => <SettingsTile>[...],
/// );
/// ```
class GlassSettingsPanel extends StatefulWidget {
  const GlassSettingsPanel({
    super.key,
    required this.playerSize,
    required this.rootTitle,
    required this.rootTiles,
    this.onDismissed,
  });

  final Size playerSize;
  final String rootTitle;
  final List<SettingsTile> rootTiles;
  final VoidCallback? onDismissed;

  /// Shows the panel as an overlay anchored to the player rect.
  static OverlayEntry show({
    required BuildContext context,
    required Size playerSize,
    required String rootTitle,
    required List<SettingsTile> Function(VoidCallback dismiss) tilesBuilder,
  }) {
    late final OverlayEntry entry;
    void dismiss() => entry.remove();
    final tiles = tilesBuilder(dismiss);

    entry = OverlayEntry(
      builder: (_) => GlassSettingsPanel(
        playerSize: playerSize,
        rootTitle: rootTitle,
        rootTiles: tiles,
        onDismissed: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }

  @override
  State<GlassSettingsPanel> createState() => _GlassPanelState();
}

// ─── internal page stack ──────────────────────────────────────────────────────

typedef SettingsPanelPageBuilder =
    Widget Function(SettingsPanelNavController nav);

class SettingsPanelNavController {
  SettingsPanelNavController(this._push, this._pop);
  final void Function(SettingsPanelPageBuilder) _push;
  final VoidCallback _pop;

  void push(SettingsPanelPageBuilder page) => _push(page);
  void pop() => _pop();
}

// ─── state ────────────────────────────────────────────────────────────────────

class _GlassPanelState extends State<GlassSettingsPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final CurvedAnimation _slideCurve;
  late final Animation<Offset> _slideAnim;

  final List<SettingsPanelPageBuilder> _stack = [];
  bool _isForward = true;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: FluidTokens.durationLg,
      value: 0,
    );
    _slideCurve = CurvedAnimation(
      parent: _slideController,
      curve: FluidTokens.curveEnter,
      reverseCurve: FluidTokens.curveExit,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(_slideCurve);

    // Root page.
    _stack.add(_buildRootPage);
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideCurve.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _push(SettingsPanelPageBuilder page) {
    setState(() {
      _isForward = true;
      _stack.add(page);
    });
  }

  void _pop() {
    if (_stack.length <= 1) return;
    setState(() {
      _isForward = false;
      _stack.removeLast();
    });
  }

  Future<void> _dismiss() async {
    await _slideController.reverse();
    widget.onDismissed?.call();
  }

  Widget _buildRootPage(SettingsPanelNavController nav) {
    return _SettingsRootPage(
      title: widget.rootTitle,
      tiles: widget.rootTiles,
      nav: nav,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.playerSize;

    // Panel width: 300 or 85% of player width, whichever is smaller.
    final panelW = (size.width * 0.85).clamp(
      PlayerTokens.settingsPanelMinWidth,
      PlayerTokens.settingsPanelMaxWidth,
    );

    final nav = SettingsPanelNavController(_push, _pop);
    final currentPage = _stack.last(nav);

    return Positioned(
      top: 0,
      left: 0,
      width: size.width,
      height: size.height,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // ── dim overlay ──────────────────────────────────────────────────
            GestureDetector(
              onTap: _dismiss,
              child: FadeTransition(
                opacity: _slideCurve,
                child: Container(color: Colors.black.withValues(alpha: 0.45)),
              ),
            ),

            // ── glass panel ──────────────────────────────────────────────────
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: panelW,
              child: SlideTransition(
                position: _slideAnim,
                child: GestureDetector(
                  // Swipe right to dismiss.
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! > 200) {
                      if (_stack.length > 1) {
                        _pop();
                      } else {
                        _dismiss();
                      }
                    }
                  },
                  child: PlayerGlassSurface(
                    sigma: 16,
                    backgroundColor: Colors.black.withValues(alpha: 0.34),
                    thickness: 1.7,
                    border: Border(
                      left: BorderSide(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: FluidTokens.durationMd,
                      switchInCurve: FluidTokens.curveEnter,
                      switchOutCurve: FluidTokens.curveExit,
                      transitionBuilder: (child, anim) {
                        final isEntering = child.key == ValueKey(_stack.length);
                        final dx = _isForward
                            ? (isEntering ? 1.0 : -1.0)
                            : (isEntering ? -1.0 : 1.0);
                        final slideAnim = Tween<Offset>(
                          begin: Offset(dx, 0),
                          end: Offset.zero,
                        ).animate(anim);
                        return SlideTransition(
                          position: slideAnim,
                          child: FadeTransition(
                            opacity: anim,
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(_stack.length),
                        child: currentPage,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── root page ────────────────────────────────────────────────────────────────

class _SettingsRootPage extends StatelessWidget {
  const _SettingsRootPage({
    required this.title,
    required this.tiles,
    required this.nav,
  });

  final String title;
  final List<SettingsTile> tiles;
  final SettingsPanelNavController nav;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
          child: Text(
            title,
            style: PlayerTokens.settingsTitle,
          ),
        ),
        const Divider(color: Color(0x1AFFFFFF), height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: tiles.length,
            itemBuilder: (_, i) => tiles[i]._buildTile(context, nav),
          ),
        ),
      ],
    );
  }
}

// ─── sub page ─────────────────────────────────────────────────────────────────

class _SettingsSubPage<T> extends StatelessWidget {
  const _SettingsSubPage({
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.labelOf,
    required this.onSelect,
    required this.nav,
  });

  final String title;
  final List<T> items;
  final T selectedValue;
  final String Function(T) labelOf;
  final void Function(T) onSelect;
  final SettingsPanelNavController nav;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with back button.
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.white,
              ),
              tooltip: '返回',
              onPressed: nav.pop,
            ),
            Expanded(
              child: Text(
                title,
                style: PlayerTokens.settingsTitle,
              ),
            ),
          ],
        ),
        const Divider(color: Color(0x1AFFFFFF), height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final isSelected = item == selectedValue;
              return _SelectableTile(
                label: labelOf(item),
                isSelected: isSelected,
                onTap: () => onSelect(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── selectable tile ─────────────────────────────────────────────────────────

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
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
      splashColor: Colors.white.withValues(alpha: 0.08),
      highlightColor: Colors.white.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: PlayerTokens.settingsTileLabel.fontSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── public tile types ────────────────────────────────────────────────────────

/// A single entry in the settings panel root list.
sealed class SettingsTile {
  const SettingsTile();

  Widget _buildTile(BuildContext context, SettingsPanelNavController nav);
}

/// A tile that navigates to a sub-page with a list of selectable options.
class SelectionTile<T> extends SettingsTile {
  const SelectionTile({
    required this.icon,
    required this.title,
    required this.getValue,
    required this.labelOf,
    required this.items,
    required this.onSelect,
  });

  final Widget icon;
  final String title;
  final T Function() getValue;
  final String Function(T) labelOf;
  final List<T> items;
  final void Function(T value, VoidCallback popBack) onSelect;

  @override
  Widget _buildTile(BuildContext context, SettingsPanelNavController nav) {
    final current = getValue();
    return _SettingsTileRow(
      icon: icon,
      title: title,
      trailing: labelOf(current),
      hasArrow: items.length > 1,
      onTap: items.length <= 1
          ? null
          : () {
              nav.push(
                (innerNav) => _SettingsSubPage<T>(
                  title: title,
                  items: items,
                  selectedValue: getValue(),
                  labelOf: labelOf,
                  onSelect: (v) => onSelect(v, innerNav.pop),
                  nav: innerNav,
                ),
              );
            },
    );
  }
}

/// A tile that shows a toggle switch.
class SwitchTile extends SettingsTile {
  const SwitchTile({
    required this.icon,
    required this.title,
    required this.getValue,
    required this.onToggle,
  });

  final Widget icon;
  final String title;
  final bool Function() getValue;
  final VoidCallback onToggle;

  @override
  Widget _buildTile(BuildContext context, SettingsPanelNavController nav) {
    final value = getValue();
    return _SettingsTileRow(
      icon: icon,
      title: title,
      trailing: null,
      hasArrow: false,
      onTap: onToggle,
      trailingWidget: Switch(
        value: value,
        onChanged: (_) => onToggle(),
        activeThumbColor: Colors.white,
        activeTrackColor: Colors.white.withValues(alpha: 0.35),
        inactiveThumbColor: Colors.white60,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// A tile that runs an arbitrary action (no sub-page).
class ActionTile extends SettingsTile {
  const ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final Widget icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget _buildTile(BuildContext context, SettingsPanelNavController nav) {
    return _SettingsTileRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: null,
      hasArrow: false,
      onTap: onTap,
    );
  }
}

/// A tile that pushes a fully custom sub-page.
class CustomSubPageTile extends SettingsTile {
  const CustomSubPageTile({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.subPageBuilder,
  });

  final Widget icon;
  final String title;
  final String? trailing;
  final Widget Function(SettingsPanelNavController nav) subPageBuilder;

  @override
  Widget _buildTile(BuildContext context, SettingsPanelNavController nav) {
    return _SettingsTileRow(
      icon: icon,
      title: title,
      trailing: trailing,
      hasArrow: true,
      onTap: () => nav.push(subPageBuilder),
    );
  }
}

// ─── tile row (shared chrome) ─────────────────────────────────────────────────

class _SettingsTileRow extends StatelessWidget {
  const _SettingsTileRow({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.hasArrow,
    required this.onTap,
    this.subtitle,
    this.trailingWidget,
  });

  final Widget icon;
  final String title;
  final String? trailing;
  final String? subtitle;
  final bool hasArrow;
  final VoidCallback? onTap;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withValues(alpha: 0.08),
      highlightColor: Colors.white.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Leading icon
            SizedBox.square(
              dimension: 24,
              child: IconTheme(
                data: const IconThemeData(color: Colors.white, size: 20),
                child: icon,
              ),
            ),
            const SizedBox(width: 14),
            // Title + optional subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: PlayerTokens.settingsTileLabel,
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
            // Trailing value / switch / arrow
            if (trailingWidget != null)
              trailingWidget!
            else if (trailing != null || hasArrow)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trailing != null)
                    Text(
                      trailing!,
                      style: PlayerTokens.settingsTileTrailing,
                    ),
                  if (hasArrow) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Custom sub-page wrapper (for complex sub-pages) ─────────────────────────

/// A generic sub-page scaffold with a back-button header.
/// Used by callers that want to push a fully custom widget.
class SettingsSubPageScaffold extends StatelessWidget {
  const SettingsSubPageScaffold({
    super.key,
    required this.title,
    required this.nav,
    required this.child,
  });

  final String title;
  final SettingsPanelNavController nav;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.white,
              ),
              tooltip: '返回',
              onPressed: nav.pop,
            ),
            Expanded(
              child: Text(
                title,
                style: PlayerTokens.settingsTitle,
              ),
            ),
          ],
        ),
        const Divider(color: Color(0x1AFFFFFF), height: 1),
        Expanded(child: child),
      ],
    );
  }
}
