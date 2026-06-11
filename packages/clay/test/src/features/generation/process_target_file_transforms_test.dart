import 'dart:io';

import 'package:clay/clay.dart';
import 'package:clay/src/features/generation/process_target_file.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('processTargetFile content transforms', () {
    late Directory tempDir;
    late Directory targetDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'clay_process_file_transforms_',
      );
      targetDir = Directory(p.join(tempDir.path, 'target'))
        ..createSync(recursive: true);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Future<File> processFile({
      required String relativePath,
      required String content,
      ClayConfig? config,
    }) async {
      final file = File(p.join(targetDir.path, relativePath))
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
      await processTargetFile(
        file: file,
        targetAbsolutePath: targetDir.path,
        config: config ?? ClayConfig(),
      );
      return file;
    }

    test('applies configured line deletions', () async {
      const originalContent = '''
line 0
line 1
line 2
line 3
line 4
line 5
line 6
line 7
line 8
line 9
''';
      const resultingContent = '''
line 0
line 1
line 2
line 8
line 9
''';

      final file = await processFile(
        relativePath: 'file.txt',
        content: originalContent,
        config: ClayConfig(
          lineDeletions: const [
            LineDeletion(
              filePath: 'file.txt',
              ranges: [LineRange(start: 3, end: 7)],
            ),
          ],
        ),
      );

      expect(file.readAsStringSync(), resultingContent);
    });

    test('applies configured content replacements', () async {
      const originalContent = '''
line 0
line 1 to be replaced
line 2
line 3
line 4 to be replaced
line 5
line 6
line 7
line 8 to be replaced
line 9
''';
      const resultingContent = '''
line 0
replaced line
line 2
line 3
replaced line
line 5
line 6
line 7
replaced line
line 9
''';

      final file = await processFile(
        relativePath: 'file.txt',
        content: originalContent,
        config: ClayConfig(
          replacements: [
            Replacement(
              from: RegExp(r'line (\d+) to be replaced'),
              to: 'replaced line',
            ),
          ],
        ),
      );

      expect(file.readAsStringSync(), resultingContent);
    });

    test('deletes remotion blocks', () async {
      const originalContent = '''
line   <!--x-remove-start--> asdf
asdf asdf
asdf <!--remove-end-x-->    0
line 1
line  /*x-remove-start*/ asdf
asdf asdf
asdf /*remove-end*/  2
line   #remove-start# asdf
asdf asdf
asdf #remove-end-x#       3
line  <!--remove-start--> asdf
asdf asdf
asdf <!--remove-end-->  4
line 5
''';
      const resultingContent = '''
line0
line 1
line  2
line   3
line    4
line 5
''';

      final file = await processFile(
        relativePath: 'file.txt',
        content: originalContent,
      );

      expect(file.readAsStringSync(), resultingContent);
    });

    test('deletes droppable blocks in all comment flavors', () async {
      const dropCases = ['/*drop*/', '#drop#', '<!--drop-->'];
      for (final (index, dropCase) in dropCases.indexed) {
        const resultingContent = '''
line 0
line 1
line 2
''';
        final originalContent = '''
line 0
line 1
line 2
$dropCase
line 3
line 4
line 5
''';

        final file = await processFile(
          relativePath: 'file$index.txt',
          content: originalContent,
        );

        expect(file.readAsStringSync(), resultingContent);
      }
    });

    test('replaces replaceable blocks', () async {
      const originalContent = '''
line0
line/*replace-start*/
asdf
asdf asdf
/*with i0*/
// 1
// line2
/*replace-end*/
line3
#replace-start#
asdf
asdf asdf
#with i1#
# line4
# line5
#replace-end#
line6
''';
      const resultingContent = '''
line0
line1
line2
line3
 line4
 line5
line6
''';

      final file = await processFile(
        relativePath: 'file.txt',
        content: originalContent,
      );

      expect(file.readAsStringSync(), resultingContent);
    });

    test('applies insertion blocks', () async {
      const originalContent = '''
line0
line/*insert-start*/
// 1
// line2
/*insert-end*/
line3
#insert-start#
# line4
# line5
#insert-end#
line6
''';
      const resultingContent = '''
line0
line1
line2
line3
line4
line5
line6
''';

      final file = await processFile(
        relativePath: 'file.txt',
        content: originalContent,
      );

      expect(file.readAsStringSync(), resultingContent);
    });

    test('resolves mustache tags in comments', () async {
      const originalContent = '''
text
/*x{{some-key}}*/
more text
#{{other-key}}x#
yet more text
and even
<!--x{{yet-another-key}}x-->
more text
''';
      const resultingContent = '''
text{{some-key}}
more text
{{other-key}}yet more text
and even{{yet-another-key}}more text
''';

      final file = await processFile(
        relativePath: 'file.txt',
        content: originalContent,
      );

      expect(file.readAsStringSync(), resultingContent);
    });

    test('resolves spacing groups', () async {
      const originalContent = '''
text
/*w 2v 4> w*/
more te#ww#xt
#w 4v 2> w#
yet more <!--w 5> w--> text
''';
      const resultingContent = '''
text

    more text



  yet more     text
''';

      final file = await processFile(
        relativePath: 'file.txt',
        content: originalContent,
      );

      expect(file.readAsStringSync(), resultingContent);
    });

    test('extracts partials and writes partial files', () async {
      const originalContent = '''
text
/*partial v partialA*/
/*w w*/
this is
the partial
A
/*partial ^ partialA*/
more text
#partial v partialB#
#w w#
this is
the partial
B
#partial ^ partialB#
yet more text
<!--partial v partialC-->
<!--w w-->
this is
the partial
C
<!--partial ^ partialC-->
and even more text
''';
      const resultingContent = '''
text
{{> partialA.partial }}
more text
{{> partialB.partial }}
yet more text
{{> partialC.partial }}
and even more text
''';

      final file = await processFile(
        relativePath: 'file.txt',
        content: originalContent,
      );

      expect(file.readAsStringSync(), resultingContent);

      for (final partialName in ['A', 'B', 'C']) {
        final partialFile = File(
          p.join(targetDir.path, '{{~ partial$partialName.partial }}'),
        );
        expect(partialFile.existsSync(), isTrue);
        expect(
          partialFile.readAsStringSync(),
          '''
this is
the partial
$partialName
''',
        );
      }
    });
  });
}
