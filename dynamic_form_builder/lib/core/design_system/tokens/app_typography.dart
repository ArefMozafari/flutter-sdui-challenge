import 'package:flutter/widgets.dart';

/// Type scale. `fontFamily` is deliberately left as the platform default
/// (Roboto/San Francisco) rather than a bundled brand font — the sample form
/// is Persian, and a bundled Latin display font silently falling back for
/// Farsi glyphs is worse than just using the system font, which always has
/// full script coverage.
abstract final class AppTypography {
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  static const double sizeXs = 11;
  static const double sizeSm = 12;
  static const double sizeMd = 14;
  static const double sizeLg = 16;
  static const double sizeXl = 18;
  static const double sizeXxl = 22;
  static const double sizeXxxl = 28;

  /// Three field-text presets, named to match the server schema's
  /// `style.size` vocabulary (`"small" | "medium" | "large"`) one-to-one —
  /// this is exactly what `ServerStyleResolver` snaps a server hint onto.
  static const TextStyle fieldTextSmall = TextStyle(
    fontSize: sizeSm,
    height: 1.3,
    fontWeight: weightRegular,
  );
  static const TextStyle fieldTextMedium = TextStyle(
    fontSize: sizeMd,
    height: 1.4,
    fontWeight: weightRegular,
  );
  static const TextStyle fieldTextLarge = TextStyle(
    fontSize: sizeLg,
    height: 1.4,
    fontWeight: weightRegular,
  );
}
