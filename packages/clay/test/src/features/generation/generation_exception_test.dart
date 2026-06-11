import 'package:clay/src/features/generation/generation_exception.dart';
import 'package:test/test.dart';

void main() {
  group('GenerationException', () {
    test('toString returns message', () {
      const exception = GenerationException('reference directory not found');

      expect(exception.toString(), 'reference directory not found');
    });
  });
}
