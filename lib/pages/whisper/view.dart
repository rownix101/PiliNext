import 'package:PiliNext/common/skeleton/whisper_item.dart';
import 'package:PiliNext/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliNext/common/widgets/loading_widget/http_error.dart';
import 'package:PiliNext/grpc/bilibili/app/im/v1.pb.dart';
import 'package:PiliNext/http/loading_state.dart';
import 'package:PiliNext/pages/whisper/controller.dart';
import 'package:PiliNext/pages/whisper/widgets/item.dart';
import 'package:PiliNext/utils/extension/theme_ext.dart';
import 'package:PiliNext/utils/extension/three_dot_ext.dart';
import 'package:PiliNext/utils/theme_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class WhisperPage extends StatefulWidget {
  const WhisperPage({super.key});

  @override
  State<WhisperPage> createState() => _WhisperPageState();
}

class _WhisperPageState extends State<WhisperPage> {
  final _controller = Get.put(WhisperController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: null,
        actions: [
          Obx(
            () => IconButton(
              tooltip: _controller.accountService.isLogin.value ? '新增粉丝' : '登录',
              onPressed: _controller.accountService.isLogin.value
                  ? () => Get.toNamed(
                      '/webview',
                      parameters: {
                        'url':
                            'https://www.bilibili.com/h5/follow/newFans?navhide=1&${ThemeUtils.themeUrl(theme.isDark)}',
                      },
                    )
                  : _openLogin,
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ),
          Obx(() {
            final outsideItem = _controller.outsideItem.value;
            if (outsideItem != null && outsideItem.isNotEmpty) {
              return Row(
                mainAxisSize: .min,
                children: outsideItem.map((e) {
                  return IconButton(
                    tooltip: e.hasTitle() ? e.title : null,
                    onPressed: () => e.type.action(
                      context: context,
                      controller: _controller,
                      item: e,
                    ),
                    icon: e.type.icon,
                  );
                }).toList(),
              );
            }
            return const SizedBox.shrink();
          }),
          Obx(() {
            final threeDotItems = _controller.threeDotItems.value;
            if (threeDotItems != null && threeDotItems.isNotEmpty) {
              return PopupMenuButton(
                itemBuilder: (context) {
                  return threeDotItems
                      .map(
                        (e) => PopupMenuItem(
                          onTap: () => e.type.action(
                            context: context,
                            controller: _controller,
                            item: e,
                          ),
                          child: Row(
                            children: [
                              e.type.icon,
                              Text('  ${e.title}'),
                            ],
                          ),
                        ),
                      )
                      .toList();
                },
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(width: 5),
        ],
      ),
      body: Obx(
        () => _controller.accountService.isLogin.value
            ? _buildInbox(theme, padding)
            : const _LoginRequiredState(),
      ),
    );
  }

  Widget _buildInbox(ThemeData theme, EdgeInsets padding) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: refreshIndicator(
          onRefresh: _controller.onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildTopItems(theme, padding),
              SliverPadding(
                padding: EdgeInsets.only(bottom: padding.bottom + 100),
                sliver: Obx(
                  () => _buildBody(_controller.loadingState.value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(LoadingState<List<Session>?> loadingState) {
    late final divider = Divider(
      indent: 72,
      endIndent: 20,
      height: 1,
      color: Colors.grey.withValues(alpha: 0.1),
    );
    return switch (loadingState) {
      Loading() => SliverList.builder(
        itemCount: 12,
        itemBuilder: (context, index) => const WhisperItemSkeleton(),
      ),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverList.separated(
                itemCount: response.length,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _controller.onLoadMore();
                  }
                  final item = response[index];
                  return WhisperSessionItem(
                    item: item,
                    onSetTop: (isTop, id) =>
                        _controller.onSetTop(item, index, isTop, id),
                    onSetMute: (isMuted, talkerUid) =>
                        _controller.onSetMute(item, isMuted, talkerUid),
                    onRemove: (talkerId) =>
                        _controller.onRemove(index, talkerId),
                  );
                },
                separatorBuilder: (context, index) => divider,
              )
            : _MessageEmptyState(onRefresh: _controller.onRefresh),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _controller.onReload,
      ),
    };
  }

  Widget _buildTopItems(ThemeData theme, EdgeInsets padding) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        padding.left + 12,
        8,
        padding.right + 12,
        8,
      ),
      sliver: SliverToBoxAdapter(
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: List.generate(_controller.msgFeedTopItems.length, (
                index,
              ) {
                final item = _controller.msgFeedTopItems[index];
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (!item.enabled) {
                        SmartDialog.showToast('已禁用');
                        return;
                      }
                      _controller.unreadCounts[index] = 0;
                      Get.toNamed(item.route);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Obx(
                            () {
                              final count = _controller.unreadCounts[index];
                              return Badge(
                                isLabelVisible: count > 0,
                                label: Text(" $count "),
                                alignment: Alignment.topRight,
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      theme.colorScheme.onInverseSurface,
                                  child: Icon(
                                    item.icon,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageEmptyState extends StatelessWidget {
  const _MessageEmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                size: 56,
                color: theme.colorScheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text('暂无私信', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                '新的对话会出现在这里',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('刷新'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginRequiredState extends StatelessWidget {
  const _LoginRequiredState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 120),
        child: Semantics(
          container: true,
          label: '登录后查看消息',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_unread_chat_alt_outlined,
                  size: 34,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text('登录后查看消息', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(
                '同步私信、回复、@我和系统通知',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _openLogin,
                icon: const Icon(Icons.login),
                label: const Text('去登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _openLogin() {
  Get.toNamed('/loginPage', parameters: const {'source': 'messages'});
}
