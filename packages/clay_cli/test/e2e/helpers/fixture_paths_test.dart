import 'package:test/test.dart';

import '../../../e2e/e2e/helpers/fixture_paths.dart';

void main() {
  group('referenceTargetFileName', () {
    test('strips the .ref suffix from committed reference fixtures', () {
      expect(
        referenceTargetFileName('widget.dart.ref'),
        'widget.dart',
      );
    });

    test('returns the original name when no .ref suffix is present', () {
      expect(referenceTargetFileName('clay.yaml'), 'clay.yaml');
      expect(referenceTargetFileName('widget.dart'), 'widget.dart');
    });
  });

  group('goldenLogicalPath', () {
    test('strips the .golden suffix from committed golden fixtures', () {
      expect(
        goldenLogicalPath('lib/app/widget.dart.golden'),
        'lib/app/widget.dart',
      );
      expect(
        goldenLogicalPath('pubspec.yaml.golden'),
        'pubspec.yaml',
      );
    });

    test('returns the original path when no .golden suffix is present', () {
      expect(
        goldenLogicalPath('templates/model.html'),
        'templates/model.html',
      );
      expect(
        goldenLogicalPath('{{~ cacheBody.partial }}'),
        '{{~ cacheBody.partial }}',
      );
    });
  });

  group('usesGoldenDiskSuffix', () {
    test('returns true for logical paths ending in .dart or .yaml', () {
      expect(usesGoldenDiskSuffix('lib/main.dart'), isTrue);
      expect(usesGoldenDiskSuffix('pubspec.yaml'), isTrue);
    });

    test('returns false for other logical path extensions', () {
      expect(usesGoldenDiskSuffix('templates/model.html'), isFalse);
      expect(usesGoldenDiskSuffix('schema.sql'), isFalse);
      expect(usesGoldenDiskSuffix('{{~ recordFields.partial }}'), isFalse);
    });
  });

  group('goldenDiskRelativePath', () {
    test('appends .golden for .dart and .yaml logical paths', () {
      expect(
        goldenDiskRelativePath('lib/app/widget.dart'),
        'lib/app/widget.dart.golden',
      );
      expect(
        goldenDiskRelativePath('pubspec.yaml'),
        'pubspec.yaml.golden',
      );
    });

    test('returns the logical path unchanged for other extensions', () {
      expect(
        goldenDiskRelativePath('templates/model.html'),
        'templates/model.html',
      );
      expect(
        goldenDiskRelativePath('{{~ cacheBody.partial }}'),
        '{{~ cacheBody.partial }}',
      );
    });
  });
}
