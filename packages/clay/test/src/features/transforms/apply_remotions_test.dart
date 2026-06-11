import 'package:clay/src/features/transforms/apply_remotions.dart';
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

    group('drop markers inside remove blocks', () {
      const cases = [
        (
          flavor: '/* */',
          start: '/*remove-start*/',
          drop: '/*drop*/',
          end: '/*remove-end*/',
        ),
        (
          flavor: '# #',
          start: '#remove-start#',
          drop: '#drop#',
          end: '#remove-end#',
        ),
        (
          flavor: '<!-- -->',
          start: '<!--remove-start-->',
          drop: '<!--drop-->',
          end: '<!--remove-end-->',
        ),
      ];

      for (final markerCase in cases) {
        test(
          'removes entire block when ${markerCase.drop} is nested '
          '(${markerCase.flavor})',
          () {
          final input = '''
line 0
${markerCase.start}
before drop
${markerCase.drop}
after drop
${markerCase.end}
line 1
''';

          const expected = '''
line 0

line 1
''';

          final result = applyRemotions(content: input);

          expect(result, expected);
          expect(result, isNot(contains('remove-start')));
          expect(result, isNot(contains('remove-end')));
          expect(result, isNot(contains(markerCase.drop)));
          },
        );
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
