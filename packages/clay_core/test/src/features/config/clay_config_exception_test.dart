import 'package:clay_core/clay.dart';
import 'package:test/test.dart';

void main() {
  group('ClayConfigException', () {
    test('toString returns message', () {
      const exception = ClayConfigException('clay.yaml is invalid');
      expect(exception.toString(), 'clay.yaml is invalid');
    });
  });

  group('ClayIncompatibleException', () {
    test('toString names current and required versions', () {
      const exception = ClayIncompatibleException(
        currentVersion: '0.0.1-dev.1',
        requiredConstraint: '^0.2.0',
      );

      expect(
        exception.toString(),
        'The current clay version is 0.0.1-dev.1.\n'
        'This project requires clay version ^0.2.0.',
      );
    });
  });

  group('ClayConfigNotFoundException', () {
    test('toString includes searched paths', () {
      const exception = ClayConfigNotFoundException(
        message: 'clay.yaml not found',
        searchedPaths: ['/a/clay.yaml', '/b/clay.yaml'],
      );

      expect(
        exception.toString(),
        contains('clay.yaml not found'),
      );
      expect(exception.toString(), contains('Searched paths:'));
      expect(exception.toString(), contains('/a/clay.yaml'));
      expect(exception.toString(), contains('/b/clay.yaml'));
    });

    test('toString omits searched paths section when empty', () {
      const exception = ClayConfigNotFoundException(
        message: 'clay.yaml not found',
        searchedPaths: [],
      );

      expect(exception.toString(), 'clay.yaml not found');
    });
  });
}
