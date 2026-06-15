import 'package:clay_core/clay.dart';
import 'package:test/test.dart';

void main() {
  group('ClayConfigException', () {
    test('toString returns message', () {
      const exception = ClayConfigException('clay.yaml is invalid');
      expect(exception.toString(), 'clay.yaml is invalid');
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
