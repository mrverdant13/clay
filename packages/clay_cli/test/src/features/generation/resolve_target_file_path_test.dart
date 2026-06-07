import 'package:clay_cli/src/entities/replacement.dart';
import 'package:clay_cli/src/features/generation/resolve_target_file_path.dart';
import 'package:test/test.dart';

void main() {
  group('resolveTargetFilePath', () {
    const targetRoot = '/project/target';

    test('returns the original path when no replacements match', () {
      expect(
        resolveTargetFilePath(
          absolutePath: '$targetRoot/lib/main.dart',
          targetAbsolutePath: targetRoot,
          replacements: const [],
        ),
        '$targetRoot/lib/main.dart',
      );
    });

    test('applies replacements to the target-relative path', () {
      expect(
        resolveTargetFilePath(
          absolutePath: '$targetRoot/from/file.txt',
          targetAbsolutePath: targetRoot,
          replacements: [Replacement(from: RegExp('from'), to: 'to')],
        ),
        '$targetRoot/to/file.txt',
      );
    });
  });
}
