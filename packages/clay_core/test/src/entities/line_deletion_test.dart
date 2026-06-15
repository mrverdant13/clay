import 'package:clay_core/clay.dart';
import 'package:test/test.dart';

void main() {
  group('LineDeletion', () {
    test('can be instantiated', () {
      const lineDeletion = LineDeletion(filePath: 'file/path', ranges: []);
      expect(lineDeletion, isA<LineDeletion>());
    });

    test('fromJson', () {
      final lineDeletion = LineDeletion.fromJson(const {
        'filePath': 'file/path',
        'ranges': [
          {'start': 1, 'end': 5},
          {'start': 11, 'end': 15},
        ],
      });
      expect(
        lineDeletion,
        isA<LineDeletion>()
            .having((r) => r.filePath, 'filePath', 'file/path')
            .having(
              (r) => r.ranges,
              'ranges',
              orderedEquals([
                const LineRange(start: 1, end: 5),
                const LineRange(start: 11, end: 15),
              ]),
            ),
      );
    });

    test('can be compared', () {
      const reference = LineDeletion(filePath: 'file/path', ranges: []);
      const same = LineDeletion(filePath: 'file/path', ranges: []);
      const other = LineDeletion(filePath: 'other/file/path', ranges: []);

      expect(reference, same);
      expect(reference, isNot(other));
    });

    test('has consistent hash code', () {
      const reference = LineDeletion(filePath: 'file/path', ranges: []);
      const same = LineDeletion(filePath: 'file/path', ranges: []);
      const other = LineDeletion(filePath: 'other/file/path', ranges: []);

      expect(reference.hashCode, same.hashCode);
      expect(reference.hashCode, isNot(other.hashCode));
    });
  });
}
