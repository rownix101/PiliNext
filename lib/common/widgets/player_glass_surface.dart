import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:PiliNext/common/animation/fluid_tokens.dart';
import 'package:PiliNext/plugin/pl_player/player_tokens.dart';
import 'package:PiliNext/utils/storage.dart';
import 'package:PiliNext/utils/storage_key.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

/// A player control material modeled after Apple's Liquid Glass principles.
///
/// On Impeller this uses a backdrop fragment shader for lensing, subtle
/// chromatic separation, and touch illumination. Other renderers fall back to
/// adaptive frosted glass while preserving the same hierarchy and contrast.
class PlayerGlassSurface extends StatefulWidget {
  const PlayerGlassSurface({
    super.key,
    required this.child,
    this.sigma = 12,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.interactive = false,
    this.thickness = 1,
    this.style,
  });

  final Widget child;
  final double sigma;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final bool interactive;
  final PlayerGlassStyle? style;

  /// Perceived material depth. Larger panels should use a higher value.
  final double thickness;

  @override
  State<PlayerGlassSurface> createState() => _PlayerGlassSurfaceState();
}

class _PlayerGlassSurfaceState extends State<PlayerGlassSurface>
    with SingleTickerProviderStateMixin {
  static const _shaderAsset = 'assets/ui_shaders/liquid_glass.frag';
  static Future<ui.FragmentProgram?>? _programFuture;

  ui.FragmentShader? _shader;
  StreamSubscription<BoxEvent>? _settingSubscription;
  late final AnimationController _pressController;
  Offset _touch = const Offset(0.5, 0.5);

  PlayerGlassStyle get _style {
    if (widget.style case final style?) return style;
    final index = GStorage.setting.get(
      SettingBoxKey.playerGlassStyle,
      defaultValue: PlayerGlassStyle.liquidGlass.index,
    );
    return PlayerGlassStyle.values[(index as int).clamp(
      0,
      PlayerGlassStyle.values.length - 1,
    )];
  }

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: FluidTokens.durationSm,
      reverseDuration: FluidTokens.durationMd,
    )..addListener(_rebuild);
    if (widget.style == null) {
      _settingSubscription = GStorage.setting
          .watch(key: SettingBoxKey.playerGlassStyle)
          .listen((_) => _handleStyleChanged());
    }
    _loadShader();
  }

  @override
  void didUpdateWidget(PlayerGlassSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style != widget.style &&
        _style == PlayerGlassStyle.liquidGlass) {
      _loadShader();
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _handleStyleChanged() {
    if (!mounted) return;
    setState(() {});
    if (_style == PlayerGlassStyle.liquidGlass) _loadShader();
  }

  Future<void> _loadShader() async {
    if (!ui.ImageFilter.isShaderFilterSupported || _shader != null) return;
    _programFuture ??= ui.FragmentProgram.fromAsset(
      _shaderAsset,
    ).then<ui.FragmentProgram?>((program) => program);
    final program = await _programFuture;
    if (program == null) {
      _programFuture = null;
      return;
    }
    if (!mounted) return;
    setState(() => _shader = program.fragmentShader());
  }

  @override
  void dispose() {
    _settingSubscription?.cancel();
    _pressController
      ..removeListener(_rebuild)
      ..dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.zero;
    final brightness = Theme.of(context).brightness;
    final mediaQuery = MediaQuery.maybeOf(context);
    final highContrast = mediaQuery?.highContrast ?? false;
    final reduceMotion = FluidTokens.reduceMotionOf(context);

    Widget surface = switch (_style) {
      PlayerGlassStyle.transparent => _buildTransparent(
        radius,
        brightness,
      ),
      PlayerGlassStyle.frostedGlass => _buildFrostedGlass(
        radius,
        brightness,
        highContrast: highContrast,
      ),
      PlayerGlassStyle.liquidGlass => _buildLiquidGlass(
        radius,
        brightness,
        highContrast: highContrast,
        reduceMotion: reduceMotion,
      ),
    };

    if (widget.interactive && _style == PlayerGlassStyle.liquidGlass) {
      surface = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          _updateTouch(event.localPosition, context.size);
          if (!reduceMotion) _pressController.forward();
        },
        onPointerMove: (event) =>
            _updateTouch(event.localPosition, context.size),
        onPointerUp: (_) => _pressController.reverse(),
        onPointerCancel: (_) => _pressController.reverse(),
        child: surface,
      );
    }

    return surface;
  }

  void _updateTouch(Offset position, Size? size) {
    if (size == null || size.isEmpty) return;
    setState(() {
      _touch = Offset(
        (position.dx / size.width).clamp(0, 1),
        (position.dy / size.height).clamp(0, 1),
      );
    });
  }

  Widget _buildTransparent(BorderRadius radius, Brightness brightness) {
    final background =
        widget.backgroundColor ??
        (brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.30)
            : Colors.white.withValues(alpha: 0.12));
    return _clip(
      radius,
      DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          border: widget.border,
        ),
        child: widget.child,
      ),
    );
  }

  Widget _buildFrostedGlass(
    BorderRadius radius,
    Brightness brightness, {
    required bool highContrast,
  }) {
    final background = _adaptiveBackground(
      brightness,
      highContrast: highContrast,
      liquid: false,
    );
    return _clip(
      radius,
      BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: widget.sigma,
          sigmaY: widget.sigma,
          tileMode: TileMode.clamp,
        ),
        child: _materialLayers(
          radius,
          background,
          brightness,
          highContrast: highContrast,
        ),
      ),
    );
  }

  Widget _buildLiquidGlass(
    BorderRadius radius,
    Brightness brightness, {
    required bool highContrast,
    required bool reduceMotion,
  }) {
    final shader = _shader;
    final background = _adaptiveBackground(
      brightness,
      highContrast: highContrast,
      liquid: true,
    );
    final blurSigma = highContrast
        ? (widget.sigma + 6).clamp(0.0, 22.0)
        : (widget.sigma * 0.55).clamp(4.0, 10.0);
    ui.ImageFilter filter = ui.ImageFilter.blur(
      sigmaX: blurSigma,
      sigmaY: blurSigma,
      tileMode: TileMode.clamp,
    );

    if (shader != null && ui.ImageFilter.isShaderFilterSupported) {
      final tint = _shaderTint(background, brightness, highContrast);
      shader
        ..setFloat(2, highContrast ? 6.0 : 13.0 * widget.thickness)
        ..setFloat(3, highContrast ? 0.0 : 1.15)
        ..setFloat(4, _touch.dx)
        ..setFloat(5, _touch.dy)
        ..setFloat(6, reduceMotion ? 0.0 : _pressController.value)
        ..setFloat(7, widget.thickness.clamp(0.5, 2.0))
        ..setFloat(8, _cornerRadius(radius))
        ..setFloat(9, brightness == Brightness.dark ? 1 : 0)
        ..setFloat(10, highContrast ? 1 : 0)
        ..setFloat(11, tint.r)
        ..setFloat(12, tint.g)
        ..setFloat(13, tint.b)
        ..setFloat(14, tint.a);
      // The shader performs its own multi-tap scattering. Feeding it the clear
      // backdrop preserves the structures that make refraction perceptible.
      filter = ui.ImageFilter.shader(shader);
    }

    return _clip(
      radius,
      BackdropFilter(
        filter: filter,
        child: _materialLayers(
          radius,
          background,
          brightness,
          highContrast: highContrast,
          energized: reduceMotion ? 0 : _pressController.value,
        ),
      ),
    );
  }

  Color _shaderTint(
    Color background,
    Brightness brightness,
    bool highContrast,
  ) {
    final baseStrength = brightness == Brightness.dark ? 0.18 : 0.22;
    return background.withValues(
      alpha: highContrast ? 0.42 : baseStrength * widget.thickness,
    );
  }

  double _cornerRadius(BorderRadius radius) {
    return [
      radius.topLeft.x,
      radius.topRight.x,
      radius.bottomLeft.x,
      radius.bottomRight.x,
    ].reduce(math.min);
  }

  Color _adaptiveBackground(
    Brightness brightness, {
    required bool highContrast,
    required bool liquid,
  }) {
    if (widget.backgroundColor case final color?) {
      final minimumAlpha = highContrast ? 0.72 : (liquid ? 0.24 : 0.34);
      return color.withValues(alpha: color.a.clamp(minimumAlpha, 0.88));
    }
    if (brightness == Brightness.dark) {
      return Colors.black.withValues(
        alpha: highContrast ? 0.78 : (liquid ? 0.30 : 0.42),
      );
    }
    return Colors.white.withValues(
      alpha: highContrast ? 0.86 : (liquid ? 0.36 : 0.58),
    );
  }

  Widget _materialLayers(
    BorderRadius radius,
    Color background,
    Brightness brightness, {
    required bool highContrast,
    double energized = 0,
  }) {
    final isDark = brightness == Brightness.dark;
    final topHighlight = Colors.white.withValues(
      alpha:
          (highContrast
              ? 0.18
              : isDark
              ? 0.10
              : 0.20) +
          energized * 0.08,
    );
    final border =
        widget.border ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: highContrast ? 0.32 : 0.16)
              : Colors.white.withValues(alpha: highContrast ? 0.72 : 0.46),
          width: highContrast ? 1.25 : 0.8,
        );

    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: radius,
              border: border,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: (isDark ? 0.30 : 0.16) * widget.thickness,
                  ),
                  blurRadius: 14 * widget.thickness,
                  offset: Offset(0, 5 * widget.thickness),
                ),
                BoxShadow(
                  color: Colors.white.withValues(
                    alpha: isDark ? 0.025 : 0.10,
                  ),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    topHighlight,
                    Colors.transparent,
                    Colors.black.withValues(
                      alpha: (isDark ? 0.035 : 0.018) * widget.thickness,
                    ),
                  ],
                  stops: const [0, 0.28, 1],
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }

  Widget _clip(BorderRadius radius, Widget child) {
    return ClipRRect(
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
