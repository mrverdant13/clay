/// Expands spacing group annotations in [content].
///
/// Supports C-style, hash, and HTML comment flavors. Actions use `Nv` for
/// newlines and `N>` for spaces (for example `2v 4>`).
String applySpacingGroups({required String content}) {
  const groupPatterns = [
    r'\s*\/\*w ?(?<spacingGroups>(?:\d+[v>] ?)*) ?w\*\/\s*',
    r'\s*#w ?(?<spacingGroups>(?:\d+[v>] ?)*) ?w#\s*',
    r'\s*<!--w ?(?<spacingGroups>(?:\d+[v>] ?)*) ?w-->\s*',
  ];
  const actionPattern = r'(?<actionTimes>\d+)(?<actionType>[v>]) ?';

  return groupPatterns.fold(content, (resolved, groupPattern) {
    final groupRegex = RegExp(groupPattern, dotAll: true);
    final actionRegex = RegExp(actionPattern, dotAll: true);
    return resolved.replaceAllMapped(groupRegex, (match) {
      match as RegExpMatch;
      final spacingGroups = match.namedGroup('spacingGroups') ?? '';
      return spacingGroups.replaceAllMapped(actionRegex, (actionMatch) {
        actionMatch as RegExpMatch;
        final actionTimes =
            int.tryParse(actionMatch.namedGroup('actionTimes') ?? '') ?? 0;
        final actionType = actionMatch.namedGroup('actionType') ?? '';
        return switch (actionType) {
              'v' => '\n',
              '>' => ' ',
              _ => '',
            } *
            actionTimes;
      });
    });
  });
}
