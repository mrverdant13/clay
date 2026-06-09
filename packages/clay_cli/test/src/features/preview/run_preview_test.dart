import 'dart:io';

import 'package:clay_cli/src/features/preview/preview_exception.dart';
import 'package:clay_cli/src/features/preview/run_preview.dart';
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

  group('runPreview', () {
    late Directory tempDir;
    late Directory referenceDir;
    late String referenceFilePath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_preview_run_');
      referenceDir = Directory(p.join(tempDir.path, 'reference'))
        ..createSync(recursive: true);
      File(p.join(tempDir.path, 'brick-gen.json')).writeAsStringSync('''
{
  "reference": "reference",
  "target": "target",
  "replacements": [
    {
      "from": "Widget",
      "to": "{{#use_riverpod}}ConsumerWidget{{/use_riverpod}}{{^use_riverpod}}StatelessWidget{{/use_riverpod}}"
    }
  ]
}
''');

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
      final result = await runPreview(
        filePath: 'widget.dart',
        templateOnly: false,
        vars: {'use_riverpod': true},
        cwd: tempDir.path,
      );

      expect(result.content, contains('class App extends ConsumerWidget'));
      expect(result.content, isNot(contains('remove-start')));
      expect(result.content, isNot(contains('scaffold')));
    });

    test('keeps mustache tags when templateOnly is true', () async {
      final result = await runPreview(
        filePath: 'widget.dart',
        templateOnly: true,
        vars: {'use_riverpod': true},
        cwd: tempDir.path,
      );

      expect(
        result.content,
        contains('{{#use_riverpod}}ConsumerWidget{{/use_riverpod}}'),
      );
      expect(
        result.content,
        contains('{{^use_riverpod}}StatelessWidget{{/use_riverpod}}'),
      );
      expect(
        result.content,
        isNot(contains('class App extends ConsumerWidget')),
      );
      expect(result.content, isNot(contains('remove-start')));
    });

    test('selects the stateless branch when use_riverpod is false', () async {
      final result = await runPreview(
        filePath: 'widget.dart',
        templateOnly: false,
        vars: {'use_riverpod': false},
        cwd: tempDir.path,
      );

      expect(result.content, contains('class App extends StatelessWidget'));
    });

    test('loads partial files created during transformation', () async {
      File(referenceFilePath).writeAsStringSync('''
class App extends Widget {
  /*partial v footer*/
  // footer line
  /*partial ^ footer*/
}
''');

      final result = await runPreview(
        filePath: 'widget.dart',
        templateOnly: false,
        vars: {'use_riverpod': true},
        cwd: tempDir.path,
      );

      expect(result.content, contains('footer line'));
    });

    test('throws when the reference path is a directory', () async {
      Directory(p.join(referenceDir.path, 'nested')).createSync();

      await expectLater(
        runPreview(
          filePath: 'nested',
          templateOnly: false,
          cwd: tempDir.path,
        ),
        throwsA(
          isA<PreviewException>().having(
            (error) => error.message,
            'message',
            contains('Path is not a file'),
          ),
        ),
      );
    });

    test('throws when the reference path is a symlink', () async {
      Link(p.join(referenceDir.path, 'linked.dart'))
          .createSync(referenceFilePath);

      await expectLater(
        runPreview(
          filePath: 'linked.dart',
          templateOnly: false,
          cwd: tempDir.path,
        ),
        throwsA(
          isA<PreviewException>().having(
            (error) => error.message,
            'message',
            contains('Path is not a file'),
          ),
        ),
      );
    });

    test('throws when the reference path is a fifo', () async {
      Process.runSync('mkfifo', [p.join(referenceDir.path, 'preview.fifo')]);

      await expectLater(
        runPreview(
          filePath: 'preview.fifo',
          templateOnly: false,
          cwd: tempDir.path,
        ),
        throwsA(
          isA<PreviewException>().having(
            (error) => error.message,
            'message',
            contains('Path is not a file'),
          ),
        ),
      );
    });

    test('throws when the reference path is a unix domain socket', () async {
      final socketPath = p.join(referenceDir.path, 'preview.sock');
      final server = await ServerSocket.bind(
        InternetAddress(socketPath, type: InternetAddressType.unix),
        0,
      );
      addTearDown(server.close);

      await expectLater(
        runPreview(
          filePath: 'preview.sock',
          templateOnly: false,
          cwd: tempDir.path,
        ),
        throwsA(
          isA<PreviewException>().having(
            (error) => error.message,
            'message',
            contains('Path is not a file'),
          ),
        ),
      );
    });

    test('throws when the reference file does not exist', () async {
      await expectLater(
        runPreview(
          filePath: 'missing.dart',
          templateOnly: false,
          cwd: tempDir.path,
        ),
        throwsA(
          isA<PreviewException>().having(
            (error) => error.message,
            'message',
            contains('File not found'),
          ),
        ),
      );
    });

    test('throws when the reference directory is missing', () async {
      referenceDir.deleteSync(recursive: true);

      await expectLater(
        runPreview(
          filePath: referenceFilePath,
          templateOnly: false,
          cwd: tempDir.path,
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

    test('throws when the file is outside the reference directory', () async {
      final outsideFile = File(p.join(tempDir.path, 'outside.dart'))
        ..createSync()
        ..writeAsStringSync('class Outside {}');

      await expectLater(
        runPreview(
          filePath: outsideFile.path,
          templateOnly: false,
          cwd: tempDir.path,
        ),
        throwsA(isA<PreviewException>()),
      );
    });

    test('wraps path replacement failures as PreviewException', () async {
      File(p.join(tempDir.path, 'brick-gen.json')).writeAsStringSync('''
{
  "reference": "reference",
  "target": "target",
  "replacements": [
    {
      "from": "widget.dart",
      "to": "/outside/widget.dart"
    }
  ]
}
''');

      await expectLater(
        runPreview(
          filePath: 'widget.dart',
          templateOnly: false,
          cwd: tempDir.path,
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
