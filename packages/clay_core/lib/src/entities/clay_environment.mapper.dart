// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'clay_environment.dart';

class ClayEnvironmentMapper extends ClassMapperBase<ClayEnvironment> {
  ClayEnvironmentMapper._();

  static ClayEnvironmentMapper? _instance;
  static ClayEnvironmentMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ClayEnvironmentMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ClayEnvironment';

  static VersionConstraint _$clay(ClayEnvironment v) => v.clay;
  static const Field<ClayEnvironment, VersionConstraint> _f$clay = Field(
    'clay',
    _$clay,
    opt: true,
    hook: versionConstraintHook,
  );

  @override
  final MappableFields<ClayEnvironment> fields = const {#clay: _f$clay};

  static ClayEnvironment _instantiate(DecodingData data) {
    return ClayEnvironment(clay: data.dec(_f$clay));
  }

  @override
  final Function instantiate = _instantiate;

  static ClayEnvironment fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ClayEnvironment>(map);
  }

  static ClayEnvironment fromJson(String json) {
    return ensureInitialized().decodeJson<ClayEnvironment>(json);
  }
}

mixin ClayEnvironmentMappable {
  String toJson() {
    return ClayEnvironmentMapper.ensureInitialized()
        .encodeJson<ClayEnvironment>(this as ClayEnvironment);
  }

  Map<String, dynamic> toMap() {
    return ClayEnvironmentMapper.ensureInitialized().encodeMap<ClayEnvironment>(
      this as ClayEnvironment,
    );
  }

  ClayEnvironmentCopyWith<ClayEnvironment, ClayEnvironment, ClayEnvironment>
      get copyWith =>
          _ClayEnvironmentCopyWithImpl<ClayEnvironment, ClayEnvironment>(
            this as ClayEnvironment,
            $identity,
            $identity,
          );
  @override
  String toString() {
    return ClayEnvironmentMapper.ensureInitialized().stringifyValue(
      this as ClayEnvironment,
    );
  }

  @override
  bool operator ==(Object other) {
    return ClayEnvironmentMapper.ensureInitialized().equalsValue(
      this as ClayEnvironment,
      other,
    );
  }

  @override
  int get hashCode {
    return ClayEnvironmentMapper.ensureInitialized().hashValue(
      this as ClayEnvironment,
    );
  }
}

extension ClayEnvironmentValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ClayEnvironment, $Out> {
  ClayEnvironmentCopyWith<$R, ClayEnvironment, $Out> get $asClayEnvironment =>
      $base.as((v, t, t2) => _ClayEnvironmentCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ClayEnvironmentCopyWith<$R, $In extends ClayEnvironment, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({VersionConstraint? clay});
  ClayEnvironmentCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ClayEnvironmentCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ClayEnvironment, $Out>
    implements ClayEnvironmentCopyWith<$R, ClayEnvironment, $Out> {
  _ClayEnvironmentCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ClayEnvironment> $mapper =
      ClayEnvironmentMapper.ensureInitialized();
  @override
  $R call({Object? clay = $none}) =>
      $apply(FieldCopyWithData({if (clay != $none) #clay: clay}));
  @override
  ClayEnvironment $make(CopyWithData data) =>
      ClayEnvironment(clay: data.get(#clay, or: $value.clay));

  @override
  ClayEnvironmentCopyWith<$R2, ClayEnvironment, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _ClayEnvironmentCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
