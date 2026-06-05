import 'package:PiliNext/common/design/design_tokens.dart';
import 'package:flutter/material.dart';

/// Messages tab — first-class navigation destination.
///
/// Provides a unified inbox for all user messages:
/// - @ mentions / replies
/// - Likes received
/// - System notifications
/// - Private messages (whispers)
class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Text(
          '消息',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _MessageRow(
            icon: Icons.reply,
            label: '回复我的',
            onTap: () => _navigate(context, '/msgFeedTop/replyMe'),
          ),
          _MessageRow(
            icon: Icons.thumb_up_outlined,
            label: '收到的赞',
            onTap: () => _navigate(context, '/msgFeedTop/likeMe'),
          ),
          _MessageRow(
            icon: Icons.alternate_email,
            label: '@ 我的',
            onTap: () => _navigate(context, '/msgFeedTop/atMe'),
          ),
          _MessageRow(
            icon: Icons.notifications_outlined,
            label: '系统通知',
            onTap: () => _navigate(context, '/msgFeedTop/sysMsg'),
          ),
          _MessageRow(
            icon: Icons.mail_outline,
            label: '私信',
            onTap: () => _navigate(context, '/whisper'),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.mdAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
