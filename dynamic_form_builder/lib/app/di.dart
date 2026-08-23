import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/dynamic_form/application/services/dynamic_form_service.dart';
import '../shared/dynamic_form/data/datasources/dynamic_form_datasource.dart';
import '../shared/dynamic_form/data/datasources/mock_dynamic_form_datasource.dart';
import '../shared/dynamic_form/data/repositories/dynamic_form_repository.dart';

/// The single mock↔real swap point. Every other provider in this graph
/// depends on [dynamicFormDataSourceProvider] transitively (through
/// [dynamicFormRepositoryProvider]), never on a concrete data source
/// directly — so pointing this at `HttpDynamicFormDataSource` instead is
/// the only line that ever needs to change to go live.
///
/// Plain `Provider`s, not `@riverpod` code-gen: each one is pure wiring
/// with no logic of its own, so generation wouldn't earn its keep the way
/// it does for `DynamicFormController`.
final dynamicFormDataSourceProvider = Provider<DynamicFormDataSource>((ref) {
  return MockDynamicFormDataSource();
});

final dynamicFormRepositoryProvider = Provider<DynamicFormRepository>((ref) {
  return DynamicFormRepository(ref.watch(dynamicFormDataSourceProvider));
});

final dynamicFormServiceProvider = Provider<DynamicFormService>((ref) {
  return DynamicFormService(ref.watch(dynamicFormRepositoryProvider));
});
