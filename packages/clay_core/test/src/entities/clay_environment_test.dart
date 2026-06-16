import 'package:clay_core/clay.dart';
import 'package:test/test.dart';

void main() {
  group('ClayEnvironment', () {
    test('defaults clay constraint to any', () {
      const environment = ClayEnvironment();
      expect(environment.clay, ClayEnvironment.defaultClayConstraint);
    });

    test('fromMap with explicit clay constraint', () {
      final environment = ClayEnvironment.fromMap(const {
        'clay': '^0.0.1-dev.1',
      });
      expect(environment.clay, '^0.0.1-dev.1');
    });

    test('fromMap applies default when clay is omitted', () {
      final environment = ClayEnvironment.fromMap(const {});
      expect(environment.clay, ClayEnvironment.defaultClayConstraint);
    });

    test('can be compared', () {
      const reference = ClayEnvironment();
      const same = ClayEnvironment();
      const other = ClayEnvironment(clay: '^1.0.0');

      expect(reference, same);
      expect(reference, isNot(other));
    });
  });
}
