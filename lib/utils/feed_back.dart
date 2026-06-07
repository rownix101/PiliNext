import 'package:PiliNext/utils/haptic_service.dart';
import 'package:PiliNext/utils/storage_pref.dart';

/// Legacy haptic toggle, mapped to [HapticService].
/// Prefer [HapticService.play] for new code.
bool enableFeedback = Pref.feedBackEnable;

/// Legacy light-impact call. Prefer [HapticService.light] or
/// [HapticService.play](HapticLevel.light) for new code.
void feedBack() {
  HapticService.light();
}
