import 'package:dynamic_form_builder/features/dynamic_form/domain/failures/failure.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exhaustively pattern-matches every [Failure] subtype. If a new subtype
/// is ever added without updating this switch, this file fails to
/// compile — the same guarantee callers of [Failure] get in production.
String describe(Failure failure) => switch (failure) {
  NetworkFailure() => 'network',
  TimeoutFailure() => 'timeout',
  ServerFailure(:final statusCode) => 'server:$statusCode',
  ParseFailure(:final details) => 'parse:$details',
  UnexpectedFailure(:final details) => 'unexpected:$details',
};

void main() {
  test('every failure subtype is distinguishable', () {
    expect(describe(const NetworkFailure()), 'network');
    expect(describe(const TimeoutFailure()), 'timeout');
    expect(describe(const ServerFailure(500)), 'server:500');
    expect(describe(const ParseFailure('bad json')), 'parse:bad json');
    expect(describe(const UnexpectedFailure('boom')), 'unexpected:boom');
  });
}
