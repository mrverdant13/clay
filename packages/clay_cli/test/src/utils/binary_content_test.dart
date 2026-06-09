import 'package:clay_cli/src/utils/binary_content.dart';
import 'package:test/test.dart';

void main() {
  group('shouldSkipBinaryContent', () {
    test('returns true for image and binary extensions', () {
      for (final path in [
        'assets/logo.png',
        'assets/logo.PNG',
        'images/banner.webp',
        'assets/icon.jpg',
        'assets/icon.JPEG',
        'assets/app.gif',
        'assets/favicon.ico',
        'lib/app.jar',
        'android/app.keystore',
        'ios/cert.p12',
        'android/debug.jks',
      ]) {
        expect(shouldSkipBinaryContent(path), isTrue, reason: path);
      }
    });

    test('returns true for .DS_Store basenames', () {
      expect(shouldSkipBinaryContent('.DS_Store'), isTrue);
      expect(shouldSkipBinaryContent('nested/.DS_Store'), isTrue);
    });

    test('returns false for text source files', () {
      for (final path in [
        'lib/main.dart',
        'README.md',
        'file.txt',
        'template.mustache',
      ]) {
        expect(shouldSkipBinaryContent(path), isFalse, reason: path);
      }
    });
  });
}
