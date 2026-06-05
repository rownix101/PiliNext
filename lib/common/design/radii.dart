import 'package:flutter/material.dart';

/// PiliNext border radius system.
///
/// Based on 4dp multiples. All radii use [BorderRadius] or [Radius] values.
abstract final class AppRadii {
  AppRadii._();

  /// 4dp — chips, badges, small tags
  static const Radius xs = Radius.circular(4);
  static const BorderRadius xsAll = BorderRadius.all(xs);

  /// 8dp — buttons, inputs, text fields
  static const Radius sm = Radius.circular(8);
  static const BorderRadius smAll = BorderRadius.all(sm);

  /// 12dp — cards, list tiles
  static const Radius md = Radius.circular(12);
  static const BorderRadius mdAll = BorderRadius.all(md);

  /// 16dp — panels, sheets, dialogs
  static const Radius lg = Radius.circular(16);
  static const BorderRadius lgAll = BorderRadius.all(lg);

  /// 24dp — modals, large glass panels
  static const Radius xl = Radius.circular(24);
  static const BorderRadius xlAll = BorderRadius.all(xl);

  /// 999dp — pill shapes, navigation indicator, full-round elements
  static const Radius full = Radius.circular(999);
  static const BorderRadius fullAll = BorderRadius.all(full);

  /// Bottom sheet top corners (18dp as per original Style)
  static const BorderRadius bottomSheet = BorderRadius.vertical(
    top: Radius.circular(18),
  );
}
