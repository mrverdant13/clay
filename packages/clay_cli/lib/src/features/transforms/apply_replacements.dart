import 'package:clay_cli/src/entities/replacement.dart';

/// Applies a single [replacement] to [input], interpolating `${n}` capture
/// groups.
String applyReplacement({
  required String input,
  required Replacement replacement,
}) {
  final toGroupMatches = RegExp(r'\${(\d+)}').allMatches(replacement.to);
  final seenGroups = <int>{};
  final toGroups = [
    for (final groupMatch in toGroupMatches)
      if (seenGroups.add(int.parse(groupMatch.group(1)!)))
        int.parse(groupMatch.group(1)!),
  ];

  return input.replaceAllMapped(replacement.from, (match) {
    match as RegExpMatch;
    return toGroups.fold(
      replacement.to,
      (resolved, group) => resolved.replaceAll(
        '\${$group}',
        match.group(group) ?? '',
      ),
    );
  });
}

/// Applies [replacements] sequentially to [input] (file paths or contents).
String applyReplacements({
  required String input,
  required List<Replacement> replacements,
}) {
  return replacements.fold(
    input,
    (resolved, replacement) => applyReplacement(
      input: resolved,
      replacement: replacement,
    ),
  );
}
