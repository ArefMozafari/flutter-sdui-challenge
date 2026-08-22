import 'package:flutter/widgets.dart';

import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Size vocabulary shared by every input component in the design system.
///
/// This is `core/`'s own vocabulary, independent of anything `dynamic_form`
/// declares — a form-agnostic app could use these components with this same
/// enum. When a server-declared field carries a size hint, mapping it onto
/// this type is the presentation layer's job, not core's — see
/// `ServerStyleResolver` (data layer) and the field renderers (presentation
/// layer) for where that mapping actually happens.
enum DsFieldSize {
  small,
  medium,
  large;

  TextStyle get textStyle => switch (this) {
        DsFieldSize.small => AppTypography.fieldTextSmall,
        DsFieldSize.medium => AppTypography.fieldTextMedium,
        DsFieldSize.large => AppTypography.fieldTextLarge,
      };

  double get verticalPadding => switch (this) {
        DsFieldSize.small => AppSpacing.sm,
        DsFieldSize.medium => AppSpacing.md,
        DsFieldSize.large => AppSpacing.lg,
      };
}
