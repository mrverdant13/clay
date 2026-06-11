import 'dart:io';

import 'package:clay/config.dart';
import 'package:clay/src/features/config/matches_ignore_pattern.dart'
    show normalizeIgnoreRelativePath;
import 'package:path/path.dart' as p;
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

  group('ignorePatternValidationError', () {
    test('allows relative and root-anchored patterns', () {
      for (final pattern in [
        'build/',
        '/build/',
        'packages/app/build/',
        '**/*.iml',
        '.DS_Store',
        '!build/keep.dart',
        '!',
      ]) {
        expect(
          ignorePatternValidationError(pattern),
          isNull,
          reason: pattern,
        );
      }
    });

    test('allows POSIX root-anchored patterns that resemble home paths', () {
      for (final pattern in [
        '/Users/app/build/',
        '/home/user/project/.dart_tool/',
        '!/var/tmp/output',
      ]) {
        expect(
          ignorePatternValidationError(pattern),
          isNull,
          reason: pattern,
        );
      }
    });

    test('rejects backslash separators', () {
      for (final pattern in [
        r'build\out',
        r'packages\app\build\',
        r'!\\server\share\build',
        r'\build\out',
        r'C:\Users\app\build',
      ]) {
        expect(
          ignorePatternValidationError(pattern),
          contains('POSIX-style forward slashes'),
          reason: pattern,
        );
      }
    });

    test('rejects Windows drive-letter paths with forward slashes', () {
      for (final pattern in [
        'C:/Users/app/build',
        '!D:/temp/out',
      ]) {
        expect(
          ignorePatternValidationError(pattern),
          contains('Windows-absolute paths'),
          reason: pattern,
        );
      }
    });

    test('returns guidance for double-leading-slash patterns', () {
      expect(
        ignorePatternValidationError('//Users/app/build'),
        contains('use a single leading / to anchor to the scan root'),
      );
    });
  });

  group('validateIgnorePatterns', () {
    test('accepts valid pattern sets', () {
      expect(
        () => validateIgnorePatterns(
          const ['build/', '/coverage/', '!build/keep.dart'],
        ),
        returnsNormally,
      );
    });

    test('throws when any pattern is Windows-absolute', () {
      expect(
        () => validateIgnorePatterns(const ['build/', r'C:\temp\out']),
        throwsFormatException,
      );
    });
  });

  group('relativePathWithinRoot', () {
    late Directory tempDir;
    late String referenceRoot;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_ignore_root_');
      referenceRoot = p.join(tempDir.path, 'reference');
      Directory(referenceRoot).createSync(recursive: true);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('returns normalized path for files under the root', () {
      final filePath = p.join(referenceRoot, 'lib', 'main.dart');

      expect(
        relativePathWithinRoot(
          rootDirectory: referenceRoot,
          absolutePath: filePath,
        ),
        'lib/main.dart',
      );
    });

    test('returns null for files outside the root', () {
      final outsidePath = p.join(tempDir.path, 'outside.dart');

      expect(
        relativePathWithinRoot(
          rootDirectory: referenceRoot,
          absolutePath: outsidePath,
        ),
        isNull,
      );
    });
  });

  group('shouldIgnoreAtRoot', () {
    late Directory tempDir;
    late String referenceRoot;
    late String targetRoot;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_ignore_scan_');
      referenceRoot = p.join(tempDir.path, 'reference');
      targetRoot = p.join(tempDir.path, 'brick', '__brick__');
      Directory(referenceRoot).createSync(recursive: true);
      Directory(targetRoot).createSync(recursive: true);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('ignores build artifacts under the reference root at any depth', () {
      const patterns = ['build/'];

      expect(
        shouldIgnoreAtRoot(
          rootDirectory: referenceRoot,
          absolutePath: p.join(referenceRoot, 'build', 'app.dill'),
          patterns: patterns,
        ),
        isTrue,
      );
      expect(
        shouldIgnoreAtRoot(
          rootDirectory: referenceRoot,
          absolutePath:
              p.join(referenceRoot, 'packages', 'app', 'build', 'out.txt'),
          patterns: patterns,
        ),
        isTrue,
      );
    });

    test('applies root-anchored patterns only at the scan root', () {
      const patterns = ['/build/'];

      expect(
        shouldIgnoreAtRoot(
          rootDirectory: referenceRoot,
          absolutePath: p.join(referenceRoot, 'build', 'app.dill'),
          patterns: patterns,
        ),
        isTrue,
      );
      expect(
        shouldIgnoreAtRoot(
          rootDirectory: referenceRoot,
          absolutePath:
              p.join(referenceRoot, 'packages', 'app', 'build', 'out.txt'),
          patterns: patterns,
        ),
        isFalse,
      );
    });

    test('uses the same relative semantics when scanning the target root', () {
      const patterns = ['.dart_tool/', 'coverage/'];

      expect(
        shouldIgnoreAtRoot(
          rootDirectory: targetRoot,
          absolutePath: p.join(targetRoot, '.dart_tool', 'package_config.json'),
          patterns: patterns,
        ),
        isTrue,
      );
      expect(
        shouldIgnoreAtRoot(
          rootDirectory: targetRoot,
          absolutePath: p.join(targetRoot, 'lib', 'main.dart'),
          patterns: patterns,
        ),
        isFalse,
      );
    });

    test('does not ignore files outside the scan root', () {
      expect(
        shouldIgnoreAtRoot(
          rootDirectory: referenceRoot,
          absolutePath: p.join(tempDir.path, 'other', 'build', 'out.txt'),
          patterns: const ['build/'],
        ),
        isFalse,
      );
    });

    test('applies POSIX-looking root anchors relative to the scan root', () {
      const patterns = ['/Users/app/build/'];

      expect(
        shouldIgnoreAtRoot(
          rootDirectory: referenceRoot,
          absolutePath:
              p.join(referenceRoot, 'Users', 'app', 'build', 'out.txt'),
          patterns: patterns,
        ),
        isTrue,
      );
      expect(
        shouldIgnoreAtRoot(
          rootDirectory: referenceRoot,
          absolutePath: p.join(
            referenceRoot,
            'packages',
            'Users',
            'app',
            'build',
            'out.txt',
          ),
          patterns: patterns,
        ),
        isFalse,
      );
    });

    test('applies negation using root-relative paths', () {
      const patterns = ['build/', '!build/keep.dart'];

      expect(
        shouldIgnoreAtRoot(
          rootDirectory: referenceRoot,
          absolutePath: p.join(referenceRoot, 'build', 'keep.dart'),
          patterns: patterns,
        ),
        isFalse,
      );
      expect(
        shouldIgnoreAtRoot(
          rootDirectory: referenceRoot,
          absolutePath: p.join(referenceRoot, 'build', 'remove.dart'),
          patterns: patterns,
        ),
        isTrue,
      );
    });
  });

  group('expandIgnorePattern', () {
    test('returns no globs for root-only patterns', () {
      expect(expandIgnorePattern('/'), isEmpty);
    });

    test('expands path-specific file patterns', () {
      expect(expandIgnorePattern('lib/main.dart'), ['lib/main.dart']);
      expect(expandIgnorePattern('/main.dart'), ['main.dart']);
    });

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
    test('matches unanchored directory patterns at any depth', () {
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
