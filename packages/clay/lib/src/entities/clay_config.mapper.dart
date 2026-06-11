// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'clay_config.dart';

class ClayConfigMapper extends ClassMapperBase<ClayConfig> {
  ClayConfigMapper._();

  static ClayConfigMapper? _instance;
  static ClayConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ClayConfigMapper._());
      ReplacementMapper.ensureInitialized();
      LineDeletionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ClayConfig';

  static String _$reference(ClayConfig v) => v.reference;
  static const Field<ClayConfig, String> _f$reference = Field(
    'reference',
    _$reference,
    opt: true,
    def: ClayConfig.defaultReferencePath,
  );
  static List<String> _$ignore(ClayConfig v) => v.ignore;
  static const Field<ClayConfig, List<String>> _f$ignore = Field(
    'ignore',
    _$ignore,
    opt: true,
    def: const [],
  );
  static List<Replacement> _$replacements(ClayConfig v) => v.replacements;
  static const Field<ClayConfig, List<Replacement>> _f$replacements = Field(
    'replacements',
    _$replacements,
    opt: true,
    def: const [],
  );
  static List<LineDeletion> _$lineDeletions(ClayConfig v) => v.lineDeletions;
  static const Field<ClayConfig, List<LineDeletion>> _f$lineDeletions = Field(
    'lineDeletions',
    _$lineDeletions,
    opt: true,
    def: const [],
  );
  static String _$target(ClayConfig v) => v.target;
  static const Field<ClayConfig, String> _f$target = Field(
    'target',
    _$target,
    opt: true,
  );

  @override
  final MappableFields<ClayConfig> fields = const {
    #reference: _f$reference,
    #ignore: _f$ignore,
    #replacements: _f$replacements,
    #lineDeletions: _f$lineDeletions,
    #target: _f$target,
  };

  static ClayConfig _instantiate(DecodingData data) {
    return ClayConfig(
      reference: data.dec(_f$reference),
      ignore: data.dec(_f$ignore),
      replacements: data.dec(_f$replacements),
      lineDeletions: data.dec(_f$lineDeletions),
      target: data.dec(_f$target),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ClayConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ClayConfig>(map);
  }

  static ClayConfig fromJson(String json) {
    return ensureInitialized().decodeJson<ClayConfig>(json);
  }
}

mixin ClayConfigMappable {
  String toJson() {
    return ClayConfigMapper.ensureInitialized().encodeJson<ClayConfig>(
      this as ClayConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return ClayConfigMapper.ensureInitialized().encodeMap<ClayConfig>(
      this as ClayConfig,
    );
  }

  ClayConfigCopyWith<ClayConfig, ClayConfig, ClayConfig> get copyWith =>
      _ClayConfigCopyWithImpl<ClayConfig, ClayConfig>(
        this as ClayConfig,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ClayConfigMapper.ensureInitialized().stringifyValue(
      this as ClayConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return ClayConfigMapper.ensureInitialized().equalsValue(
      this as ClayConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return ClayConfigMapper.ensureInitialized().hashValue(this as ClayConfig);
  }
}

extension ClayConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ClayConfig, $Out> {
  ClayConfigCopyWith<$R, ClayConfig, $Out> get $asClayConfig =>
      $base.as((v, t, t2) => _ClayConfigCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ClayConfigCopyWith<$R, $In extends ClayConfig, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get ignore;
  ListCopyWith<$R, Replacement,
      ReplacementCopyWith<$R, Replacement, Replacement>> get replacements;
  ListCopyWith<$R, LineDeletion,
      LineDeletionCopyWith<$R, LineDeletion, LineDeletion>> get lineDeletions;
  $R call({
    String? reference,
    List<String>? ignore,
    List<Replacement>? replacements,
    List<LineDeletion>? lineDeletions,
    String? target,
  });
  ClayConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ClayConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ClayConfig, $Out>
    implements ClayConfigCopyWith<$R, ClayConfig, $Out> {
  _ClayConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ClayConfig> $mapper =
      ClayConfigMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get ignore =>
      ListCopyWith(
        $value.ignore,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(ignore: v),
      );
  @override
  ListCopyWith<$R, Replacement,
          ReplacementCopyWith<$R, Replacement, Replacement>>
      get replacements => ListCopyWith(
            $value.replacements,
            (v, t) => v.copyWith.$chain(t),
            (v) => call(replacements: v),
          );
  @override
  ListCopyWith<$R, LineDeletion,
          LineDeletionCopyWith<$R, LineDeletion, LineDeletion>>
      get lineDeletions => ListCopyWith(
            $value.lineDeletions,
            (v, t) => v.copyWith.$chain(t),
            (v) => call(lineDeletions: v),
          );
  @override
  $R call({
    String? reference,
    List<String>? ignore,
    List<Replacement>? replacements,
    List<LineDeletion>? lineDeletions,
    Object? target = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (reference != null) #reference: reference,
          if (ignore != null) #ignore: ignore,
          if (replacements != null) #replacements: replacements,
          if (lineDeletions != null) #lineDeletions: lineDeletions,
          if (target != $none) #target: target,
        }),
      );
  @override
  ClayConfig $make(CopyWithData data) => ClayConfig(
        reference: data.get(#reference, or: $value.reference),
        ignore: data.get(#ignore, or: $value.ignore),
        replacements: data.get(#replacements, or: $value.replacements),
        lineDeletions: data.get(#lineDeletions, or: $value.lineDeletions),
        target: data.get(#target, or: $value.target),
      );

  @override
  ClayConfigCopyWith<$R2, ClayConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _ClayConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
