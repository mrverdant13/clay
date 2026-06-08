import 'package:clay_cli/src/entities/brick_gen_config.dart';
import 'package:clay_cli/src/entities/replacement.dart';
import 'package:clay_cli/src/features/generation/assert_unique_resolved_paths.dart';
import 'package:clay_cli/src/features/generation/generation_exception.dart';
import 'package:test/test.dart';

void main() {
  group('assertUniqueResolvedPaths', () {
    test('allows distinct resolved paths', () {
      expect(
        () => assertUniqueResolvedPaths(
          entityPaths: const [
            '/target/a.txt',
            '/target/b.txt',
          ],
          targetAbsolutePath: '/target',
          config: BrickGenConfig(),
        ),
        returnsNormally,
      );
    });

    test('throws when two entries map to the same path', () {
      expect(
        () => assertUniqueResolvedPaths(
          entityPaths: const [
            '/target/a_widget.dart',
            '/target/b_widget.dart',
          ],
          targetAbsolutePath: '/target',
          config: BrickGenConfig(
            replacements: [
              Replacement(
                from: RegExp(r'^.+_widget\.dart$'),
                to: 'widget.dart',
              ),
            ],
          ),
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

    test('ignores entries matched by ignore patterns', () {
      expect(
        () => assertUniqueResolvedPaths(
          entityPaths: const [
            '/target/build/a.txt',
            '/target/build/b.txt',
          ],
          targetAbsolutePath: '/target',
          config: BrickGenConfig(ignore: const ['build/']),
        ),
        returnsNormally,
      );
    });
  });
}
