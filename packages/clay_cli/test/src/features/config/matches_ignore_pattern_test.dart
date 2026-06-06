import 'package:clay_cli/src/features/config/matches_ignore_pattern.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeIgnoreRelativePath', () {
    test('uses forward slashes', () {
      expect(
        normalizeIgnoreRelativePath(r'lib\src\main.dart'),
        'lib/src/main.dart',
      );
    });

    test('removes leading ./ segments', () {
      expect(
        normalizeIgnoreRelativePath('./lib/main.dart'),
        'lib/main.dart',
      );
    });

    test('collapses redundant segments', () {
      expect(
        normalizeIgnoreRelativePath('lib/./src/main.dart'),
        'lib/src/main.dart',
      );
    });
  });

  group('expandIgnorePattern', () {
    test('expands directory patterns without slash to any depth', () {
      expect(
        expandIgnorePattern('build/'),
        ['build', 'build/**', '**/build', '**/build/**'],
      );
    });

    test('expands root-anchored directory patterns', () {
      expect(
        expandIgnorePattern('/build/'),
        ['build', 'build/**'],
      );
    });

    test('expands path-specific directory patterns', () {
      expect(
        expandIgnorePattern('src/cache/'),
        ['src/cache', 'src/cache/**'],
      );
    });

    test('expands filename patterns to root and nested paths', () {
      expect(
        expandIgnorePattern('.DS_Store'),
        ['.DS_Store', '**/.DS_Store'],
      );
    });

    test('expands **-prefixed patterns with a root alternate', () {
      expect(
        expandIgnorePattern('**/*.iml'),
        ['**/*.iml', '*.iml'],
      );
    });
  });

  group('matchesIgnorePattern', () {
    test('matches directory patterns at any depth', () {
      expect(
        matchesIgnorePattern(
          relativePath: 'build/output.txt',
          pattern: 'build/',
        ),
        isTrue,
      );
      expect(
        matchesIgnorePattern(
          relativePath: 'packages/app/build/output.txt',
          pattern: 'build/',
        ),
        isTrue,
      );
    });

    test('matches root-anchored directory patterns only at root', () {
      expect(
        matchesIgnorePattern(
          relativePath: 'build/output.txt',
          pattern: '/build/',
        ),
        isTrue,
      );
      expect(
        matchesIgnorePattern(
          relativePath: 'packages/app/build/output.txt',
          pattern: '/build/',
        ),
        isFalse,
      );
    });

    test('matches common config ignore patterns', () {
      for (final path in [
        '.dart_tool/package_config.json',
        'packages/app/.dart_tool/package_config.json',
      ]) {
        expect(
          matchesIgnorePattern(relativePath: path, pattern: '.dart_tool/'),
          isTrue,
          reason: path,
        );
      }

      expect(
        matchesIgnorePattern(relativePath: 'src/foo.iml', pattern: '**/*.iml'),
        isTrue,
      );
      expect(
        matchesIgnorePattern(relativePath: 'foo.iml', pattern: '**/*.iml'),
        isTrue,
      );
      expect(
        matchesIgnorePattern(
          relativePath: 'src/.DS_Store',
          pattern: '.DS_Store',
        ),
        isTrue,
      );
    });

    test('does not match unrelated paths', () {
      expect(
        matchesIgnorePattern(
          relativePath: 'lib/main.dart',
          pattern: 'build/',
        ),
        isFalse,
      );
      expect(
        matchesIgnorePattern(
          relativePath: 'lib/main.dart',
          pattern: '**/*.iml',
        ),
        isFalse,
      );
    });
  });

  group('matchesIgnorePatterns', () {
    test('returns false when patterns are empty', () {
      expect(
        matchesIgnorePatterns(
          relativePath: 'build/output.txt',
          patterns: const [],
        ),
        isFalse,
      );
    });

    test('matches when any non-negated pattern matches', () {
      expect(
        matchesIgnorePatterns(
          relativePath: 'build/output.txt',
          patterns: const ['coverage/', 'build/'],
        ),
        isTrue,
      );
    });

    test('returns false when no patterns match', () {
      expect(
        matchesIgnorePatterns(
          relativePath: 'lib/main.dart',
          patterns: const ['build/', 'coverage/', '.dart_tool/'],
        ),
        isFalse,
      );
    });

    test('applies negation after a matching ignore pattern', () {
      expect(
        matchesIgnorePatterns(
          relativePath: 'build/keep.dart',
          patterns: const ['build/', '!build/keep.dart'],
        ),
        isFalse,
      );
      expect(
        matchesIgnorePatterns(
          relativePath: 'build/remove.dart',
          patterns: const ['build/', '!build/keep.dart'],
        ),
        isTrue,
      );
    });

    test('applies later negated patterns in order', () {
      expect(
        matchesIgnorePatterns(
          relativePath: 'coverage/lcov.info',
          patterns: const ['coverage/', '!coverage/lcov.info', 'coverage/'],
        ),
        isTrue,
      );
    });

    test('matches documented default ignore set', () {
      const patterns = [
        '.dart_tool/',
        'build/',
        'coverage/',
        '**/*.iml',
        '.DS_Store',
      ];

      expect(
        matchesIgnorePatterns(
          relativePath: '.dart_tool/package_config.json',
          patterns: patterns,
        ),
        isTrue,
      );
      expect(
        matchesIgnorePatterns(
          relativePath: 'packages/app/build/app.dill',
          patterns: patterns,
        ),
        isTrue,
      );
      expect(
        matchesIgnorePatterns(
          relativePath: 'coverage/lcov.info',
          patterns: patterns,
        ),
        isTrue,
      );
      expect(
        matchesIgnorePatterns(
          relativePath: 'android/.idea/modules.iml',
          patterns: patterns,
        ),
        isTrue,
      );
      expect(
        matchesIgnorePatterns(
          relativePath: 'lib/main.dart',
          patterns: patterns,
        ),
        isFalse,
      );
    });
  });
}
