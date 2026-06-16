import 'package:clay_core/src/entities/clay_environment.dart';
import 'package:clay_core/src/features/config/validate_environment.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('validateEnvironmentMap', () {
    test('accepts maps without environment', () {
      expect(
        () => validateEnvironmentMap(const {}),
        returnsNormally,
      );
    });

    test('accepts environment with clay constraint', () {
      expect(
        () => validateEnvironmentMap(const {
          'environment': {'clay': '^0.0.1-dev.1'},
        }),
        returnsNormally,
      );
    });

    test('rejects non-mapping environment values', () {
      expect(
        () => validateEnvironmentMap(const {'environment': 'any'}),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'environment must be a mapping',
          ),
        ),
      );
    });

    test('rejects unknown environment keys', () {
      expect(
        () => validateEnvironmentMap(const {
          'environment': {'mason': '^1.0.0'},
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'environment contains unknown keys: mason',
          ),
        ),
      );
    });

    test('rejects non-string clay values', () {
      expect(
        () => validateEnvironmentMap(const {
          'environment': {'clay': 1},
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'environment.clay must be a string',
          ),
        ),
      );
    });
  });

  group('ClayEnvironment.fromMap', () {
    test('decodes clay constraint strings into VersionConstraint', () {
      final environment = ClayEnvironment.fromMap(const {
        'clay': '^0.0.1-dev.1',
      });

      expect(
        environment.clay,
        VersionConstraint.parse('^0.0.1-dev.1'),
      );
    });

    test('defaults clay to any when omitted', () {
      final environment = ClayEnvironment.fromMap(const {});

      expect(environment.clay, ClayEnvironment.defaultClayConstraint);
    });

    test('rejects invalid clay constraints', () {
      expect(
        () => ClayEnvironment.fromMap(const {'clay': 'not-a-version'}),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('environment.clay must be a valid semver constraint'),
          ),
        ),
      );
    });
  });
}
