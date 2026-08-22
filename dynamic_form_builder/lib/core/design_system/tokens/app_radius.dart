import 'package:flutter/widgets.dart';

/// Corner-radius scale, in both raw `double` form (for `BorderRadius.circular`
/// call sites) and pre-built [BorderRadius] form (for the common "all
/// corners" case), so widgets never hardcode a radius value.
abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}
