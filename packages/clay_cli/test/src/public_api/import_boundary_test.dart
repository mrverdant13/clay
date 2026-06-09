import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Directory _packageRoot() {
  var current = Directory.current;
  while (true) {
    final pubspec = File(p.join(current.path, 'pubspec.yaml'));
    if (pubspec.existsSync() &&
        pubspec.readAsStringSync().contains('name: clay_cli')) {
      return current;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      fail(
        'Could not locate clay_cli package root '
        'from ${Directory.current.path}',
      );
    }
    current = parent;
  }
}

/// Scans [lines] for disallowed `package:` imports.
List<String> scanImportViolations({
  required List<String> lines,
  required String relativePath,
  required Set<String> allowedPackages,
}) {
  final violations = <String>[];
  final uriPattern = RegExp("['\"]([^'\"]+)['\"]");

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trimLeft();
    if (!line.startsWith('import ')) {
      continue;
    }

    final directiveStartLine = index + 1;
    final directiveLines = <String>[];
    var directiveEndIndex = index;

    while (directiveEndIndex < lines.length) {
      directiveLines.add(lines[directiveEndIndex]);
      if (lines[directiveEndIndex].contains(';')) {
        break;
      }
      directiveEndIndex++;
    }

    final directive = directiveLines.join('\n');
    index = directiveEndIndex;

    for (final uriMatch in uriPattern.allMatches(directive)) {
      final uri = uriMatch.group(1)!;
      if (uri.startsWith('dart:') || !uri.startsWith('package:')) {
        continue;
      }

      if (uri.contains('/_internal/') || uri.endsWith('/_internal')) {
        violations.add(
          '$relativePath:$directiveStartLine: internal path $uri',
        );
        continue;
      }

      final packageName = uri.substring('package:'.length).split('/').first;
      if (!allowedPackages.contains(packageName)) {
        violations.add(
          '$relativePath:$directiveStartLine: disallowed package $packageName',
        );
      }
    }
  }

  return violations;
}

void main() {
  group('scanImportViolations', () {
    const allowedPackages = {'clay_cli', 'path'};
    const relativePath = 'example.dart';

    test('allows a single-line package import', () {
      expect(
        scanImportViolations(
          lines: ["import 'package:clay_cli/foo.dart';"],
          relativePath: relativePath,
          allowedPackages: allowedPackages,
        ),
        isEmpty,
      );
    });

    test('allows a multi-line show import', () {
      expect(
        scanImportViolations(
          lines: [
            "import 'package:clay_cli/src/features/config/matches_ignore_pattern.dart'",
            '    show normalizeIgnoreRelativePath, shouldIgnoreAtRoot;',
          ],
          relativePath: relativePath,
          allowedPackages: allowedPackages,
        ),
        isEmpty,
      );
    });

    test('flags disallowed packages in conditional imports', () {
      expect(
        scanImportViolations(
          lines: [
            "import 'package:clay_cli/foo.dart'",
            "    if (dart.library.io) 'package:evil/bar.dart';",
          ],
          relativePath: relativePath,
          allowedPackages: allowedPackages,
        ),
        ['example.dart:1: disallowed package evil'],
      );
    });

    test('flags internal package paths', () {
      expect(
        scanImportViolations(
          lines: ["import 'package:clay_cli/src/_internal/hidden.dart';"],
          relativePath: relativePath,
          allowedPackages: allowedPackages,
        ),
        [
          'example.dart:1: internal path '
              'package:clay_cli/src/_internal/hidden.dart',
        ],
      );
    });

    test('ignores dart: imports', () {
      expect(
        scanImportViolations(
          lines: ["import 'dart:io';"],
          relativePath: relativePath,
          allowedPackages: allowedPackages,
        ),
        isEmpty,
      );
    });
  });

  group('import boundary', () {
    const allowedPackages = {
      'args',
      'clay_cli',
      'dart_mappable',
      'glob',
      'mason',
      'mason_logger',
      'meta',
      'path',
    };

    late Directory libDir;

    setUp(() {
      libDir = Directory(p.join(_packageRoot().path, 'lib'));
    });

    test('lib sources only import allowed packages', () {
      final violations = <String>[];

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }

        final relativePath = p.relative(entity.path, from: libDir.path);
        violations.addAll(
          scanImportViolations(
            lines: entity.readAsLinesSync(),
            relativePath: relativePath,
            allowedPackages: allowedPackages,
          ),
        );
      }

      expect(
        violations,
        isEmpty,
        reason: 'Unexpected imports:\n${violations.join('\n')}',
      );
    });
  });
}
