import 'dart:io';

import 'package:clay_cli/src/entities/brick_gen_config.dart';
import 'package:clay_cli/src/entities/replacement.dart';
import 'package:clay_cli/src/features/generation/generate_template.dart';
import 'package:clay_cli/src/features/generation/generation_exception.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('generateTemplate', () {
    late Directory tempDir;
    late Directory referenceDir;
    late Directory targetDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_generate_template_');
      referenceDir = Directory(p.join(tempDir.path, 'reference'))
        ..createSync(recursive: true);
      targetDir = Directory(p.join(tempDir.path, 'target'));
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('copies reference files into the target directory', () async {
      File(p.join(referenceDir.path, 'hello.txt')).writeAsStringSync('hello\n');

      await generateTemplate(
        config: BrickGenConfig(),
        referencePath: referenceDir.path,
        targetPath: targetDir.path,
      );

      expect(
        File(p.join(targetDir.path, 'hello.txt')).readAsStringSync(),
        'hello\n',
      );
    });

    test('copies binary assets without attempting text transforms', () async {
      final bytes = [0xFF, 0xD8, 0xFF, 0x00, 0x01];
      File(p.join(referenceDir.path, 'assets', 'logo.jpg'))
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);

      await generateTemplate(
        config: BrickGenConfig(),
        referencePath: referenceDir.path,
        targetPath: targetDir.path,
      );

      expect(
        File(p.join(targetDir.path, 'assets', 'logo.jpg')).readAsBytesSync(),
        bytes,
      );
    });

    test('excludes ignored files and prunes empty directories', () async {
      File(p.join(referenceDir.path, 'lib', 'main.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync('main\n');
      File(p.join(referenceDir.path, 'build', 'output.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync('ignored\n');

      await generateTemplate(
        config: BrickGenConfig(ignore: const ['build/']),
        referencePath: referenceDir.path,
        targetPath: targetDir.path,
      );

      expect(
        File(p.join(targetDir.path, 'lib', 'main.dart')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(targetDir.path, 'build', 'output.txt')).existsSync(),
        isFalse,
      );
      expect(Directory(p.join(targetDir.path, 'build')).existsSync(), isFalse);
    });

    test('applies transforms when paths are relative to the working directory',
        () async {
      final previousWorkingDirectory = Directory.current.path;
      Directory.current = tempDir.path;
      try {
        File(p.join('reference', 'from_widget.dart'))
            .writeAsStringSync('class Widget {}\n/*drop*/\n');

        await generateTemplate(
          config: BrickGenConfig(
            replacements: [Replacement(from: RegExp('from'), to: 'to')],
          ),
          referencePath: 'reference',
          targetPath: 'target',
        );

        final outputFile = File(p.join('target', 'to_widget.dart'));
        expect(outputFile.existsSync(), isTrue);
        expect(outputFile.readAsStringSync(), 'class Widget {}\n');
      } finally {
        Directory.current = previousWorkingDirectory;
      }
    });

    test('applies path renames and content transforms', () async {
      File(p.join(referenceDir.path, 'from_widget.dart'))
          .writeAsStringSync('class Widget {}\n/*drop*/\n');

      await generateTemplate(
        config: BrickGenConfig(
          replacements: [Replacement(from: RegExp('from'), to: 'to')],
        ),
        referencePath: referenceDir.path,
        targetPath: targetDir.path,
      );

      final outputFile = File(p.join(targetDir.path, 'to_widget.dart'));
      expect(outputFile.existsSync(), isTrue);
      expect(outputFile.readAsStringSync(), 'class Widget {}\n');
    });

    test('excludes ignored symlinks and prunes empty directories', () async {
      final linkedFile = File(p.join(referenceDir.path, 'build', 'output.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync('ignored');
      Link(p.join(referenceDir.path, 'build', 'link.txt'))
          .createSync(linkedFile.path);

      await generateTemplate(
        config: BrickGenConfig(ignore: const ['build/']),
        referencePath: referenceDir.path,
        targetPath: targetDir.path,
      );

      expect(
        Link(p.join(targetDir.path, 'build', 'link.txt')).existsSync(),
        isFalse,
      );
      expect(Directory(p.join(targetDir.path, 'build')).existsSync(), isFalse);
    });

    test('renames symlinks using replacements', () async {
      final externalFile = File(p.join(tempDir.path, 'external.txt'))
        ..writeAsStringSync('external');
      Link(p.join(referenceDir.path, 'from_link.txt'))
          .createSync(externalFile.path);

      await generateTemplate(
        config: BrickGenConfig(
          replacements: [Replacement(from: RegExp('from'), to: 'to')],
        ),
        referencePath: referenceDir.path,
        targetPath: targetDir.path,
      );

      expect(
        Link(p.join(targetDir.path, 'from_link.txt')).existsSync(),
        isFalse,
      );
      final renamedLink = Link(p.join(targetDir.path, 'to_link.txt'));
      expect(renamedLink.existsSync(), isTrue);
      expect(renamedLink.targetSync(), externalFile.path);
    });

    test('throws when path replacements collide', () async {
      File(p.join(referenceDir.path, 'a_widget.dart')).writeAsStringSync('a');
      File(p.join(referenceDir.path, 'b_widget.dart')).writeAsStringSync('b');

      expect(
        () => generateTemplate(
          config: BrickGenConfig(
            replacements: [
              Replacement(
                from: RegExp(r'^.+_widget\.dart$'),
                to: 'widget.dart',
              ),
            ],
          ),
          referencePath: referenceDir.path,
          targetPath: targetDir.path,
        ),
        throwsA(
          isA<GenerationException>().having(
            (error) => error.message,
            'message',
            contains('Path replacement collision'),
          ),
        ),
      );
    });

    test('replaces an existing target directory', () async {
      targetDir.createSync(recursive: true);
      File(p.join(targetDir.path, 'stale.txt')).writeAsStringSync('stale\n');
      File(p.join(referenceDir.path, 'fresh.txt')).writeAsStringSync('fresh\n');

      await generateTemplate(
        config: BrickGenConfig(),
        referencePath: referenceDir.path,
        targetPath: targetDir.path,
      );

      expect(File(p.join(targetDir.path, 'stale.txt')).existsSync(), isFalse);
      expect(
        File(p.join(targetDir.path, 'fresh.txt')).readAsStringSync(),
        'fresh\n',
      );
    });

    test('throws when reference and target paths are equal', () async {
      expect(
        () => generateTemplate(
          config: BrickGenConfig(),
          referencePath: referenceDir.path,
          targetPath: referenceDir.path,
        ),
        throwsA(
          isA<GenerationException>().having(
            (error) => error.message,
            'message',
            contains('must differ'),
          ),
        ),
      );
    });

    test('throws when the target is inside the reference', () async {
      final nestedTarget = Directory(p.join(referenceDir.path, 'output'))
        ..createSync(recursive: true);

      expect(
        () => generateTemplate(
          config: BrickGenConfig(),
          referencePath: referenceDir.path,
          targetPath: nestedTarget.path,
        ),
        throwsA(
          isA<GenerationException>().having(
            (error) => error.message,
            'message',
            contains('inside the reference directory'),
          ),
        ),
      );
    });

    test('throws when the reference is inside the target', () async {
      targetDir.createSync(recursive: true);
      final nestedReference = Directory(p.join(targetDir.path, 'reference'))
        ..createSync(recursive: true);
      File(p.join(nestedReference.path, 'hello.txt'))
          .writeAsStringSync('hello\n');

      expect(
        () => generateTemplate(
          config: BrickGenConfig(),
          referencePath: nestedReference.path,
          targetPath: targetDir.path,
        ),
        throwsA(
          isA<GenerationException>().having(
            (error) => error.message,
            'message',
            contains('inside the target directory'),
          ),
        ),
      );

      expect(nestedReference.existsSync(), isTrue);
    });

    test('throws when the target is the filesystem root', () async {
      final rootPath = Platform.isWindows
          ? '${Directory.current.path.split(':').first}:\\'
          : '/';

      expect(
        () => generateTemplate(
          config: BrickGenConfig(),
          referencePath: referenceDir.path,
          targetPath: rootPath,
        ),
        throwsA(
          isA<GenerationException>().having(
            (error) => error.message,
            'message',
            contains('filesystem root'),
          ),
        ),
      );
    });

    test('throws when the reference directory is missing', () async {
      referenceDir.deleteSync(recursive: true);

      expect(
        () => generateTemplate(
          config: BrickGenConfig(),
          referencePath: referenceDir.path,
          targetPath: targetDir.path,
        ),
        throwsA(isA<GenerationException>()),
      );
    });
  });
}
