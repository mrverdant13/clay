import 'package:clay_cli/src/features/transforms/skip_content_transforms.dart';
import 'package:test/test.dart';

void main() {
  group('shouldSkipContentTransforms', () {
    test('returns true for .png paths', () {
      expect(shouldSkipContentTransforms('assets/logo.png'), isTrue);
      expect(shouldSkipContentTransforms('assets/logo.PNG'), isTrue);
    });

    test('returns true for .webp paths', () {
      expect(shouldSkipContentTransforms('images/banner.webp'), isTrue);
      expect(shouldSkipContentTransforms('images/banner.WEBP'), isTrue);
    });

    test('returns true for other binary extensions', () {
      expect(shouldSkipContentTransforms('assets/icon.jpg'), isTrue);
      expect(shouldSkipContentTransforms('assets/icon.JPG'), isTrue);
      expect(shouldSkipContentTransforms('assets/app.ico'), isTrue);
      expect(shouldSkipContentTransforms('.DS_Store'), isTrue);
    });

    test('returns false for other extensions', () {
      expect(shouldSkipContentTransforms('lib/main.dart'), isFalse);
      expect(shouldSkipContentTransforms('README.md'), isFalse);
      expect(shouldSkipContentTransforms('file.txt'), isFalse);
    });
  });
}
