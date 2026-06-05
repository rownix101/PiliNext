import 'package:PiliNext/http/loading_state.dart';
import 'package:PiliNext/http/video.dart';
import 'package:PiliNext/models/model_hot_video_item.dart';
import 'package:PiliNext/pages/common/common_list_controller.dart';

class HotController
    extends CommonListController<List<HotVideoItemModel>, HotVideoItemModel> {
  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  Future<LoadingState<List<HotVideoItemModel>>> customGetData() =>
      VideoHttp.hotVideoList(
        pn: page,
        ps: 20,
      );
}
