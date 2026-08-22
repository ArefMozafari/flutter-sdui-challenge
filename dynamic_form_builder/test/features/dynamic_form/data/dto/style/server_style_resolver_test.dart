import 'package:dynamic_form_builder/features/dynamic_form/data/dto/style/server_style_resolver.dart';
import 'package:dynamic_form_builder/features/dynamic_form/domain/models/field_size_hint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = ServerStyleResolver();

  test('style.size wins outright', () {
    final hint = resolver.resolveSizeHint(style: {'size': 'large'});
    expect(hint, FieldSizeHint.large);
  });

  test('props.size is used when style.size is absent', () {
    final hint = resolver.resolveSizeHint(props: {'size': 'medium'});
    expect(hint, FieldSizeHint.medium);
  });

  test('style.size takes priority over props.size', () {
    final hint = resolver.resolveSizeHint(
      style: {'size': 'small'},
      props: {'size': 'large'},
    );
    expect(hint, FieldSizeHint.small);
  });

  test('legacy padding snaps to the nearest anchor when no token is sent', () {
    expect(
      resolver.resolveSizeHint(style: {'padding': '8px'}),
      FieldSizeHint.small,
    );
    expect(
      resolver.resolveSizeHint(style: {'padding': '10px 0'}),
      FieldSizeHint.medium,
    );
    expect(
      resolver.resolveSizeHint(style: {'padding': '20px'}),
      FieldSizeHint.large,
    );
  });

  test('no signal at all defaults to medium', () {
    expect(resolver.resolveSizeHint(), FieldSizeHint.medium);
  });

  test('an unparsable padding value defaults to medium', () {
    expect(
      resolver.resolveSizeHint(style: {'padding': 'auto'}),
      FieldSizeHint.medium,
    );
  });
}
