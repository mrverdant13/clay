import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolves `partial v <name>` / `partial ^ <name>` blocks in [content].
///
/// Extracts partial payloads into `{{~ name.partial }}` files under
/// [targetAbsolutePath] and replaces each block with `{{> name.partial }}`.
/// Supports C-style, hash, and HTML comment flavors.
///
/// [partialName] values are trimmed and must not be empty, `.`, `..`, or
/// contain path separators. Invalid names throw [FormatException].
String applyPartials({
  required String content,
  required String targetAbsolutePath,
}) {
  const partialPatterns = [
    r'\/\*partial v (?<partialName>.*?)\*\/(?<partialPayload>.*?)\/\*partial \^ \k<partialName>\*\/',
    r'#partial v (?<partialName>.*?)#(?<partialPayload>.*?)#partial \^ \k<partialName>#',
    r'<!--partial v (?<partialName>.*?)-->(?<partialPayload>.*?)<!--partial \^ \k<partialName>-->',
  ];

  return partialPatterns.fold(content, (resolved, pattern) {
    final regex = RegExp(pattern, dotAll: true);
    return resolved.replaceAllMapped(regex, (match) {
      match as RegExpMatch;
      final rawPartialName = match.namedGroup('partialName') ?? '';
      final partialName = _validatedPartialName(rawPartialName);
      final partialPayload = match.namedGroup('partialPayload') ?? '';
      File(p.join(targetAbsolutePath, '{{~ $partialName.partial }}'))
        ..createSync(recursive: true)
        ..writeAsStringSync(partialPayload);
      return '{{> $partialName.partial }}';
    });
  });
}

String _validatedPartialName(String rawName) {
  final name = rawName.trim();
  if (name.isEmpty ||
      name == '.' ||
      name == '..' ||
      name.contains('/') ||
      name.contains(r'\')) {
    throw FormatException(
      'Invalid partial name "$rawName": must be non-empty and must not be '
      '".", "..", or contain path separators.',
    );
  }
  return name;
}
