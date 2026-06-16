/// Thrown when `clay.yaml` cannot be loaded or parsed.
class ClayConfigException implements Exception {
  /// Creates a [ClayConfigException].
  const ClayConfigException(this.message);

  /// Human-readable error description.
  final String message;

  @override
  String toString() => message;
}

/// Thrown when the running Clay version does not satisfy `environment.clay`.
class ClayIncompatibleException implements Exception {
  /// Creates a [ClayIncompatibleException].
  const ClayIncompatibleException({
    required this.currentVersion,
    required this.requiredConstraint,
  });

  /// The installed Clay library version.
  final String currentVersion;

  /// The semver constraint declared in `environment.clay`.
  final String requiredConstraint;

  @override
  String toString() =>
      'The current clay version is $currentVersion.\n'
      'This project requires clay version $requiredConstraint.';
}

/// Thrown when `clay.yaml` cannot be discovered.
class ClayConfigNotFoundException implements Exception {
  /// Creates a [ClayConfigNotFoundException].
  const ClayConfigNotFoundException({
    required this.message,
    required this.searchedPaths,
  });

  /// Human-readable error description.
  final String message;

  /// Candidate paths checked during discovery.
  final List<String> searchedPaths;

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (searchedPaths.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Searched paths:')
        ..writeAll(searchedPaths.map((path) => '  $path'), '\n');
    }
    return buffer.toString();
  }
}
