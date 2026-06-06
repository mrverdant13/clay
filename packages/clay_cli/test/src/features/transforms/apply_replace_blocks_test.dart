import 'package:clay_cli/src/features/transforms/apply_replace_blocks.dart';
import 'package:test/test.dart';

void main() {
  group('applyReplaceBlocks', () {
    test('replaces replaceable blocks with indentation control', () {
      const input = '''
line0
line/*replace-start*/
asdf
asdf asdf
/*with i0*/
// 1
// line2
/*replace-end*/
line3
#replace-start#
asdf
asdf asdf
#with i1#
# line4
# line5
#replace-end#
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

      final result = applyReplaceBlocks(content: input);

      expect(result, expected);
    });

    test('resolves HTML comment replace blocks', () {
      const input = '''
before
<!--replace-start-->
ignored
<!--with i2-->
<!-- line a-->
<!-- line b-->
<!--replace-end-->
after
''';
      const expected = '''
before
  line a
  line b
after
''';

      final result = applyReplaceBlocks(content: input);

      expect(result, expected);
    });

    test('returns content unchanged when no replace blocks are present', () {
      const input = '''
line 0
line 1
line 2
''';

      final result = applyReplaceBlocks(content: input);

      expect(result, input);
    });
  });
}
