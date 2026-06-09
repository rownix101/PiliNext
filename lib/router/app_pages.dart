import 'package:PiliNext/pages/about/view.dart';
import 'package:PiliNext/pages/article/view.dart';
import 'package:PiliNext/pages/article_list/view.dart';
import 'package:PiliNext/pages/audio/view.dart';
import 'package:PiliNext/pages/blacklist/view.dart';
import 'package:PiliNext/pages/bubble/view.dart';
import 'package:PiliNext/pages/danmaku_block/view.dart';
import 'package:PiliNext/pages/dlna/view.dart';
import 'package:PiliNext/pages/download/view.dart';
import 'package:PiliNext/pages/dynamics/view.dart';
import 'package:PiliNext/pages/dynamics_create_vote/view.dart';
import 'package:PiliNext/pages/dynamics_detail/view.dart';
import 'package:PiliNext/pages/dynamics_topic/view.dart';
import 'package:PiliNext/pages/dynamics_topic_rcmd/view.dart';
import 'package:PiliNext/pages/fan/view.dart';
import 'package:PiliNext/pages/fav/view.dart';
import 'package:PiliNext/pages/fav_create/view.dart';
import 'package:PiliNext/pages/fav_detail/view.dart';
import 'package:PiliNext/pages/fav_search/view.dart';
import 'package:PiliNext/pages/follow/view.dart';
import 'package:PiliNext/pages/follow_search/view.dart';
import 'package:PiliNext/pages/follow_type/follow_same/view.dart';
import 'package:PiliNext/pages/follow_type/followed/view.dart';
import 'package:PiliNext/pages/history/view.dart';
import 'package:PiliNext/pages/history_search/view.dart';
import 'package:PiliNext/pages/home/view.dart';
import 'package:PiliNext/pages/hot/view.dart';
import 'package:PiliNext/pages/later/view.dart';
import 'package:PiliNext/pages/later_search/view.dart';
import 'package:PiliNext/pages/live_dm_block/view.dart';
import 'package:PiliNext/pages/live_room/view.dart';
import 'package:PiliNext/pages/login/view.dart';
import 'package:PiliNext/pages/main/view.dart';
import 'package:PiliNext/pages/main_reply/view.dart';
import 'package:PiliNext/pages/match_info/view.dart';
import 'package:PiliNext/pages/member/view.dart';
import 'package:PiliNext/pages/member_dynamics/view.dart';
import 'package:PiliNext/pages/member_guard/view.dart';
import 'package:PiliNext/pages/member_profile/view.dart';
import 'package:PiliNext/pages/member_search/view.dart';
import 'package:PiliNext/pages/member_upower_rank/view.dart';
import 'package:PiliNext/pages/member_video_web/archive/view.dart';
import 'package:PiliNext/pages/member_video_web/season_series/view.dart';
import 'package:PiliNext/pages/msg_feed_top/at_me/view.dart';
import 'package:PiliNext/pages/msg_feed_top/like_detail/view.dart';
import 'package:PiliNext/pages/msg_feed_top/like_me/view.dart';
import 'package:PiliNext/pages/msg_feed_top/reply_me/view.dart';
import 'package:PiliNext/pages/msg_feed_top/sys_msg/view.dart';
import 'package:PiliNext/pages/music/view.dart';
import 'package:PiliNext/pages/my_reply/view.dart';
import 'package:PiliNext/pages/popular_precious/view.dart';
import 'package:PiliNext/pages/popular_series/view.dart';
import 'package:PiliNext/pages/search/view.dart';
import 'package:PiliNext/pages/search_result/view.dart';
import 'package:PiliNext/pages/search_trending/view.dart';
import 'package:PiliNext/pages/setting/extra_setting.dart';
import 'package:PiliNext/pages/setting/pages/bar_set.dart';
import 'package:PiliNext/pages/setting/pages/color_select.dart';
import 'package:PiliNext/pages/setting/pages/display_mode.dart';
import 'package:PiliNext/pages/setting/pages/font_size_select.dart';
import 'package:PiliNext/pages/setting/pages/logs.dart';
import 'package:PiliNext/pages/setting/pages/play_speed_set.dart';
import 'package:PiliNext/pages/setting/play_setting.dart';
import 'package:PiliNext/pages/setting/privacy_setting.dart';
import 'package:PiliNext/pages/setting/recommend_setting.dart';
import 'package:PiliNext/pages/setting/style_setting.dart';
import 'package:PiliNext/pages/setting/video_setting.dart';
import 'package:PiliNext/pages/setting/simplified_view.dart';
import 'package:PiliNext/pages/settings_search/view.dart';
import 'package:PiliNext/pages/space_setting/view.dart';
import 'package:PiliNext/pages/sponsor_block/view.dart';
import 'package:PiliNext/pages/subscription/view.dart';
import 'package:PiliNext/pages/subscription_detail/view.dart';
import 'package:PiliNext/pages/video/view.dart';
import 'package:PiliNext/pages/webdav/view.dart';
import 'package:PiliNext/pages/webview/view.dart';
import 'package:PiliNext/pages/whisper/view.dart';
import 'package:PiliNext/pages/whisper_detail/view.dart';
import 'package:PiliNext/common/animation/animation.dart';
import 'package:get/get.dart';

class Routes {
  // ── Shorthand constructors for readability ────────────────────
  static DirectionalGetPage<T> _right<T>(String name, GetPageBuilder page) =>
      DirectionalGetPage(
        name: name,
        page: page,
        direction: TransitionDirection.fromRight,
      );

  static DirectionalGetPage<T> _fade<T>(String name, GetPageBuilder page) =>
      DirectionalGetPage(
        name: name,
        page: page,
        direction: TransitionDirection.fade,
      );

  static DirectionalGetPage<T> _bottom<T>(String name, GetPageBuilder page) =>
      DirectionalGetPage(
        name: name,
        page: page,
        direction: TransitionDirection.fromBottom,
      );

  static final List<GetPage<dynamic>> getPages = [
    // ── Root (no transition — managed by _DirectionalTabSwitcher) ──
    GetPage(name: '/', page: () => const MainApp()),
    GetPage(name: '/home', page: () => const HomePage()),
    GetPage(name: '/hot', page: () => const HotPage()),

    // ── Forward / detail navigation (fromRight) ───────────────────
    _right('/videoV', () => const VideoDetailPageV()),
    _right('/webview', () => const WebviewPage()),
    _right('/fav', () => const FavPage()),
    _right('/favDetail', () => const FavDetailPage()),
    _right('/later', () => const LaterPage()),
    _right('/history', () => const HistoryPage()),
    _right('/search', () => const SearchPage()),
    _right('/searchResult', () => const SearchResultPage()),
    _right('/dynamics', () => const DynamicsPage()),
    _right('/dynamicDetail', () => const DynamicDetailPage()),
    _right('/follow', () => const FollowPage()),
    _right('/fan', () => const FansPage()),
    _right('/liveRoom', () => const LiveRoomPage()),
    _right('/member', () => const MemberPage()),
    _right('/memberSearch', () => const MemberSearchPage()),
    _right('/articlePage', () => const ArticlePage()),
    _right('/whisper', () => const WhisperPage()),
    _right('/whisperDetail', () => const WhisperDetailPage()),
    _right('/replyMe', () => const ReplyMePage()),
    _right('/atMe', () => const AtMePage()),
    _right('/likeMe', () => const LikeMePage()),
    _right('/sysMsg', () => const SysMsgPage()),
    _right('/memberDynamics', () => const MemberDynamicsPage()),
    _right('/subscription', () => const SubPage()),
    _right('/subDetail', () => const SubDetailPage()),
    _right('/searchTrending', () => const SearchTrendingPage()),
    _right('/dynTopic', () => const DynTopicPage()),
    _right('/articleList', () => const ArticleListPage()),
    _right('/dynTopicRcmd', () => const DynTopicRcmdPage()),
    _right('/matchInfo', () => const MatchInfoPage()),
    _right('/msgLikeDetail', () => const LikeDetailPage()),
    _right('/musicDetail', () => const MusicDetailPage()),
    _right('/popularSeries', () => const PopularSeriesPage()),
    _right('/popularPrecious', () => const PopularPreciousPage()),
    _right('/followed', () => const FollowedPage()),
    _right('/sameFollowing', () => const FollowSamePage()),
    _right('/download', () => const DownloadPage()),
    _right('/dlna', () => const DLNAPage()),
    _right('/myReply', () => const MyReply()),
    _right('/videoWeb', () => const MemberVideoWeb()),
    _right('/ssWeb', () => const MemberSSWeb()),
    _right('/memberGuard', () => const MemberGuard()),
    _right('/upowerRank', () => const UpowerRankPage()),

    // ── Search overlays (fromRight — same spatial axis as content) ─
    _right('/favSearch', () => const FavSearchPage()),
    _right('/historySearch', () => const HistorySearchPage()),
    _right('/laterSearch', () => const LaterSearchPage()),
    _right('/followSearch', () => const FollowSearchPage()),
    _right('/settingsSearch', () => const SettingsSearchPage()),

    // ── Settings (fade — same-level, no spatial direction) ─────────
    _fade('/setting', () => const SimplifiedSettingsPage()),
    _fade('/recommendSetting', () => const RecommendSetting()),
    _fade('/videoSetting', () => const VideoSetting()),
    _fade('/playSetting', () => const PlaySetting()),
    _fade('/styleSetting', () => const StyleSetting()),
    _fade('/privacySetting', () => const PrivacySetting()),
    _fade('/extraSetting', () => const ExtraSetting()),
    _fade('/blackListPage', () => const BlackListPage()),
    _fade('/colorSetting', () => const ColorSelectPage()),
    _fade('/fontSizeSetting', () => const FontSizeSelectPage()),
    _fade('/displayModeSetting', () => const SetDisplayMode()),
    _fade('/about', () => const AboutPage()),
    _fade('/playSpeedSet', () => const PlaySpeedPage()),
    _fade('/logs', () => const LogsPage()),
    _fade('/danmakuBlock', () => const DanmakuBlockPage()),
    _fade('/sponsorBlock', () => const SponsorBlockPage()),
    _fade('/webdavSetting', () => const WebDavSettingPage()),
    _fade('/barSetting', () => const BarSetPage()),
    _fade('/spaceSetting', () => const SpaceSettingPage()),
    _fade('/liveDmBlockPage', () => const LiveDmBlockPage()),
    _fade('/editProfile', () => const EditProfilePage()),

    // ── Bottom-up panels ──────────────────────────────────────────
    _bottom('/mainReply', () => const MainReplyPage()),
    _bottom('/audio', () => const AudioPage()),
    _bottom('/createFav', () => const CreateFavPage()),
    _bottom('/createVote', () => const CreateVotePage()),
    _bottom('/bubble', () => const BubblePage()),

    // ── Special (fade — modal/auth overlay) ───────────────────────
    _fade('/loginPage', () => const LoginPage()),
  ];
}
