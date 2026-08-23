import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/dynamic_form_datasource.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/http_dynamic_form_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

SubmissionFile _file(String fieldName, String name) => SubmissionFile(
  fieldName: fieldName,
  fileName: name,
  mimeType: 'image/png',
  bytes: const [1, 2, 3],
);

void main() {
  test('non-file fields become form fields', () {
    final formData = buildSubmitFormData({
      'brand': 'Toyota',
      'year': 2020,
    }, const []);

    final fields = {for (final e in formData.fields) e.key: e.value};
    expect(fields, {'brand': 'Toyota', 'year': '2020'});
  });

  test('every file for a field is kept, not just the last one', () {
    final formData = buildSubmitFormData(const {}, [
      _file('car_images', 'a.png'),
      _file('car_images', 'b.png'),
      _file('car_images', 'c.png'),
    ]);

    final carImageFiles = formData.files.where((e) => e.key == 'car_images');
    expect(carImageFiles, hasLength(3));
    expect(
      carImageFiles.map((e) => e.value.filename),
      containsAll(['a.png', 'b.png', 'c.png']),
    );
  });

  test('files for different fields stay under their own field name', () {
    final formData = buildSubmitFormData(const {}, [
      _file('car_images', 'a.png'),
      _file('receipt', 'r.png'),
    ]);

    expect(formData.files.where((e) => e.key == 'car_images'), hasLength(1));
    expect(formData.files.where((e) => e.key == 'receipt'), hasLength(1));
  });
}
