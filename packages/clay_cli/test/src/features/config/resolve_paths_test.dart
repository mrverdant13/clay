import 'package:clay_cli/src/entities/brick_gen_config.dart';
import 'package:clay_cli/src/features/config/resolve_paths.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  const projectRoot = '/project/root';

  group('resolvePathFromProjectRoot', () {
    test('joins relative paths to project root', () {
      expect(
        resolvePathFromProjectRoot(
          projectRoot: projectRoot,
          path: 'reference',
        ),
        p.join(projectRoot, 'reference'),
      );
    });

    test('returns absolute paths unchanged', () {
      const absolutePath = '/absolute/reference';

      expect(
        resolvePathFromProjectRoot(
          projectRoot: projectRoot,
          path: absolutePath,
        ),
        absolutePath,
      );
    });

    test('normalizes relative path segments', () {
      expect(
        resolvePathFromProjectRoot(
          projectRoot: projectRoot,
          path: 'brick/../target',
        ),
        p.join(projectRoot, 'target'),
      );
    });
  });

  group('resolveReferencePath', () {
    test('uses config reference when no CLI override is provided', () {
      const config = BrickGenConfig(reference: 'src/ref');

      expect(
        resolveReferencePath(projectRoot: projectRoot, config: config),
        p.join(projectRoot, 'src/ref'),
      );
    });

    test('uses CLI override over config reference', () {
      const config = BrickGenConfig(reference: 'src/ref');

      expect(
        resolveReferencePath(
          projectRoot: projectRoot,
          config: config,
          cliOverride: 'override/ref',
        ),
        p.join(projectRoot, 'override/ref'),
      );
    });

    test('falls back to built-in default when config uses default', () {
      const config = BrickGenConfig();

      expect(
        resolveReferencePath(projectRoot: projectRoot, config: config),
        p.join(projectRoot, defaultReferencePath),
      );
    });

    test('resolves absolute CLI override as-is', () {
      const config = BrickGenConfig();
      const absoluteOverride = '/custom/reference';

      expect(
        resolveReferencePath(
          projectRoot: projectRoot,
          config: config,
          cliOverride: absoluteOverride,
        ),
        absoluteOverride,
      );
    });
  });

  group('resolveTargetPath', () {
    test('uses config target when no CLI override is provided', () {
      const config = BrickGenConfig(target: 'out/template');

      expect(
        resolveTargetPath(projectRoot: projectRoot, config: config),
        p.join(projectRoot, 'out/template'),
      );
    });

    test('uses CLI override over config target', () {
      const config = BrickGenConfig(target: 'out/template');

      expect(
        resolveTargetPath(
          projectRoot: projectRoot,
          config: config,
          cliOverride: 'override/template',
        ),
        p.join(projectRoot, 'override/template'),
      );
    });

    test('falls back to built-in default when config uses default', () {
      const config = BrickGenConfig();

      expect(
        resolveTargetPath(projectRoot: projectRoot, config: config),
        p.join(projectRoot, defaultTargetPath),
      );
    });
  });
}
