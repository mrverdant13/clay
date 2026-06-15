import 'package:clay_core/src/utils/regex_hook.dart';
import 'package:test/test.dart';

void main() {
  group('RegexHook', () {
    const hook = RegexHook();

    test('decodes null values', () {
      final result = hook.beforeDecode(null);
      expect(result, isNull);
    });

    test('passes through existing RegExp values', () {
      final input = RegExp('existing');
      expect(hook.beforeDecode(input), same(input));
    });

    test('decodes plain string patterns', () {
      final result = hook.beforeDecode(r'^from$');
      expect(result, isA<RegExp>());
      expect((result! as RegExp).pattern, r'^from$');
    });

    test('decodes object patterns without additional options', () {
      final result = hook.beforeDecode(const {
        'pattern': r'^from$',
      });
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

    test('decodes object patterns with multiLine', () {
      final result = hook.beforeDecode(const {
        'pattern': r'^from$',
        'multiLine': true,
      });
      expect(result, isA<RegExp>());
      expect((result! as RegExp).pattern, r'^from$');
    });

    test('decodes object patterns with unicode', () {
      final result = hook.beforeDecode(const {
        'pattern': r'^from$',
        'unicode': true,
      });
      expect(result, isA<RegExp>());
      expect((result! as RegExp).pattern, r'^from$');
    });

    test('decodes object patterns with caseSensitive', () {
      final result = hook.beforeDecode(const {
        'pattern': r'^from$',
        'caseSensitive': false,
      });
      expect(result, isA<RegExp>());
      expect((result! as RegExp).pattern, r'^from$');
    });

    test('decodes object in its stringified form', () {
      final result = hook.beforeDecode(123);
      expect(result, isA<RegExp>());
      expect((result! as RegExp).pattern, '123');
    });
  });
}
