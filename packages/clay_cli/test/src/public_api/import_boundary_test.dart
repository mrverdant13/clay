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

    final uriMatch = uriPattern.firstMatch(line);
    if (uriMatch == null) {
      continue;
    }

    final uri = uriMatch.group(1)!;
    if (uri.startsWith('dart:') || !uri.startsWith('package:')) {
      continue;
    }

    if (uri.contains('/_internal/') || uri.endsWith('/_internal')) {
      violations.add('$relativePath:${index + 1}: internal path $uri');
      continue;
    }

    final packageName = uri.substring('package:'.length).split('/').first;
    if (!allowedPackages.contains(packageName)) {
      violations.add(
        '$relativePath:${index + 1}: disallowed package $packageName',
      );
    }
  }

  return violations;
}

void main() {
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
