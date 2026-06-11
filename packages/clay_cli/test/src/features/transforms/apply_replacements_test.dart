import 'package:clay/clay.dart';
import 'package:clay_cli/src/features/transforms/apply_replacements.dart';
import 'package:test/test.dart';

void main() {
  group('applyReplacement', () {
    test('replaces pattern matches in input', () {
      final replacement = Replacement(
        from: RegExp(r'some\w?.*\w?pattern'),
        to: 'XxXxXxX',
      );
      const input = 'This is some test pattern.';
      const expected = 'This is XxXxXxX.';

      final actual = applyReplacement(input: input, replacement: replacement);

      expect(actual, expected);
    });

    test('interpolates capture groups in replacement string', () {
      final replacement = Replacement(
        from: RegExp(
          'test pattern with a group value of ([a-z]+)',
          dotAll: true,
        ),
        to: r'replacement ZzZzZzZ (group value: ${1})',
      );
      const input = 'This is a test pattern with a group value of asdf.';
      const expected = 'This is a replacement ZzZzZzZ (group value: asdf).';

      final actual = applyReplacement(input: input, replacement: replacement);

      expect(actual, expected);
    });
  });

  group('applyReplacements', () {
    test('applies replacements sequentially', () {
      final replacements = [
        Replacement(
          from: RegExp('some test pattern'),
          to: 'a replacement XxXxXxX',
        ),
        Replacement(
          from: RegExp('another test pattern'),
          to: 'a replacement YyYyYyY',
        ),
        Replacement(
          from: RegExp(
            'test pattern with a group value of ([a-z]+)',
            dotAll: true,
          ),
          to: r'replacement ZzZzZzZ (group value: ${1})',
        ),
      ];
      const input = 'This is some test pattern. '
          'This is another test pattern. '
          'This is a test pattern with a group value of asdf.';
      const expected = 'This is a replacement XxXxXxX. '
          'This is a replacement YyYyYyY. '
          'This is a replacement ZzZzZzZ (group value: asdf).';

      final actual = applyReplacements(
        input: input,
        replacements: replacements,
      );

      expect(actual, expected);
    });

    test('returns input unchanged when replacements list is empty', () {
      const input = 'This is some test pattern.';

      final actual = applyReplacements(input: input, replacements: const []);

      expect(actual, input);
    });

    test('applies replacements to file paths', () {
      final replacements = [
        Replacement(from: RegExp('reference/'), to: 'template/'),
        Replacement(from: RegExp(r'\.dart$'), to: '.mustache'),
      ];
      const input = 'reference/lib/main.dart';
      const expected = 'template/lib/main.mustache';

      final actual = applyReplacements(
        input: input,
        replacements: replacements,
      );

      expect(actual, expected);
    });
  });
}
