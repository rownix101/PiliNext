import 'package:PiliNext/common/animation/fluid_tokens.dart';
import 'package:PiliNext/common/design/design_tokens.dart';
import 'package:PiliNext/common/widgets/player_glass_surface.dart';
import 'package:PiliNext/plugin/pl_player/player_tokens.dart';
import 'package:flutter/material.dart';

/// Small glass popover card that appears above its trigger.
///
/// Two modes:
/// - [PlayerPopover.items]: simple list of selectable items
/// - [PlayerPopover.builder]: custom content (e.g. speed slider)
class PlayerPopover<T> extends StatefulWidget {
  /// Simple list-of-items popover.
  factory PlayerPopover.items({
    Key? key,
    required Widget Function(VoidCallback open) trigger,
    required List<T> items,
    required T selectedValue,
    required String Function(T) labelOf,
    required ValueChanged<T> onSelect,
    String? tooltip,
  }) {
    return PlayerPopover<T>._(
      key: key,
      trigger: trigger,
      items: items,
      selectedValue: selectedValue,
      labelOf: labelOf,
      onSelect: onSelect,
      tooltip: tooltip,
    );
  }

  /// Custom content popover (e.g. speed panel).
  const PlayerPopover.builder({
    super.key,
    required this.trigger,
    required this.builder,
    this.tooltip,
    this.panelWidth,
  }) : items = null,
       selectedValue = null,
       labelOf = null,
       onSelect = null;

  const PlayerPopover._({
    super.key,
    required this.trigger,
    this.items,
    this.selectedValue,
    this.labelOf,
    this.onSelect,
    this.builder,
    this.tooltip,
    this.panelWidth,
  });

  final Widget Function(VoidCallback open) trigger;
  final Widget Function(BuildContext context, VoidCallback close)? builder;
  final String? tooltip;
  final double? panelWidth;

  final List<T>? items;
  final T? selectedValue;
  final String Function(T)? labelOf;
  final ValueChanged<T>? onSelect;

  @override
  State<PlayerPopover<T>> createState() => _PlayerPopoverState<T>();
}

class _PlayerPopoverState<T> extends State<PlayerPopover<T>>
    with SingleTickerProviderStateMixin {
  final _triggerKey = GlobalKey();
  OverlayEntry? _entry;
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: FluidTokens.durationSm,
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: FluidTokens.curveEnter,
      reverseCurve: FluidTokens.curveExit,
    );
    _fadeAnim = _curve.drive(Tween<double>(begin: 0, end: 1));
    _slideAnim = _curve.drive(
      Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero),
    );
  }

  @override
  void dispose() {
    _removeEntry();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _open() {
    if (_entry != null) return;
    _entry = OverlayEntry(builder: (_) => _buildPopover());
    Overlay.of(context).insert(_entry!);
    _controller.forward();
  }

  void _close() {
    if (_entry == null) return;
    _controller.reverse().then((_) => _removeEntry());
  }

  void _removeEntry() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  Color _bgColor() {
    final cs = ColorScheme.of(context);
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    return cs.surfaceContainerHigh.withValues(alpha: isDark ? 0.30 : 0.38);
  }

  @override
  Widget build(BuildContext context) {
    final triggerWidget = widget.trigger(_open);

    Widget child = GestureDetector(
      key: _triggerKey,
      onTap: _entry == null ? _open : _close,
      child: triggerWidget,
    );

    if (widget.tooltip != null) {
      child = Tooltip(message: widget.tooltip!, child: child);
    }

    return child;
  }

  Widget _buildPopover() {
    final renderBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      return const SizedBox.shrink();
    }

    final triggerPos = renderBox.localToGlobal(Offset.zero);
    final triggerSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    final panelWidth =
        widget.panelWidth ??
        (widget.builder != null ? 288.0 : 200.0).clamp(
          140.0,
          screenSize.width * 0.7,
        );

    final top = triggerPos.dy - 8;
    double left = triggerPos.dx + triggerSize.width / 2 - panelWidth / 2;

    final rightEdge = left + panelWidth;
    if (rightEdge > screenSize.width - 8) {
      left = screenSize.width - panelWidth - 8;
    }
    if (left < 8) {
      left = 8;
    }

    final itemCount = widget.items?.length ?? 0;
    final cardHeight = widget.builder != null
        ? 220.0
        : (itemCount * PlayerTokens.popupMenuItemHeight + 16);
    final showBelow = top - cardHeight < 16;

    return Positioned.fill(
      child: Stack(
        children: [
          // Full-screen tap barrier — dismisses on tap outside.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _close,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Popover card.
          Positioned(
            left: left,
            top: showBelow ? triggerPos.dy + triggerSize.height + 8 : null,
            bottom: showBelow ? null : screenSize.height - top,
            width: panelWidth,
            child: Material(
              color: Colors.transparent,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: PlayerGlassSurface(
                    sigma: 12,
                    backgroundColor: _bgColor(),
                    borderRadius: AppRadii.mdAll,
                    interactive: true,
                    thickness: 1.35,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    child: widget.builder != null
                        ? widget.builder!(context, _close)
                        : _buildDefaultItems(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultItems() {
    final items = widget.items;
    if (items == null) return const SizedBox.shrink();
    final selected = widget.selectedValue;
    final labelOf = widget.labelOf!;
    final onSelect = widget.onSelect!;
    final colorScheme = ColorScheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(items.length, (i) {
        final item = items[i];
        final isSelected = item == selected;
        return _PopoverItem(
          label: labelOf(item),
          isSelected: isSelected,
          onTap: () {
            onSelect(item);
            _close();
          },
          colorScheme: colorScheme,
        );
      }),
    );
  }
}

class _PopoverItem extends StatelessWidget {
  const _PopoverItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withValues(alpha: 0.08),
      highlightColor: Colors.white.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
