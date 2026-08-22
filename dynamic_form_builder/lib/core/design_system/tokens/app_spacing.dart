/// Spacing scale. Every gap, padding, and margin in the app is one of these
/// values — never a raw number — so rhythm stays consistent as the design
/// evolves and a single edit here reflows the whole app.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}
