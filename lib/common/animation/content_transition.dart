import 'package:flutter/material.dart';

import 'package:PiliNext/common/animation/fluid_tokens.dart';
import 'package:PiliNext/http/loading_state.dart';

/// A widget that animates transitions between Loading, Content, and Error
/// states with purposeful, asymmetric motion.
///
/// - **Content enters** with fade + subtle upward shift (the user is about to
///   engage — draw attention gently).
/// - **Content/Error exits** with a fast fade only (the user already decided
///   to leave — don't slow them down).
/// - **Error enters** with fade only (no directional cue — errors are not
///   "somewhere").
///
/// ```dart
/// Obx(() => ContentTransition(
///   state: controller.loadingState.value,
///   loading: () => const Skeleton(...),
///   content: (data) => MyList(data: data),
///   error: (msg) => HttpError(errMsg: msg, onReload: ...),
/// ))
/// ```
class ContentTransition<T> extends StatefulWidget {
  const ContentTransition({
    super.key,
    required this.state,
    required this.loading,
    required this.content,
    required this.error,
    this.enterDuration = FluidTokens.durationMd,
    this.exitDuration = FluidTokens.durationExitSm,
    this.enterSpring,
  });

  /// Current loading state.
  final LoadingState<T> state;

  /// Builder for the loading state.
  final Widget Function() loading;

  /// Builder for the success state.
  final Widget Function(T data) content;

  /// Builder for the error state.
  final Widget Function(String? errMsg) error;

  /// Enter animation duration.
  final Duration enterDuration;

  /// Exit animation duration (shorter than enter by design).
  final Duration exitDuration;

  /// Optional spring for content entrance.
  final SpringDescription? enterSpring;

  @override
  State<ContentTransition<T>> createState() => _ContentTransitionState<T>();
}

class _ContentTransitionState<T> extends State<ContentTransition<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Widget? _currentChild;
  Widget? _previousChild;
  bool _isContent = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.enterDuration,
      value: 1.0,
    );
    _currentChild = _buildForState(widget.state);
    _isContent = widget.state is Success<T>;
  }

  @override
  void didUpdateWidget(ContentTransition<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_stateTypeChanged(oldWidget.state, widget.state)) {
      _previousChild = _currentChild;
      _currentChild = _buildForState(widget.state);
      _isContent = widget.state is Success<T>;

      _controller.duration = _isContent
          ? widget.enterDuration
          : widget.exitDuration;
      _controller
        ..reset()
        ..forward();
    }
  }

  bool _stateTypeChanged(LoadingState oldState, LoadingState newState) {
    return oldState.runtimeType != newState.runtimeType;
  }

  Widget _buildForState(LoadingState<T> state) {
    return switch (state) {
      Loading() => widget.loading(),
      Success(:final response) => widget.content(response),
      Error(:final errMsg) => widget.error(errMsg),
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (FluidTokens.reduceMotionOf(context)) {
      return _currentChild ?? const SizedBox.shrink();
    }

    final enterCurve = CurvedAnimation(
      parent: _controller,
      curve: FluidTokens.curveEnter,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = enterCurve.value;

        // Exit: previous child fades out fast.
        Widget? exitWidget;
        if (_previousChild != null && t < 1.0) {
          exitWidget = Opacity(
            opacity: (1 - t * 2).clamp(0.0, 1.0),
            child: _previousChild,
          );
        }

        // Enter: new child fades in + optional offset for content.
        final enterOpacity = t.clamp(0.0, 1.0);
        final enterOffset = _isContent
            ? Offset(0, (1 - t) * FluidTokens.contentEnterDy)
            : Offset.zero;

        final enterWidget = Opacity(
          opacity: enterOpacity,
          child: Transform.translate(
            offset: enterOffset,
            child: _currentChild,
          ),
        );

        if (exitWidget != null) {
          return Stack(
            children: [
              exitWidget,
              enterWidget,
            ],
          );
        }
        return enterWidget;
      },
    );
  }
}
