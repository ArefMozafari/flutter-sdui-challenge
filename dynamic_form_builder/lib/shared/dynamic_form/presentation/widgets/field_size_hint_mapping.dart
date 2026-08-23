import '../../../../core/design_system/components/ds_field_size.dart';
import '../../domain/models/field_size_hint.dart';

/// Maps Domain's [FieldSizeHint] onto the design system's [DsFieldSize].
/// Presentation is the only layer allowed to depend on both Domain and
/// `core/design_system` (see the `core`/`shared`/`features` boundary rule
/// in the plan doc) — `DsFieldSize` deliberately doesn't know
/// `dynamic_form` exists, so this mapping can't live on either side, only
/// here.
extension FieldSizeHintMapping on FieldSizeHint {
  DsFieldSize get toDs => switch (this) {
    FieldSizeHint.small => DsFieldSize.small,
    FieldSizeHint.medium => DsFieldSize.medium,
    FieldSizeHint.large => DsFieldSize.large,
  };
}
