import 'package:clay_core/clay.dart';
import 'package:test/test.dart';

void main() {
  group('LineRange', () {
    test('can be instantiated', () {
      const lineRange = LineRange(start: 1, end: 5);
      expect(lineRange, isA<LineRange>());
    });

    test('fromJson', () {
      final lineRange = LineRange.fromJson(const {'start': 1, 'end': 5});
      expect(
        lineRange,
        isA<LineRange>()
            .having((r) => r.start, 'start', 1)
            .having((r) => r.end, 'end', 5),
      );
    });

    test('can be compared', () {
      const reference = LineRange(start: 1, end: 5);
      const same = LineRange(start: 1, end: 5);
      const other = LineRange(start: 1, end: 6);

      expect(reference, same);
      expect(reference, isNot(other));
    });

    test('has consistent hash code', () {
      const reference = LineRange(start: 1, end: 5);
      const same = LineRange(start: 1, end: 5);
      const other = LineRange(start: 1, end: 6);

      expect(reference.hashCode, same.hashCode);
      expect(reference.hashCode, isNot(other.hashCode));
    });

    test('contains', () {
      const lineRange = LineRange(start: 1, end: 5);
      expect(lineRange.contains(0), isFalse);
      expect(lineRange.contains(1), isTrue);
      expect(lineRange.contains(3), isTrue);
      expect(lineRange.contains(5), isTrue);
      expect(lineRange.contains(6), isFalse);
    });
  });
}
