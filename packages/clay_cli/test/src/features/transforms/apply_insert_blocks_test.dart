import 'package:clay_cli/src/features/transforms/apply_insert_blocks.dart';
import 'package:test/test.dart';

void main() {
  group('applyInsertBlocks', () {
    test('inlines insert blocks from C-style and hash comments', () {
      const input = '''
line0
line/*insert-start*/
// 1
// line2
/*insert-end*/
line3
#insert-start#
# line4
# line5
#insert-end#
line6
''';
      const expected = '''
line0
line1
line2
line3
line4
line5
line6
''';

      final result = applyInsertBlocks(content: input);

      expect(result, expected);
    });

    test('resolves HTML comment insert blocks', () {
      const input = '''
before
<!--insert-start-->
<!-- line a-->
<!-- line b-->
<!--insert-end-->
after
''';
      const expected = '''
before
line a
line b
after
''';

      final result = applyInsertBlocks(content: input);

      expect(result, expected);
    });

    test('throws FormatException when insert section line is invalid', () {
      const input = '''
line/*insert-start*/
// valid
not a comment
/*insert-end*/
''';

      expect(
        () => applyInsertBlocks(content: input),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('C-style comment'),
              contains('not a comment'),
            ),
          ),
        ),
      );
    });

    test('returns content unchanged when no insert blocks are present', () {
      const input = '''
line 0
line 1
line 2
''';

      final result = applyInsertBlocks(content: input);

      expect(result, input);
    });

    test('resolves insert blocks in CRLF content', () {
      const input = 'line0\r\n'
          'line/*insert-start*/\r\n'
          '// 1\r\n'
          '// line2\r\n'
          '/*insert-end*/\r\n'
          'line3\r\n';
      const expected = 'line0\r\n'
          'line1\n'
          'line2\r\n'
          'line3\r\n';

      final result = applyInsertBlocks(content: input);

      expect(result, expected);
    });
  });
}
