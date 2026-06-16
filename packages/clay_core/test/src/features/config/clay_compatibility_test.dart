import 'package:clay_core/clay.dart';
import 'package:clay_core/config.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('isClayConfigCompatibleWithClay', () {
    test('returns true when environment.clay is any', () {
      expect(isClayConfigCompatibleWithClay(ClayConfig()), isTrue);
    });

    test('returns true when constraint allows the current version', () {
      final config = ClayConfig(
        environment: ClayEnvironment(
          clay: VersionConstraint.parse('^0.0.1-dev.1'),
        ),
      );

      expect(isClayConfigCompatibleWithClay(config), isTrue);
    });

    test('returns false when constraint excludes the current version', () {
      final config = ClayConfig(
        environment: ClayEnvironment(
          clay: VersionConstraint.parse('^0.2.0'),
        ),
      );

      expect(isClayConfigCompatibleWithClay(config), isFalse);
    });
  });

  group('assertClayCompatible', () {
    test('does not throw when environment.clay is any', () {
      expect(() => assertClayCompatible(ClayConfig()), returnsNormally);
    });

    test('does not throw when constraint allows the current version', () {
      final config = ClayConfig(
        environment: ClayEnvironment(
          clay: VersionConstraint.parse('^0.0.1-dev.1'),
        ),
      );

      expect(() => assertClayCompatible(config), returnsNormally);
    });

    test('throws ClayIncompatibleException with actionable message', () {
      final config = ClayConfig(
        environment: ClayEnvironment(
          clay: VersionConstraint.parse('^0.2.0'),
        ),
      );

      expect(
        () => assertClayCompatible(config),
        throwsA(
          isA<ClayIncompatibleException>()
              .having(
                (error) => error.currentVersion,
                'currentVersion',
                packageVersion,
              )
              .having(
                (error) => error.requiredConstraint,
                'requiredConstraint',
                '^0.2.0',
              )
              .having(
                (error) => error.toString(),
                'message',
                'The current clay version is $packageVersion.\n'
                'This project requires clay version ^0.2.0.',
              ),
        ),
      );
    });
  });

  group('environment.clay parsing', () {
    test('rejects invalid constraint strings before compatibility checks', () {
      expect(
        () => ClayEnvironment.fromMap(const {'clay': 'not-a-version'}),
        throwsA(
          predicate<Object>(
            (error) => error.toString().contains(
              'environment.clay must be a valid semver constraint',
            ),
          ),
        ),
      );
    });
  });
}
