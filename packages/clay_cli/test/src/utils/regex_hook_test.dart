import 'package:clay_cli/src/utils/regex_hook.dart';
import 'package:test/test.dart';

void main() {
  group('RegexHook', () {
    const hook = RegexHook();

    test('decodes plain string patterns', () {
      final result = hook.beforeDecode(r'^from$');
      expect(result, isA<RegExp>());
      expect((result! as RegExp).pattern, r'^from$');
    });

    test('decodes object patterns with dotAll', () {
      final result = hook.beforeDecode(const {
        'pattern': r'@Dependencies\(\[(.*?)\]\)',
        'dotAll': true,
      });
      expect(result, isA<RegExp>());
      final regex = result! as RegExp;
      expect(regex.pattern, r'@Dependencies\(\[(.*?)\]\)');
      expect(regex.isDotAll, isTrue);
    });

    test('passes through existing RegExp values', () {
      final input = RegExp('existing');
      expect(hook.beforeDecode(input), same(input));
    });
  });
}
