import 'package:clay_core/src/utils/version_constraint_hook.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('VersionConstraintHook', () {
    const hook = VersionConstraintHook();

    test('decodes null values', () {
      final result = hook.beforeDecode(null);
      expect(result, isNull);
    });

    test('passes through existing VersionConstraint values', () {
      final input = VersionConstraint.parse('^1.0.0');
      expect(hook.beforeDecode(input), same(input));
    });

    test('decodes plain string constraints', () {
      final result = hook.beforeDecode('^0.0.1-dev.1');
      expect(result, isA<VersionConstraint>());
      expect(
        (result! as VersionConstraint).allows(Version.parse('0.0.1-dev.1')),
        isTrue,
      );
    });

    test('decodes any constraint', () {
      final result = hook.beforeDecode('any');
      expect(result, VersionConstraint.any);
    });

    test('rejects non-string values', () {
      expect(
        () => hook.beforeDecode(1),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'environment.clay must be a string',
          ),
        ),
      );
    });

    test('rejects empty constraints', () {
      expect(
        () => hook.beforeDecode(''),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'environment.clay must not be empty',
          ),
        ),
      );
    });

    test('rejects invalid constraints', () {
      expect(
        () => hook.beforeDecode('not-a-version'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('environment.clay must be a valid semver constraint'),
          ),
        ),
      );
    });

    test('encodes constraints as strings', () {
      expect(
        hook.beforeEncode(VersionConstraint.parse('^0.0.1-dev.1')),
        '^0.0.1-dev.1',
      );
      expect(hook.beforeEncode(VersionConstraint.any), 'any');
    });
  });

  group('parseClayVersionConstraint', () {
    test('parses any constraint', () {
      expect(parseClayVersionConstraint('any'), VersionConstraint.any);
    });

    test('parses caret constraints', () {
      final constraint = parseClayVersionConstraint('^0.0.1-dev.1');
      expect(constraint.allows(Version.parse('0.0.1-dev.1')), isTrue);
      expect(constraint.allows(Version.parse('0.0.1-dev.2')), isTrue);
      expect(constraint.allows(Version.parse('1.0.0')), isFalse);
    });
  });
}
