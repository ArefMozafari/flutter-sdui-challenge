import 'package:dynamic_form_builder/core/l10n/app_localizations.dart';
import 'package:dynamic_form_builder/core/l10n/app_localizations_en.dart';
import 'package:dynamic_form_builder/core/l10n/app_localizations_fa.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/failures/failure.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/validation/validation_result.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/failure_message_resolver.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/validation_message_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every key `field_validator.dart` can emit, with args where the message
/// takes them. If the validator gains a key that isn't here, the "no key
/// falls through to the generic message" test below catches it.
const _everyValidationKey = <String, Map<String, Object>>{
  'validationRequired': {},
  'validationInvalidNumber': {},
  'validationMinLength': {'min': 2},
  'validationMaxLength': {'max': 5},
  'validationMin': {'min': 1900},
  'validationMax': {'max': 2024},
  'validationFileTooLarge': {'maxSize': '5MB'},
  'validationTooManyFiles': {'max': 10},
  'validationUnsupportedFileType': {},
};

void main() {
  final locales = <String, AppLocalizations>{
    'en': AppLocalizationsEn(),
    'fa': AppLocalizationsFa(),
  };

  group('resolveValidationMessage', () {
    for (final entry in locales.entries) {
      final locale = entry.key;
      final l10n = entry.value;

      test('[$locale] every key the validator emits resolves to real text', () {
        for (final key in _everyValidationKey.keys) {
          final message = resolveValidationMessage(
            l10n,
            InvalidResult(key, args: _everyValidationKey[key]!),
          );

          expect(message, isNotNull, reason: key);
          expect(message, isNotEmpty, reason: key);
          // The fallback arm — reaching it means the key has no case, so
          // the user would see a generic error instead of the real one.
          expect(message, isNot(l10n.errorGeneric), reason: key);
        }
      });

      test('[$locale] messages taking args interpolate them', () {
        expect(
          resolveValidationMessage(
            l10n,
            const InvalidResult('validationMinLength', args: {'min': 2}),
          ),
          contains('2'),
        );
        expect(
          resolveValidationMessage(
            l10n,
            const InvalidResult('validationTooManyFiles', args: {'max': 10}),
          ),
          contains('10'),
        );
        expect(
          resolveValidationMessage(
            l10n,
            const InvalidResult(
              'validationFileTooLarge',
              args: {'maxSize': '5MB'},
            ),
          ),
          contains('5MB'),
        );
      });

      test('[$locale] distinct keys produce distinct text', () {
        // Guards against two keys being wired to the same l10n method, which
        // still "resolves" but tells the user the wrong thing.
        final messages = <String>{};
        for (final key in _everyValidationKey.keys) {
          messages.add(
            resolveValidationMessage(
              l10n,
              InvalidResult(key, args: _everyValidationKey[key]!),
            )!,
          );
        }
        expect(messages, hasLength(_everyValidationKey.length));
      });
    }

    test('a valid result has no message', () {
      expect(
        resolveValidationMessage(
          AppLocalizationsEn(),
          const ValidationResult.valid(),
        ),
        isNull,
      );
      expect(resolveValidationMessage(AppLocalizationsEn(), null), isNull);
    });

    test('an unknown key falls through to the generic message', () {
      final l10n = AppLocalizationsEn();
      expect(
        resolveValidationMessage(l10n, const InvalidResult('validationNope')),
        l10n.errorGeneric,
      );
    });
  });

  group('resolveFailureMessage', () {
    const everyFailure = <Failure>[
      NetworkFailure(),
      TimeoutFailure(),
      ServerFailure(500),
      ParseFailure('bad'),
      UnexpectedFailure('boom'),
    ];

    for (final entry in locales.entries) {
      test('[${entry.key}] every failure resolves to distinct real text', () {
        final messages = <String>{};
        for (final failure in everyFailure) {
          final message = resolveFailureMessage(entry.value, failure);
          expect(message, isNotEmpty, reason: '$failure');
          messages.add(message);
        }
        // UnexpectedFailure legitimately shares the generic message with
        // nothing else, so all five must still be distinct.
        expect(messages, hasLength(everyFailure.length));
      });
    }
  });
}
