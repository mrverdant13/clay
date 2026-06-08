import 'package:clay_cli/src/features/validation/validation_exception.dart';
import 'package:test/test.dart';

void main() {
  group('ValidationException', () {
    test('toString returns message', () {
      const exception = ValidationException('reference directory not found');

      expect(exception.toString(), 'reference directory not found');
    });
  });
}
