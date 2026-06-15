import 'package:clay_core/src/features/generation/assert_safe_target_path.dart';
import 'package:clay_core/src/features/generation/generation_exception.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('isFilesystemRoot', () {
    test('returns true for POSIX root paths', () {
      expect(isFilesystemRoot('/', isWindows: false), isTrue);
    });

    test('returns false for non-root POSIX paths', () {
      expect(isFilesystemRoot('/tmp/output', isWindows: false), isFalse);
    });

    test('returns true for Windows drive roots', () {
      expect(isFilesystemRoot(r'C:\', isWindows: true), isTrue);
      expect(isFilesystemRoot('D:', isWindows: true), isTrue);
    });

    test('returns false for non-root Windows paths', () {
      expect(isFilesystemRoot(r'C:\Users\app', isWindows: true), isFalse);
    });
  });

  group('assertSafeTargetPath', () {
    test('throws when the target resolves to the POSIX root', () {
      expect(
        () => assertSafeTargetPath(targetPath: '/'),
        throwsA(
          isA<GenerationException>().having(
            (error) => error.message,
            'message',
            contains('filesystem root'),
          ),
        ),
      );
    });

    test('allows normal target directories', () {
      expect(
        () => assertSafeTargetPath(
          targetPath: p.join(p.current, 'target'),
        ),
        returnsNormally,
      );
    });
  });
}
