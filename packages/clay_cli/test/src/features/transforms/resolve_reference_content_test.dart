import 'dart:io';

import 'package:clay/clay.dart';
import 'package:clay_cli/src/features/transforms/resolve_reference_content.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('resolveReferenceContent', () {
    late Directory tempDir;
    late String targetAbsolutePath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_resolve_content_');
      targetAbsolutePath = tempDir.path;
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('removes a remove-start/end block', () {
      const input = '''
line0
/*remove-start*/
scaffold
/*remove-end*/
line1
''';
      const expected = '''
line0

line1
''';
      final result = resolveReferenceContent(
        content: input,
        targetRelativePath: 'file.txt',
        targetAbsolutePath: targetAbsolutePath,
        config: BrickGenConfig(),
      );
      expect(result, expected);
    });

    test('unwraps a commented mustache tag', () {
      const input = '/*x{{flag}}*/tail';
      const expected = '{{flag}}tail';
      final result = resolveReferenceContent(
        content: input,
        targetRelativePath: 'file.txt',
        targetAbsolutePath: targetAbsolutePath,
        config: BrickGenConfig(),
      );
      expect(result, expected);
    });

    test('returns binary extensions unchanged', () {
      const input = '''
/*remove-start*/
drop me
/*remove-end*/
''';
      final result = resolveReferenceContent(
        content: input,
        targetRelativePath: 'assets/icon.png',
        targetAbsolutePath: targetAbsolutePath,
        config: BrickGenConfig(),
      );
      expect(result, input);
    });

    test('applies replacements before remotions', () {
      const input = '/*remove-start*/content/*remove-end*/';
      const expected = '/*remove-start-disabled*/content/*remove-end*/';
      final result = resolveReferenceContent(
        content: input,
        targetRelativePath: 'file.txt',
        targetAbsolutePath: targetAbsolutePath,
        config: BrickGenConfig(
          replacements: [
            Replacement(
              from: RegExp('remove-start'),
              to: 'remove-start-disabled',
            ),
          ],
        ),
      );
      expect(result, expected);
    });

    test('applies configured line deletions and replacements', () {
      const input = '''
remove
keep
''';
      const expected = 'removed\n';
      final result = resolveReferenceContent(
        content: input,
        targetRelativePath: 'file.txt',
        targetAbsolutePath: targetAbsolutePath,
        config: BrickGenConfig(
          replacements: [
            Replacement(from: RegExp('keep'), to: 'removed'),
          ],
          lineDeletions: const [
            LineDeletion(
              filePath: 'file.txt',
              ranges: [LineRange(start: 0, end: 0)],
            ),
          ],
        ),
      );
      expect(result, expected);
    });

    test('runs partial extraction as the final transform', () {
      const input = '''
before
/*partial v header*/
header body
/*partial ^ header*/
after
''';
      const expected = '''
before
{{> header.partial }}
after
''';
      final result = resolveReferenceContent(
        content: input,
        targetRelativePath: 'file.txt',
        targetAbsolutePath: targetAbsolutePath,
        config: BrickGenConfig(),
      );
      expect(result, expected);
      final partialFile = File(
        p.join(targetAbsolutePath, '{{~ header.partial }}'),
      );
      expect(partialFile.readAsStringSync(), '\nheader body\n');
    });
  });
}
