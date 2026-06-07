import 'package:PiliNext/pages/whisper/view.dart';
import 'package:flutter/material.dart';

/// The primary messages destination.
///
/// Keep this wrapper separate from [WhisperPage] so the navigation model can
/// evolve without duplicating the inbox implementation.
class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) => const WhisperPage();
}
