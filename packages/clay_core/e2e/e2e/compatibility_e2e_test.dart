import 'package:clay_core/clay.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  test(
    'isClayConfigCompatibleWithClay accepts default any constraint',
    () {
      expect(isClayConfigCompatibleWithClay(ClayConfig()), isTrue);
    },
    tags: const ['e2e'],
  );

  test(
    'isClayConfigCompatibleWithClay accepts satisfied environment.clay',
    () {
      final config = ClayConfig(
        environment: ClayEnvironment(
          clay: VersionConstraint.parse('^0.0.1-dev.1'),
        ),
      );

      expect(isClayConfigCompatibleWithClay(config), isTrue);
    },
    tags: const ['e2e'],
  );

  test(
    'assertClayCompatible throws for unsatisfied environment.clay',
    () {
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
                clayCoreVersion,
              )
              .having(
                (error) => error.requiredConstraint,
                'requiredConstraint',
                '^0.2.0',
              ),
        ),
      );
    },
    tags: const ['e2e'],
  );
}
