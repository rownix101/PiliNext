import 'dart:async';

import 'package:PiliNext/plugin/pl_player/widgets/seek_feedback.dart';
import 'package:flutter/material.dart';

class ForwardSeekIndicator extends StatefulWidget {
  final ValueChanged<Duration> onSubmitted;
  final Duration duration;

  const ForwardSeekIndicator({
    super.key,
    required this.onSubmitted,
    required this.duration,
  });

  @override
  State<ForwardSeekIndicator> createState() => ForwardSeekIndicatorState();
}

class ForwardSeekIndicatorState extends State<ForwardSeekIndicator> {
  late Duration duration;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    duration = widget.duration;
    timer = Timer(const Duration(milliseconds: 400), () {
      widget.onSubmitted(duration);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void increment() {
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 400), () {
      widget.onSubmitted(duration);
    });
    setState(() {
      duration += widget.duration;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SeekFeedback(
      duration: duration,
      forward: true,
      onTap: increment,
    );
  }
}
