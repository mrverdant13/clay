import 'package:clay_cli/src/features/transforms/apply_mustache_tags.dart';
import 'package:test/test.dart';

void main() {
  group('applyMustacheTags', () {
    test('unwraps mustache tags from all comment flavors with x flags', () {
      const input = '''
text
/*x{{some-key}}*/
more text
#{{other-key}}x#
yet more text
and even
<!--x{{yet-another-key}}x-->
more text
''';
      const expected = '''
text{{some-key}}
more text
{{other-key}}yet more text
and even{{yet-another-key}}more text
''';

      final result = applyMustacheTags(content: input);

      expect(result, expected);
    });

    test('retains adjacent whitespace when x flags are absent', () {
      const input = '''
before /*{{name}}*/ after
before #{{name}}# after
before <!--{{name}}--> after
''';
      const expected = '''
before {{name}} after
before {{name}} after
before {{name}} after
''';

      final result = applyMustacheTags(content: input);

      expect(result, expected);
    });

    test('drops only leading whitespace with dropLeading x flag', () {
      const input = 'line /*x{{tag}}*/ rest';

      final result = applyMustacheTags(content: input);

      expect(result, 'line{{tag}} rest');
    });

    test('drops only trailing whitespace with dropTrailing x flag', () {
      const input = 'line #{{tag}}x# rest';

      final result = applyMustacheTags(content: input);

      expect(result, 'line {{tag}}rest');
    });

    test('unwraps multiple tags in the same content', () {
      const input = '''
/*{{a}}*/
middle
#{{b}}#
''';
      const expected = '''
{{a}}
middle
{{b}}
''';

      final result = applyMustacheTags(content: input);

      expect(result, expected);
    });

    test('leaves content without mustache comment wrappers unchanged', () {
      const input = '''
plain text
/* not a mustache comment */
# also not #
<!-- {{unclosed
''';

      final result = applyMustacheTags(content: input);

      expect(result, input);
    });
  });
}
