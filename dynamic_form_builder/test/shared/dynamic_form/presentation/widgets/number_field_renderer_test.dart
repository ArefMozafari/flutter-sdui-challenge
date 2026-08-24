import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/number_field_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseLocalizedNumber', () {
    test('parses ASCII digits', () {
      expect(parseLocalizedNumber('2019'), 2019);
      expect(parseLocalizedNumber('  2019  '), 2019);
      expect(parseLocalizedNumber('12.5'), 12.5);
      expect(parseLocalizedNumber('-3'), -3);
    });

    test('parses Persian digits, which a fa keyboard actually produces', () {
      // The exact input that used to read as empty while the field showed it.
      expect(parseLocalizedNumber('۲۰۱۹'), 2019);
      expect(parseLocalizedNumber('۰'), 0);
      expect(parseLocalizedNumber('۱۲۳۴۵۶۷۸۹'), 123456789);
    });

    test('parses Arabic-Indic digits', () {
      expect(parseLocalizedNumber('٢٠١٩'), 2019);
      expect(parseLocalizedNumber('٠'), 0);
    });

    test('accepts the Arabic decimal separator', () {
      expect(parseLocalizedNumber('۱۲٫۵'), 12.5);
    });

    test('accepts a sign and mixed scripts in one string', () {
      expect(parseLocalizedNumber('-۳'), -3);
      expect(parseLocalizedNumber('۲0۱9'), 2019);
    });

    test('returns null for what is genuinely not a number', () {
      expect(parseLocalizedNumber(''), isNull);
      expect(parseLocalizedNumber('   '), isNull);
      expect(parseLocalizedNumber('abc'), isNull);
      expect(parseLocalizedNumber('برند'), isNull);
    });

    test('leaves grouping separators unparsable in both scripts', () {
      // Not a feature gap on one side only: ASCII behaves the same way, so
      // neither script is quietly more capable than the other.
      expect(parseLocalizedNumber('1,000'), isNull);
      expect(parseLocalizedNumber('۱٬۰۰۰'), isNull);
    });
  });
}
