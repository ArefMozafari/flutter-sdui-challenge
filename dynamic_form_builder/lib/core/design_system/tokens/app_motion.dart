import 'package:flutter/animation.dart';

/// Motion scale — every `AnimatedContainer`/`AnimatedSwitcher`/implicit
/// transition in the app uses one of these, so nothing feels a beat too
/// fast or too sluggish relative to everything else.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve standard = Curves.easeInOutCubic;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
}
