import 'package:clay/clay.dart';
import 'package:test/test.dart';

void main() {
  group('BrickGenConfigException', () {
    test('toString returns message', () {
      const exception = BrickGenConfigException('load failed');

      expect(exception.toString(), 'load failed');
    });
  });

  group('BrickGenConfigNotFoundException', () {
    test('toString includes searched paths when present', () {
      const exception = BrickGenConfigNotFoundException(
        message: 'brick-gen.json not found',
        searchedPaths: ['/a/brick-gen.json', '/b/brick-gen.json'],
      );

      expect(
        exception.toString(),
        '''
brick-gen.json not found
Searched paths:
  /a/brick-gen.json
  /b/brick-gen.json''',
      );
    });

    test('toString returns message only when searched paths are empty', () {
      const exception = BrickGenConfigNotFoundException(
        message: 'brick-gen.json not found',
        searchedPaths: [],
      );

      expect(exception.toString(), 'brick-gen.json not found');
    });
  });
}
