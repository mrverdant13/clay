import 'dart:io';

import 'package:clay/clay.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('resolveReferenceFilePath', () {
    late Directory tempDir;
    late String referencePath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_preview_path_');
      referencePath = p.join(tempDir.path, 'reference');
      Directory(referencePath).createSync(recursive: true);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('resolves paths relative to the reference directory', () {
      final filePath = p.join(referencePath, 'lib', 'main.dart');
      File(filePath).createSync(recursive: true);

      expect(
        resolveReferenceFilePath(
          filePath: 'lib/main.dart',
          referencePath: referencePath,
        ),
        p.normalize(filePath),
      );
    });

    test('accepts absolute paths under the reference directory', () {
      final filePath = p.join(referencePath, 'widget.dart');
      File(filePath).createSync();

      expect(
        resolveReferenceFilePath(
          filePath: filePath,
          referencePath: referencePath,
        ),
        p.normalize(filePath),
      );
    });

    test('throws when the file is outside the reference directory', () {
      final outsideFile = p.join(tempDir.path, 'outside.dart');
      File(outsideFile).createSync();

      expect(
        () => resolveReferenceFilePath(
          filePath: outsideFile,
          referencePath: referencePath,
        ),
        throwsA(
          isA<PreviewException>().having(
            (error) => error.message,
            'message',
            contains('File must be under the reference directory'),
          ),
        ),
      );
    });
  });

  group('assertPreviewPathIsFile', () {
    const path = '/tmp/reference/widget.dart';

    test('allows files', () {
      expect(
        () => assertPreviewPathIsFile(
          path,
          resolveEntityType: (_) => FileSystemEntityType.file,
        ),
        returnsNormally,
      );
    });

    test('throws when the path does not exist', () {
      expect(
        () => assertPreviewPathIsFile(
          path,
          resolveEntityType: (_) => FileSystemEntityType.notFound,
        ),
        throwsA(
          isA<PreviewException>().having(
            (error) => error.message,
            'message',
            'File not found: $path',
          ),
        ),
      );
    });

    test('throws when the path is a directory', () {
      expect(
        () => assertPreviewPathIsFile(
          path,
          resolveEntityType: (_) => FileSystemEntityType.directory,
        ),
        throwsA(
          isA<PreviewException>().having(
            (error) => error.message,
            'message',
            'Path is not a file: $path',
          ),
        ),
      );
    });

    test('throws when the path is a symlink', () {
      expect(
        () => assertPreviewPathIsFile(
          path,
          resolveEntityType: (_) => FileSystemEntityType.link,
        ),
        throwsA(
          isA<PreviewException>().having(
            (error) => error.message,
            'message',
            'Path is not a file: $path',
          ),
        ),
      );
    });

    test('throws when the path is a fifo', () {
      expect(
        () => assertPreviewPathIsFile(
          path,
          resolveEntityType: (_) => FileSystemEntityType.pipe,
        ),
        throwsA(
          isA<PreviewException>().having(
            (error) => error.message,
            'message',
            'Path is not a file: $path',
          ),
        ),
      );
    });

    test('throws when the path is a unix domain socket', () {
      expect(
        () => assertPreviewPathIsFile(
          path,
          resolveEntityType: (_) => FileSystemEntityType.unixDomainSock,
        ),
        throwsA(
          isA<PreviewException>().having(
            (error) => error.message,
            'message',
            'Path is not a file: $path',
          ),
        ),
      );
    });
  });

  group('loadPreviewPartials', () {
    test('returns an empty map when the target directory does not exist', () {
      final tempDir = Directory.systemTemp
          .createTempSync('clay_preview_partials_missing_')
        ..deleteSync();

      expect(loadPreviewPartials(tempDir), isEmpty);
    });

    test('loads partial files created during transformation', () {
      final tempDir =
          Directory.systemTemp.createTempSync('clay_preview_partials_');
      try {
        File(p.join(tempDir.path, '{{~ footer.partial }}'))
          ..createSync(recursive: true)
          ..writeAsStringSync('footer line\n');
        File(p.join(tempDir.path, 'ignored.txt')).createSync();

        expect(
          loadPreviewPartials(tempDir),
          {
            '{{~ footer.partial }}': [
              102,
              111,
              111,
              116,
              101,
              114,
              32,
              108,
              105,
              110,
              101,
              10,
            ],
          },
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  group('previewReferenceFile', () {
    late Directory tempDir;
    late Directory referenceDir;
    late String referenceFilePath;
    late BrickGenConfig config;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_preview_ref_');
      referenceDir = Directory(p.join(tempDir.path, 'reference'))
        ..createSync(recursive: true);
      config = BrickGenConfig(
        replacements: [
          Replacement(
            from: RegExp('Widget'),
            to: '{{#use_riverpod}}ConsumerWidget{{/use_riverpod}}'
                '{{^use_riverpod}}StatelessWidget{{/use_riverpod}}',
          ),
        ],
      );

      referenceFilePath = p.join(referenceDir.path, 'widget.dart');
      File(referenceFilePath).writeAsStringSync('''
class App extends Widget {
  /*remove-start*/
  // scaffold
  /*remove-end*/
}
''');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('renders transformed content with Mason variables', () async {
      final content = await previewReferenceFile(
        filePath: 'widget.dart',
        referencePath: referenceDir.path,
        config: config,
        templateOnly: false,
        vars: {'use_riverpod': true},
      );

      expect(content, contains('class App extends ConsumerWidget'));
      expect(content, isNot(contains('remove-start')));
      expect(content, isNot(contains('scaffold')));
    });

    test('keeps mustache tags when templateOnly is true', () async {
      final content = await previewReferenceFile(
        filePath: 'widget.dart',
        referencePath: referenceDir.path,
        config: config,
        templateOnly: true,
        vars: {'use_riverpod': true},
      );

      expect(
        content,
        contains('{{#use_riverpod}}ConsumerWidget{{/use_riverpod}}'),
      );
      expect(
        content,
        contains('{{^use_riverpod}}StatelessWidget{{/use_riverpod}}'),
      );
      expect(content, isNot(contains('class App extends ConsumerWidget')));
      expect(content, isNot(contains('remove-start')));
    });

    test('loads partial files created during transformation', () async {
      File(referenceFilePath).writeAsStringSync('''
class App extends Widget {
  /*partial v footer*/
  // footer line
  /*partial ^ footer*/
}
''');

      final content = await previewReferenceFile(
        filePath: 'widget.dart',
        referencePath: referenceDir.path,
        config: config,
        templateOnly: false,
        vars: {'use_riverpod': true},
      );

      expect(content, contains('footer line'));
    });

    test('throws when the reference directory is missing', () async {
      referenceDir.deleteSync(recursive: true);

      await expectLater(
        previewReferenceFile(
          filePath: referenceFilePath,
          referencePath: referenceDir.path,
          config: config,
          templateOnly: false,
        ),
        throwsA(
          isA<PreviewException>().having(
            (error) => error.message,
            'message',
            contains('Reference directory not found'),
          ),
        ),
      );
    });

    test('wraps path replacement failures as PreviewException', () async {
      final badConfig = BrickGenConfig(
        replacements: [
          Replacement(
            from: RegExp('widget.dart'),
            to: '/outside/widget.dart',
          ),
        ],
      );

      await expectLater(
        previewReferenceFile(
          filePath: 'widget.dart',
          referencePath: referenceDir.path,
          config: badConfig,
          templateOnly: false,
        ),
        throwsA(
          isA<PreviewException>().having(
            (error) => error.message,
            'message',
            contains('Path replacement produced an absolute path'),
          ),
        ),
      );
    });
  });
}
