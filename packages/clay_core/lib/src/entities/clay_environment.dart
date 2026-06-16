import 'package:clay_core/src/utils/version_constraint_hook.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

part 'clay_environment.mapper.dart';

/// Semver environment constraints declared in `clay.yaml`.
@immutable
@MappableClass()
class ClayEnvironment with ClayEnvironmentMappable {
  /// Creates a [ClayEnvironment].
  ClayEnvironment({VersionConstraint? clay})
      : clay = clay ?? defaultClayConstraint;

  /// Creates a [ClayEnvironment] from a config map.
  // ignore: specify_nonobvious_property_types
  static const fromMap = ClayEnvironmentMapper.fromMap;

  /// Default [ClayEnvironment.clay] when omitted.
  static final VersionConstraint defaultClayConstraint = VersionConstraint.any;

  /// Semver constraint for the Clay CLI/library version required by this project.
  @MappableField(hook: versionConstraintHook)
  final VersionConstraint clay;
}
