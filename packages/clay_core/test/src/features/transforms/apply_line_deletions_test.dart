import 'package:clay_core/clay.dart';
import 'package:clay_core/src/features/transforms/apply_line_deletions.dart';
import 'package:test/test.dart';

void main() {
  group('applyLineDeletions', () {
    const input = '''
This is line 1.
This is line 2.
This is line 3.
This is line 4.
This is line 5.
This is line 6.
This is line 7.
This is line 8.
This is line 9.
This is line 10.
This is line 11.
This is line 12.
This is line 13.
This is line 14.
This is line 15.
This is line 16.
This is line 17.
This is line 18.
This is line 19.
This is line 20.
''';

    const expected = '''
This is line 1.
This is line 7.
This is line 8.
This is line 9.
This is line 10.
This is line 11.
This is line 17.
This is line 18.
This is line 19.
This is line 20.
''';

    final lineDeletions = [
      const LineDeletion(
        filePath: 'file/path',
        ranges: [
          LineRange(start: 1, end: 5),
          LineRange(start: 11, end: 15),
        ],
      ),
      const LineDeletion(
        filePath: 'other/file/path',
        ranges: [
          LineRange(start: 2, end: 6),
          LineRange(start: 12, end: 16),
        ],
      ),
    ];

    test('drops matching ranges for the target file path', () {
      final result = applyLineDeletions(
        content: input,
        filePath: 'file/path',
        lineDeletions: lineDeletions,
      );

      expect(result, expected);
    });

    test('returns content unchanged when file path does not match', () {
      final result = applyLineDeletions(
        content: input,
        filePath: 'non-matching/file/path',
        lineDeletions: lineDeletions,
      );

      expect(result, input);
    });

    test('returns content unchanged when no deletions are configured', () {
      final result = applyLineDeletions(
        content: input,
        filePath: 'file/path',
        lineDeletions: const [],
      );

      expect(result, input);
    });
  });
}
