/// One choice in a [SelectFieldSpec].
///
/// Deliberately distinct from `DsSelectOption` (core/design_system): Domain
/// must not import the design system, and the design-system component
/// shouldn't know a "select field" from a form even exists. Presentation
/// maps one onto the other.
class SelectOption {
  const SelectOption({required this.label, required this.value});

  final String label;
  final String value;
}
