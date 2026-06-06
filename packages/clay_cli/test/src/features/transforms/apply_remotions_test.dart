import 'package:clay_cli/src/features/transforms/apply_remotions.dart';
import 'package:test/test.dart';

void main() {
  group('applyRemotions', () {
    test('removes remove blocks with whitespace control flags', () {
      const input = '''
line   <!--x-remove-start--> asdf
asdf asdf
asdf <!--remove-end-x-->    0
line 1
line  /*x-remove-start*/ asdf
asdf asdf
asdf /*remove-end*/  2
line   #remove-start# asdf
asdf asdf
asdf #remove-end-x#       3
line  <!--remove-start--> asdf
asdf asdf
asdf <!--remove-end-->  4
line 5
''';
      const expected = '''
line0
line 1
line  2
line   3
line    4
line 5
''';

      final result = applyRemotions(content: input);

      expect(result, expected);
    });

    group('drop markers', () {
      const suffix = '''
line 3
line 4
line 5
''';

      for (final dropCase in ['/*drop*/', '#drop#', '<!--drop-->']) {
        test('removes content from $dropCase to end of file', () {
          final input = '''
line 0
line 1
line 2
$dropCase
$suffix''';

          const expected = '''
line 0
line 1
line 2
''';

          final result = applyRemotions(content: input);

          expect(result, expected);
        });
      }
    });

    test('returns content unchanged when no remotion markers are present', () {
      const input = '''
line 0
line 1
line 2
''';

      final result = applyRemotions(content: input);

      expect(result, input);
    });
  });
}
