import 'package:clay_core/src/entities/clay_environment.dart';
import 'package:clay_core/src/features/config/validate_environment.dart';
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

  group('validateClayEnvironment', () {
    test('accepts any constraint', () {
      expect(
        () => validateClayEnvironment(const ClayEnvironment()),
        returnsNormally,
      );
    });

    test('accepts explicit semver constraints', () {
      expect(
        () => validateClayEnvironment(
          const ClayEnvironment(clay: '^0.0.1-dev.1'),
        ),
        returnsNormally,
      );
    });

    test('rejects empty clay constraints', () {
      expect(
        () => validateClayEnvironment(const ClayEnvironment(clay: '')),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'environment.clay must not be empty',
          ),
        ),
      );
    });
  });
}
