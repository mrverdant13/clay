import 'package:clay/src/features/preview/preview_exception.dart';
import 'package:test/test.dart';

void main() {
  group('PreviewException', () {
    test('toString returns message', () {
      const exception = PreviewException('file not found');

      expect(exception.toString(), 'file not found');
    });
  });
}
