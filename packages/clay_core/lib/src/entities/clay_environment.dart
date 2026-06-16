import 'package:dart_mappable/dart_mappable.dart';
import 'package:meta/meta.dart';

part 'clay_environment.mapper.dart';

/// Semver environment constraints declared in `clay.yaml`.
@immutable
@MappableClass()
class ClayEnvironment with ClayEnvironmentMappable {
  /// Creates a [ClayEnvironment].
  const ClayEnvironment({this.clay = defaultClayConstraint});

  /// Creates a [ClayEnvironment] from a config map.
  // ignore: specify_nonobvious_property_types
  static const fromMap = ClayEnvironmentMapper.fromMap;

  /// Default [ClayEnvironment.clay] when omitted.
  static const defaultClayConstraint = 'any';

  /// Semver constraint for the Clay CLI/library version required by this project.
  final String clay;
}
