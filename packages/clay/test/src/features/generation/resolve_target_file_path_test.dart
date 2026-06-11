import 'package:clay/clay.dart';
import 'package:clay/src/features/config/matches_ignore_pattern.dart';
import 'package:clay/src/features/generation/resolve_target_file_path.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('resolveTargetFilePath', () {
    final targetRoot = p.absolute(p.join('project', 'target'));

    test('returns the original path when no replacements match', () {
      expect(
        resolveTargetFilePath(
          absolutePath: p.join(targetRoot, 'lib', 'main.dart'),
          targetAbsolutePath: targetRoot,
          replacements: const [],
        ),
        p.join(targetRoot, 'lib', 'main.dart'),
      );
    });

    test('applies POSIX-style replacements to backslash relative paths', () {
      expect(
        resolveTargetFilePath(
          absolutePath: p.join(targetRoot, r'from\file.txt'),
          targetAbsolutePath: targetRoot,
          replacements: [Replacement(from: RegExp('from'), to: 'to')],
        ),
        p.join(targetRoot, 'to', 'file.txt'),
      );
    });

    test('applies replacements to the target-relative path', () {
      expect(
        resolveTargetFilePath(
          absolutePath: p.join(targetRoot, 'from', 'file.txt'),
          targetAbsolutePath: targetRoot,
          replacements: [Replacement(from: RegExp('from'), to: 'to')],
        ),
        p.join(targetRoot, 'to', 'file.txt'),
      );
    });

    test('normalizes a relative absolutePath before applying replacements', () {
      final relativeTargetRoot = p.join('project', 'target');
      final relativeFilePath = p.join(relativeTargetRoot, 'from', 'file.txt');

      expect(
        resolveTargetFilePath(
          absolutePath: relativeFilePath,
          targetAbsolutePath: relativeTargetRoot,
          replacements: [Replacement(from: RegExp('from'), to: 'to')],
        ),
        p.join(p.absolute(relativeTargetRoot), 'to', 'file.txt'),
      );
    });

    test('throws when a replacement produces an absolute path', () {
      expect(
        () => resolveTargetFilePath(
          absolutePath: p.join(targetRoot, 'file.txt'),
          targetAbsolutePath: targetRoot,
          replacements: [
            Replacement(
              from: RegExp(r'file\.txt'),
              to: p.absolute('outside.txt'),
            ),
          ],
        ),
        throwsA(isA<GenerationException>()),
      );
    });

    test('applies replacements sequentially to the target-relative path', () {
      expect(
        resolveTargetFilePath(
          absolutePath: p.join(targetRoot, 'alpha.txt'),
          targetAbsolutePath: targetRoot,
          replacements: [
            Replacement(from: RegExp(r'^alpha\.txt$'), to: 'beta.txt'),
            Replacement(from: RegExp(r'^beta\.txt$'), to: 'gamma.txt'),
          ],
        ),
        p.join(targetRoot, 'gamma.txt'),
      );
    });

    test('applies multiple replacements across directory and file segments',
        () {
      expect(
        resolveTargetFilePath(
          absolutePath: p.join(targetRoot, 'reference', 'lib', 'main.dart'),
          targetAbsolutePath: targetRoot,
          replacements: [
            Replacement(from: RegExp('reference/'), to: 'template/'),
            Replacement(from: RegExp(r'\.dart$'), to: '.mustache'),
          ],
        ),
        p.join(targetRoot, 'template', 'lib', 'main.mustache'),
      );
    });

    test('throws when a replacement escapes the target root', () {
      final nestedFile = normalizeIgnoreRelativePath(
        p.join('nested', 'file.txt'),
      );
      expect(
        () => resolveTargetFilePath(
          absolutePath: p.join(targetRoot, nestedFile),
          targetAbsolutePath: targetRoot,
          replacements: [
            Replacement(
              from: RegExp('^${RegExp.escape(nestedFile)}\$'),
              to: '../outside.txt',
            ),
          ],
        ),
        throwsA(
          isA<GenerationException>().having(
            (error) => error.message,
            'message',
            contains('outside the target directory'),
          ),
        ),
      );
    });
  });
}
