import 'package:PiliNext/common/animation/animated_list_item.dart';
import 'package:PiliNext/common/skeleton/video_card_v.dart';
import 'package:PiliNext/common/style.dart';
import 'package:PiliNext/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliNext/common/widgets/loading_widget/http_error.dart';
import 'package:PiliNext/common/widgets/video_card/video_card_v.dart';
import 'package:PiliNext/http/loading_state.dart';
import 'package:PiliNext/pages/rcmd/controller.dart';
import 'package:PiliNext/utils/grid.dart';
import 'package:PiliNext/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RcmdPage extends StatefulWidget {
  const RcmdPage({super.key});

  @override
  State<RcmdPage> createState() => _RcmdPageState();
}

class _RcmdPageState extends State<RcmdPage>
    with AutomaticKeepAliveClientMixin {
  final RcmdController controller = Get.put(RcmdController());

  /// Tracks whether this is the first successful data load — stagger is
  /// only applied on first appearance, not on load-more or refresh.
  bool _hasAnimatedOnce = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = ColorScheme.of(context);
    return Container(
      clipBehavior: .hardEdge,
      margin: const .symmetric(horizontal: Style.safeSpace),
      decoration: const BoxDecoration(borderRadius: Style.mdRadius),
      child: refreshIndicator(
        onRefresh: controller.onRefresh,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const .only(top: Style.cardSpace, bottom: 100),
              sliver: Obx(
                () => _buildBody(colorScheme, controller.loadingState.value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: Style.cardSpace,
    crossAxisSpacing: Style.cardSpace,
    maxCrossAxisExtent: Pref.recommendCardWidth,
    childAspectRatio: Style.aspectRatio,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(90),
  );

  Widget _buildBody(
    ColorScheme colorScheme,
    LoadingState<List<dynamic>?> loadingState,
  ) {
    // Mark first stagger as done once we have data.
    if (loadingState is Success && !_hasAnimatedOnce) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _hasAnimatedOnce = true;
      });
    }
    return switch (loadingState) {
      Loading() => _buildSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.onLoadMore();
                  }
                  Widget card;
                  if (controller.lastRefreshAt != null) {
                    if (controller.lastRefreshAt == index) {
                      card = GestureDetector(
                        onTap: () => controller
                          ..animateToTop()
                          ..onRefresh(),
                        child: Card(
                          child: Container(
                            alignment: Alignment.center,
                            padding: const .symmetric(horizontal: 10),
                            child: Text(
                              '上次看到这里\n点击刷新',
                              textAlign: .center,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      final actualIndex = index > controller.lastRefreshAt!
                          ? index - 1
                          : index;
                      card = VideoCardV(
                        videoItem: response[actualIndex],
                        onRemove: () {
                          if (controller.lastRefreshAt != null &&
                              actualIndex < controller.lastRefreshAt!) {
                            controller.lastRefreshAt =
                                controller.lastRefreshAt! - 1;
                          }
                          controller.loadingState
                            ..value.data!.removeAt(actualIndex)
                            ..refresh();
                        },
                      );
                    }
                  } else {
                    card = VideoCardV(
                      videoItem: response[index],
                      onRemove: () => controller.loadingState
                        ..value.data!.removeAt(index)
                        ..refresh(),
                    );
                  }

                  // Only stagger on first data appearance.
                  if (!_hasAnimatedOnce) {
                    return AnimatedListItem(index: index, child: card);
                  }
                  return card;
                },
                itemCount: controller.lastRefreshAt != null
                    ? response.length + 1
                    : response.length,
              )
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget get _buildSkeleton => SliverGrid.builder(
    gridDelegate: gridDelegate,
    itemBuilder: (context, index) => const VideoCardVSkeleton(),
    itemCount: 10,
  );
}
