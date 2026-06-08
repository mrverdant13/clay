/// Parses `key=value` pairs from a comma-separated CLI value.
Map<String, dynamic> parsePreviewVars(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return {};
  }

  return {
    for (final pair in raw.split(','))
      if (pair.trim().isNotEmpty) ..._parsePreviewVarPair(pair.trim()),
  };
}

Map<String, dynamic> _parsePreviewVarPair(String pair) {
  final separatorIndex = pair.indexOf('=');
  if (separatorIndex <= 0) {
    throw FormatException(
      'Invalid --vars entry (expected key=value): $pair',
    );
  }

  final key = pair.substring(0, separatorIndex).trim();
  final rawValue = pair.substring(separatorIndex + 1).trim();
  return {key: _parsePreviewVarValue(rawValue)};
}

dynamic _parsePreviewVarValue(String rawValue) {
  if (rawValue == 'true') {
    return true;
  }
  if (rawValue == 'false') {
    return false;
  }

  final intValue = int.tryParse(rawValue);
  if (intValue != null) {
    return intValue;
  }

  if ((rawValue.startsWith('"') && rawValue.endsWith('"')) ||
      (rawValue.startsWith("'") && rawValue.endsWith("'"))) {
    return rawValue.substring(1, rawValue.length - 1);
  }

  return rawValue;
}
