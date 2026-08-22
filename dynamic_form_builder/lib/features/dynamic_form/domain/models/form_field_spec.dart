import 'field_size_hint.dart';
import 'field_validation.dart';
import 'select_option.dart';

/// One field in a [FormSpec], as a Dart 3 sealed hierarchy.
///
/// Sealed (not a single class with a `type` string) so that every place
/// that renders or validates a field — the widget registry, the validator —
/// is a `switch` the compiler checks for exhaustiveness. Add a sixth field
/// type and every such switch fails to build until it's handled, instead of
/// silently falling through at runtime.
///
/// The five subtypes below are exactly the five field shapes the server can
/// send (see `dto/form_field_spec_dto.dart` for the wire-format mapping,
/// including the legacy `type: input` + `props.type` discriminator).
sealed class FormFieldSpec {
  const FormFieldSpec({
    required this.name,
    required this.label,
    required this.validation,
    required this.sizeHint,
  });

  /// The key this field's value is submitted under.
  final String name;
  final String label;
  final FieldValidation validation;
  final FieldSizeHint sizeHint;
}

final class TextFieldSpec extends FormFieldSpec {
  const TextFieldSpec({
    required super.name,
    required super.label,
    required super.validation,
    required super.sizeHint,
    this.placeholder,
  });

  final String? placeholder;
}

final class NumberFieldSpec extends FormFieldSpec {
  const NumberFieldSpec({
    required super.name,
    required super.label,
    required super.validation,
    required super.sizeHint,
    this.placeholder,
  });

  final String? placeholder;
}

final class MultilineFieldSpec extends FormFieldSpec {
  const MultilineFieldSpec({
    required super.name,
    required super.label,
    required super.validation,
    required super.sizeHint,
    this.placeholder,
  });

  final String? placeholder;
}

final class SelectFieldSpec extends FormFieldSpec {
  const SelectFieldSpec({
    required super.name,
    required super.label,
    required super.validation,
    required super.sizeHint,
    required this.options,
  });

  final List<SelectOption> options;
}

final class FileFieldSpec extends FormFieldSpec {
  const FileFieldSpec({
    required super.name,
    required super.label,
    required super.validation,
    required super.sizeHint,
  });
}
