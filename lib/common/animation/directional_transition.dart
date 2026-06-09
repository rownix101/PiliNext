import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:PiliNext/common/animation/fluid_tokens.dart';

/// Direction for page transitions, defining the "where from → where to" axis.
///
/// Each page declares its enter direction. The exit direction is automatically
/// the reverse side of the same axis — a page that enters from the right will
/// exit to the right. This enforces the "从哪里来, 到哪里去" principle.
enum TransitionDirection {
  /// Page slides in from the right edge (with a gentle fade).
  /// Use for: list → detail, forward navigation.
  fromRight,

  /// Page slides in from the left edge.
  /// Use for: back-navigation feel, sidebar panels.
  fromLeft,

  /// Page slides up from the bottom edge.
  /// Use for: bottom sheets, comments panel, pickers.
  fromBottom,

  /// Page slides down from the top edge.
  /// Use for: notification overlays, dropdown panels.
  fromTop,

  /// No directional movement — fade only.
  /// Use for: settings, same-level navigation.
  fade,
}

/// A [GetPage] subclass with directional page transitions.
///
/// Overrides [createRoute] to return a route whose [buildTransitions] respects
/// the declared [direction]. On push the page enters from [direction]; on pop
/// it exits toward [direction] — creating a consistent "从哪里来, 到哪里去"
/// motion loop.
///
/// ```dart
/// DirectionalGetPage(
///   name: '/dynamicDetail',
///   page: () => const DynamicDetailPage(),
///   direction: TransitionDirection.fromRight,
/// )
/// ```
class DirectionalGetPage<T> extends GetPage<T> {
  DirectionalGetPage({
    required super.name,
    required super.page,
    this.direction = TransitionDirection.fromRight,
    this.duration = FluidTokens.durationMd,
    super.title,
    super.participatesInRootNavigator,
    super.maintainState,
    super.parameters,
    super.binding,
    super.bindings,
    super.middlewares,
    super.preventDuplicates,
    super.arguments,
  });

  /// The direction from which the page enters.
  final TransitionDirection direction;

  /// Duration of the transition animation.
  final Duration duration;

  @override
  Route<T> createRoute(BuildContext context) {
    return _DirectionalPageRoute<T>(
      settings: this,
      pageBuilder: page,
      direction: direction,
      transitionDuration: duration,
      maintainState: maintainState,
      middlewares: middlewares,
      binding: binding,
      bindings: bindings,
      title: title,
    );
  }
}

class _DirectionalPageRoute<T> extends PageRoute<T> {
  _DirectionalPageRoute({
    required super.settings,
    required this.pageBuilder,
    required this.direction,
    this.transitionDuration = FluidTokens.durationMd,
    this.maintainState = true,
    this.middlewares,
    this.binding,
    this.bindings,
    this.title,
  });

  final GetPageBuilder? pageBuilder;
  final TransitionDirection direction;
  final List<GetMiddleware>? middlewares;
  final Bindings? binding;
  final List<Bindings>? bindings;
  final String? title;

  @override
  final Duration transitionDuration;

  @override
  final bool maintainState;

  @override
  final bool opaque = true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  Widget? _child;

  Widget _getChild() {
    if (_child != null) return _child!;
    final middlewareRunner = MiddlewareRunner(middlewares);

    final localBindings = [
      ...?bindings,
      ?binding,
    ];
    final bindingsToBind = middlewareRunner.runOnBindingsStart(localBindings);
    if (bindingsToBind != null) {
      for (final b in bindingsToBind) {
        b.dependencies();
      }
    }

    final pageToBuild = middlewareRunner.runOnPageBuildStart(pageBuilder)!;
    _child = middlewareRunner.runOnPageBuilt(pageToBuild());
    return _child!;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: _getChild(),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (FluidTokens.reduceMotionOf(context)) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: FluidTokens.curveStandard,
        ),
        child: child,
      );
    }

    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: FluidTokens.curveEnter,
      reverseCurve: FluidTokens.curveExit,
    );

    final beginOffset = _offsetForDirection(direction);
    // Exit uses a smaller offset — user already knows where they came from.
    final exitOffset = _exitOffsetForDirection(direction);

    final isForward = animation.status == AnimationStatus.forward ||
        animation.status == AnimationStatus.completed;

    return SlideTransition(
      position: Tween<Offset>(
        begin: isForward ? beginOffset : exitOffset,
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    MiddlewareRunner(middlewares).runOnPageDispose();
  }

  static Offset _offsetForDirection(TransitionDirection direction) {
    switch (direction) {
      case TransitionDirection.fromRight:
        return const Offset(0.04, 0.0);
      case TransitionDirection.fromLeft:
        return const Offset(-0.04, 0.0);
      case TransitionDirection.fromBottom:
        return const Offset(0.0, 0.04);
      case TransitionDirection.fromTop:
        return const Offset(0.0, -0.04);
      case TransitionDirection.fade:
        return Offset.zero;
    }
  }

  /// Exit offsets are smaller — the user already knows the spatial relationship.
  static Offset _exitOffsetForDirection(TransitionDirection direction) {
    switch (direction) {
      case TransitionDirection.fromRight:
        return const Offset(0.025, 0.0);
      case TransitionDirection.fromLeft:
        return const Offset(-0.025, 0.0);
      case TransitionDirection.fromBottom:
        return const Offset(0.0, 0.025);
      case TransitionDirection.fromTop:
        return const Offset(0.0, -0.025);
      case TransitionDirection.fade:
        return Offset.zero;
    }
  }
}
