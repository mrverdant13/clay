/// Unwraps Mustache tags from comment wrappers in [content].
///
/// Supports C-style, hash, and HTML comment flavors. Optional `x` flags before
/// or after the tag drop adjacent whitespace on that side.
String applyMustacheTags({required String content}) {
  const patterns = [
    r'(?<leading>\s*)\/\*(?<dropLeading>x)?(?<mustacheTag>{{.*?}})(?<dropTrailing>x)?\*\/(?<trailing>\s*)',
    r'(?<leading>\s*)#(?<dropLeading>x)?(?<mustacheTag>{{.*?}})(?<dropTrailing>x)?#(?<trailing>\s*)',
    r'(?<leading>\s*)<!--(?<dropLeading>x)?(?<mustacheTag>{{.*?}})(?<dropTrailing>x)?-->(?<trailing>\s*)',
  ];

  return patterns.fold(content, (resolved, pattern) {
    final regex = RegExp(pattern, dotAll: true);
    return resolved.replaceAllMapped(regex, (match) {
      match as RegExpMatch;
      final mustacheTag = match.namedGroup('mustacheTag') ?? '';
      final keepLeading = (match.namedGroup('dropLeading') ?? '').isEmpty;
      final keepTrailing = (match.namedGroup('dropTrailing') ?? '').isEmpty;
      final leading = match.namedGroup('leading') ?? '';
      final trailing = match.namedGroup('trailing') ?? '';
      return [
        if (keepLeading) leading,
        mustacheTag,
        if (keepTrailing) trailing,
      ].join();
    });
  });
}
