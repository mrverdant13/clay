import 'package:dart_mappable/dart_mappable.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

/// Parses [constraint] as a semver version constraint.
///
/// Throws [FormatException] when [constraint] is not a valid constraint string.
VersionConstraint parseClayVersionConstraint(String constraint) {
  if (constraint.isEmpty) {
    throw const FormatException('environment.clay must not be empty');
  }

  try {
    return VersionConstraint.parse(constraint);
  } on FormatException catch (error) {
    throw FormatException(
      'environment.clay must be a valid semver constraint: ${error.message}',
    );
  }
}

/// A [MappingHook] for encoding and decoding [VersionConstraint] values.
@visibleForTesting
class VersionConstraintHook extends MappingHook {
  /// Creates a [VersionConstraintHook].
  @visibleForTesting
  const VersionConstraintHook();

  @override
  Object? beforeDecode(Object? value) {
    return switch (value) {
      null => null,
      final VersionConstraint value => value,
      final String value => parseClayVersionConstraint(value),
      _ => throw const FormatException('environment.clay must be a string'),
    };
  }

  @override
  Object? beforeEncode(Object? value) {
    return switch (value) {
      null => null,
      final VersionConstraint value => value.toString(),
      _ => value,
    };
  }
}

/// Hook instance for [VersionConstraint] fields in mappable entities.
const versionConstraintHook = VersionConstraintHook();
