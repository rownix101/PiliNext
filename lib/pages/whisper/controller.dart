import 'package:PiliNext/grpc/bilibili/app/im/v1.pb.dart'
    show Offset, Session, SessionMainReply, SessionPageType, ThreeDotItem;
import 'package:PiliNext/grpc/im.dart';
import 'package:PiliNext/http/loading_state.dart';
import 'package:PiliNext/models_new/msg/msgfeed_unread.dart';
import 'package:PiliNext/pages/common/common_whisper_controller.dart';
import 'package:PiliNext/services/account_service.dart';
import 'package:PiliNext/utils/storage_pref.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:protobuf/protobuf.dart' show PbMap;

class WhisperController extends CommonWhisperController<SessionMainReply>
    with AccountMixin {
  @override
  final AccountService accountService = Get.find<AccountService>();

  @override
  SessionPageType sessionPageType = SessionPageType.SESSION_PAGE_TYPE_HOME;

  late final List<({bool enabled, IconData icon, String name, String route})>
  msgFeedTopItems;
  late final RxList<int> unreadCounts;

  PbMap<int, Offset>? offset;

  Rx<List<ThreeDotItem>?> threeDotItems = Rx<List<ThreeDotItem>?>(null);
  Rx<List<ThreeDotItem>?> outsideItem = Rx<List<ThreeDotItem>?>(null);

  @override
  void onInit() {
    super.onInit();
    msgFeedTopItems = [
      const (
        name: "回复我的",
        icon: Icons.message_outlined,
        route: "/replyMe",
        enabled: true,
      ),
      const (
        name: "@我",
        icon: Icons.alternate_email_outlined,
        route: "/atMe",
        enabled: true,
      ),
      (
        name: "收到的赞",
        icon: Icons.favorite_border_outlined,
        route: "/likeMe",
        enabled: !accountService.isLogin.value || !Pref.disableLikeMsg,
      ),
      const (
        name: "系统通知",
        icon: Icons.notifications_none_outlined,
        route: "/sysMsg",
        enabled: true,
      ),
    ];
    unreadCounts = List.filled(msgFeedTopItems.length, 0).obs;
    if (accountService.isLogin.value) {
      queryMsgFeedUnread();
      queryData();
    } else {
      loadingState.value = const Error('账号未登录');
    }
  }

  Future<void> queryMsgFeedUnread() async {
    if (!accountService.isLogin.value) return;
    final res = await ImGrpc.getTotalUnread(unreadType: 2);
    if (res case Success(:final response)) {
      final data = MsgFeedUnread.fromJson(response.msgFeedUnread.unread);
      final unreadCounts = [data.reply, data.at, data.like, data.sysMsg];
      if (!listEquals(this.unreadCounts, unreadCounts)) {
        this.unreadCounts.value = unreadCounts;
      }
    } else {
      res.toast();
    }
  }

  @override
  List<Session>? getDataList(SessionMainReply response) {
    offset = response.paginationParams.offsets;
    isEnd = !response.paginationParams.hasMore;
    return response.sessions;
  }

  @override
  bool customHandleResponse(
    bool isRefresh,
    Success<SessionMainReply> response,
  ) {
    if (isRefresh) {
      threeDotItems.value = response.response.threeDotItems;
      outsideItem.value = response.response.outsideItem;
    }
    return false;
  }

  @override
  Future<LoadingState<SessionMainReply>> customGetData() {
    if (!accountService.isLogin.value) {
      return Future.value(const Error('账号未登录'));
    }
    return ImGrpc.sessionMain(offset: offset);
  }

  @override
  Future<void> onRefresh() {
    if (!accountService.isLogin.value) return Future.value();
    offset = null;
    queryMsgFeedUnread();
    return super.onRefresh();
  }

  @override
  void onChangeAccount(bool isLogin) {
    offset = null;
    unreadCounts.fillRange(0, unreadCounts.length, 0);
    if (isLogin) {
      loadingState.value = LoadingState<List<Session>?>.loading();
      queryMsgFeedUnread();
      queryData();
    } else {
      loadingState.value = const Error('账号未登录');
    }
  }
}
