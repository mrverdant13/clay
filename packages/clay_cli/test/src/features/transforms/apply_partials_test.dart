import 'dart:io';

import 'package:clay_cli/src/features/transforms/apply_partials.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('applyPartials', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_apply_partials_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('extracts and creates partials in all comment flavors', () {
      const input = '''
text
/*partial v partialA*/this is
the partial
A
/*partial ^ partialA*/
more text
#partial v partialB#this is
the partial
B
#partial ^ partialB#
yet more text
<!--partial v partialC-->this is
the partial
C
<!--partial ^ partialC-->
and even more text
''';
      const expected = '''
text
{{> partialA.partial }}
more text
{{> partialB.partial }}
yet more text
{{> partialC.partial }}
and even more text
''';

      final result = applyPartials(
        content: input,
        targetAbsolutePath: tempDir.path,
      );

      expect(result, expected);

      for (final partialName in ['A', 'B', 'C']) {
        final partialFile = File(
          p.join(tempDir.path, '{{~ partial$partialName.partial }}'),
        );
        expect(
          partialFile.existsSync(),
          isTrue,
          reason: 'partial$partialName file should exist',
        );
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

    test('extracts C-style partial blocks', () {
      const input = '''
before
/*partial v header*/line one
line two
/*partial ^ header*/
after
''';

      final result = applyPartials(
        content: input,
        targetAbsolutePath: tempDir.path,
      );

      expect(result, '''
before
{{> header.partial }}
after
''');

      final partialFile = File(
        p.join(tempDir.path, '{{~ header.partial }}'),
      );
      expect(partialFile.readAsStringSync(), '''
line one
line two
''');
    });

    test('extracts hash partial blocks', () {
      const input = '#partial v footer#footer content\n#partial ^ footer#';

      final result = applyPartials(
        content: input,
        targetAbsolutePath: tempDir.path,
      );

      expect(result, '{{> footer.partial }}');

      final partialFile = File(
        p.join(tempDir.path, '{{~ footer.partial }}'),
      );
      expect(partialFile.readAsStringSync(), 'footer content\n');
    });

    test('extracts HTML partial blocks', () {
      const input =
          '<!--partial v sidebar--><nav>links</nav>\n<!--partial ^ sidebar-->';

      final result = applyPartials(
        content: input,
        targetAbsolutePath: tempDir.path,
      );

      expect(result, '{{> sidebar.partial }}');

      final partialFile = File(
        p.join(tempDir.path, '{{~ sidebar.partial }}'),
      );
      expect(partialFile.readAsStringSync(), '<nav>links</nav>\n');
    });

    test('leaves content without partial blocks unchanged', () {
      const input = '''
plain text
/*not a partial block*/
#partial v missing closing marker
<!--partial ^ unmatched-->
''';

      final result = applyPartials(
        content: input,
        targetAbsolutePath: tempDir.path,
      );

      expect(result, input);
      expect(tempDir.listSync(), isEmpty);
    });

    test('overwrites an existing partial file with the same name', () {
      const input = '''
/*partial v shared*/new content
/*partial ^ shared*/
''';
      final partialPath = p.join(tempDir.path, '{{~ shared.partial }}');
      File(partialPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('old content');

      applyPartials(
        content: input,
        targetAbsolutePath: tempDir.path,
      );

      expect(File(partialPath).readAsStringSync(), 'new content\n');
    });
  });
}
