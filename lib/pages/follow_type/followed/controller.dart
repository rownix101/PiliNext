import 'package:PiliNext/http/loading_state.dart';
import 'package:PiliNext/http/user.dart';
import 'package:PiliNext/models_new/follow/data.dart';
import 'package:PiliNext/pages/follow_type/controller.dart';

class FollowedController extends FollowTypeController {
  @override
  Future<LoadingState<FollowData>> customGetData() =>
      UserHttp.followedUp(mid: mid, pn: page);
}
