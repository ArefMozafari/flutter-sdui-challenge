import '../../../domain/models/field_size_hint.dart';

/// Resolves whatever size signal a server field carries into a
/// [FieldSizeHint] — never a raw pixel or hex value.
///
/// Three sources, tried in order:
/// 1. The new-format `style.size` token (`"small"`/`"medium"`/`"large"`).
/// 2. The legacy `props.size` token — same three strings, different nesting.
/// 3. The legacy `style.padding` raw CSS (e.g. `"8px"`), for fields that
///    predate both of the above — snapped to the *nearest* of this
///    resolver's own size anchors.
///
/// [_sizeAnchorsPx] are **not** `core/design_system`'s spacing tokens.
/// Data may only depend on Domain (see architecture — Data never imports
/// core), so these are Data's own small, local proxy scale for "does this
/// field look compact, normal, or roomy", used for exactly one purpose:
/// turning legacy pixels into a token-safe hint before anything reaches a
/// widget. Everything else in the legacy `style` object — `borderRadius`,
/// `margin`, `color` — has no Domain concept to map onto and is dropped
/// entirely, on purpose (see the DTO layer's compatibility-shim docs).
class ServerStyleResolver {
  const ServerStyleResolver();

  static const _knownSizeTokens = {
    'small': FieldSizeHint.small,
    'medium': FieldSizeHint.medium,
    'large': FieldSizeHint.large,
  };

  static const _sizeAnchorsPx = {
    FieldSizeHint.small: 6,
    FieldSizeHint.medium: 10,
    FieldSizeHint.large: 16,
  };

  FieldSizeHint resolveSizeHint({
    Map<String, dynamic>? style,
    Map<String, dynamic>? props,
  }) {
    final fromStyle = _knownSizeTokens[style?['size']];
    if (fromStyle != null) return fromStyle;

    final fromProps = _knownSizeTokens[props?['size']];
    if (fromProps != null) return fromProps;

    final padding = _parseLeadingPx(style?['padding']);
    if (padding != null) return _nearestAnchor(padding);

    return FieldSizeHint.medium;
  }

  FieldSizeHint _nearestAnchor(int px) {
    return _sizeAnchorsPx.entries
        .reduce(
          (closest, candidate) =>
              (px - closest.value).abs() <= (px - candidate.value).abs()
              ? closest
              : candidate,
        )
        .key;
  }

  /// Parses the leading number off a CSS length, e.g. `"8px"` -> `8`, or
  /// shorthand `"10px 0"` -> `10` (only the first value is a size signal
  /// here). Returns null for anything that doesn't start with a number.
  int? _parseLeadingPx(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'^(\d+)').firstMatch(value.trim());
    if (match == null) return null;
    return int.parse(match.group(1)!);
  }
}
