import 'package:clay/clay.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final projectRoot = p.join('project', 'root');

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
      final absolutePath = p.absolute(p.join('absolute', 'reference'));

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
          path: p.join('brick', '..', 'target'),
        ),
        p.join(projectRoot, 'target'),
      );
    });
  });

  group('resolveReferencePath', () {
    test('uses config reference when no CLI override is provided', () {
      final config = ClayConfig(reference: p.join('src', 'ref'));

      expect(
        resolveReferencePath(projectRoot: projectRoot, config: config),
        p.join(projectRoot, 'src', 'ref'),
      );
    });

    test('uses CLI override over config reference', () {
      final config = ClayConfig(reference: p.join('src', 'ref'));

      expect(
        resolveReferencePath(
          projectRoot: projectRoot,
          config: config,
          cliOverride: p.join('override', 'ref'),
        ),
        p.join(projectRoot, 'override', 'ref'),
      );
    });

    test('falls back to built-in default when config uses default', () {
      final config = ClayConfig();

      expect(
        resolveReferencePath(projectRoot: projectRoot, config: config),
        p.join(projectRoot, ClayConfig.defaultReferencePath),
      );
    });

    test('resolves absolute CLI override as-is', () {
      final config = ClayConfig();
      final absoluteOverride = p.absolute(p.join('custom', 'reference'));

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
      final config = ClayConfig(target: p.join('out', 'template'));

      expect(
        resolveTargetPath(projectRoot: projectRoot, config: config),
        p.join(projectRoot, 'out', 'template'),
      );
    });

    test('uses CLI override over config target', () {
      final config = ClayConfig(target: p.join('out', 'template'));

      expect(
        resolveTargetPath(
          projectRoot: projectRoot,
          config: config,
          cliOverride: p.join('override', 'template'),
        ),
        p.join(projectRoot, 'override', 'template'),
      );
    });

    test('falls back to built-in default when config uses default', () {
      final config = ClayConfig();

      expect(
        resolveTargetPath(projectRoot: projectRoot, config: config),
        p.join(projectRoot, ClayConfig.defaultTargetPath),
      );
    });
  });
}
