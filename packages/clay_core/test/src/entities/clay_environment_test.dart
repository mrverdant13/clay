import 'package:clay_core/clay.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('ClayEnvironment', () {
    test('defaults clay constraint to any', () {
      final environment = ClayEnvironment();
      expect(environment.clay, ClayEnvironment.defaultClayConstraint);
    });

    test('fromMap with explicit clay constraint', () {
      final environment = ClayEnvironment.fromMap(const {
        'clay': r'^0.0.1-dev.1',
      });
      expect(
        environment.clay,
        VersionConstraint.parse(r'^0.0.1-dev.1'),
      );
    });

    test('fromMap applies default when clay is omitted', () {
      final environment = ClayEnvironment.fromMap(const {});
      expect(environment.clay, ClayEnvironment.defaultClayConstraint);
    });

    test('can be compared', () {
      final reference = ClayEnvironment();
      final same = ClayEnvironment();
      final other = ClayEnvironment(
        clay: VersionConstraint.parse('^1.0.0'),
      );

      expect(reference, same);
      expect(reference, isNot(other));
    });
  });
}
