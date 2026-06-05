import 'package:PiliNext/http/loading_state.dart';
import 'package:PiliNext/http/user.dart';
import 'package:PiliNext/models_new/follow/data.dart';
import 'package:PiliNext/pages/follow_type/controller.dart';

class FollowSameController extends FollowTypeController {
  @override
  Future<LoadingState<FollowData>> customGetData() =>
      UserHttp.sameFollowing(mid: mid, pn: page);
}
