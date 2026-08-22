import 'package:flutter/painting.dart';

/// Color tokens. `brandSeed` drives the whole Material 3 [ColorScheme] via
/// `ColorScheme.fromSeed` in `app_theme.dart` — most roles (primary,
/// surface, outline, …) are derived, not hand-picked, so they stay
/// harmonized automatically. `success`/`warning` are hand-picked because
/// Material 3's [ColorScheme] has no semantic role for them (only `error`),
/// and the standing rule is that error styling is reserved for errors —
/// warnings need their own distinct color, not a diluted red.
///
/// These are placeholder brand values, not a real design language — swap
/// `brandSeed` for the real palette when one exists; every other role
/// re-derives from it automatically.
abstract final class AppColors {
  static const Color brandSeed = Color(0xFF3457D5);

  static const Color success = Color(0xFF2E7D32);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFB26A00);
  static const Color onWarning = Color(0xFFFFFFFF);
}
