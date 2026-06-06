// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'brick_gen_config.dart';

class BrickGenConfigMapper extends ClassMapperBase<BrickGenConfig> {
  BrickGenConfigMapper._();

  static BrickGenConfigMapper? _instance;
  static BrickGenConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = BrickGenConfigMapper._());
      ReplacementMapper.ensureInitialized();
      LineDeletionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'BrickGenConfig';

  static String _$reference(BrickGenConfig v) => v.reference;
  static const Field<BrickGenConfig, String> _f$reference = Field(
    'reference',
    _$reference,
    opt: true,
    def: BrickGenConfig.defaultReferencePath,
  );
  static List<String> _$ignore(BrickGenConfig v) => v.ignore;
  static const Field<BrickGenConfig, List<String>> _f$ignore = Field(
    'ignore',
    _$ignore,
    opt: true,
    def: const [],
  );
  static List<Replacement> _$replacements(BrickGenConfig v) => v.replacements;
  static const Field<BrickGenConfig, List<Replacement>> _f$replacements = Field(
    'replacements',
    _$replacements,
    opt: true,
    def: const [],
  );
  static List<LineDeletion> _$lineDeletions(BrickGenConfig v) =>
      v.lineDeletions;
  static const Field<BrickGenConfig, List<LineDeletion>> _f$lineDeletions =
      Field('lineDeletions', _$lineDeletions, opt: true, def: const []);
  static String _$target(BrickGenConfig v) => v.target;
  static const Field<BrickGenConfig, String> _f$target = Field(
    'target',
    _$target,
    opt: true,
  );

  @override
  final MappableFields<BrickGenConfig> fields = const {
    #reference: _f$reference,
    #ignore: _f$ignore,
    #replacements: _f$replacements,
    #lineDeletions: _f$lineDeletions,
    #target: _f$target,
  };

  static BrickGenConfig _instantiate(DecodingData data) {
    return BrickGenConfig(
      reference: data.dec(_f$reference),
      ignore: data.dec(_f$ignore),
      replacements: data.dec(_f$replacements),
      lineDeletions: data.dec(_f$lineDeletions),
      target: data.dec(_f$target),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static BrickGenConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<BrickGenConfig>(map);
  }

  static BrickGenConfig fromJson(String json) {
    return ensureInitialized().decodeJson<BrickGenConfig>(json);
  }
}

mixin BrickGenConfigMappable {
  String toJson() {
    return BrickGenConfigMapper.ensureInitialized().encodeJson<BrickGenConfig>(
      this as BrickGenConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return BrickGenConfigMapper.ensureInitialized().encodeMap<BrickGenConfig>(
      this as BrickGenConfig,
    );
  }

  BrickGenConfigCopyWith<BrickGenConfig, BrickGenConfig, BrickGenConfig>
      get copyWith =>
          _BrickGenConfigCopyWithImpl<BrickGenConfig, BrickGenConfig>(
            this as BrickGenConfig,
            $identity,
            $identity,
          );
  @override
  String toString() {
    return BrickGenConfigMapper.ensureInitialized().stringifyValue(
      this as BrickGenConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return BrickGenConfigMapper.ensureInitialized().equalsValue(
      this as BrickGenConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return BrickGenConfigMapper.ensureInitialized().hashValue(
      this as BrickGenConfig,
    );
  }
}

extension BrickGenConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, BrickGenConfig, $Out> {
  BrickGenConfigCopyWith<$R, BrickGenConfig, $Out> get $asBrickGenConfig =>
      $base.as((v, t, t2) => _BrickGenConfigCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class BrickGenConfigCopyWith<$R, $In extends BrickGenConfig, $Out>
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
  BrickGenConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _BrickGenConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, BrickGenConfig, $Out>
    implements BrickGenConfigCopyWith<$R, BrickGenConfig, $Out> {
  _BrickGenConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<BrickGenConfig> $mapper =
      BrickGenConfigMapper.ensureInitialized();
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
  BrickGenConfig $make(CopyWithData data) => BrickGenConfig(
        reference: data.get(#reference, or: $value.reference),
        ignore: data.get(#ignore, or: $value.ignore),
        replacements: data.get(#replacements, or: $value.replacements),
        lineDeletions: data.get(#lineDeletions, or: $value.lineDeletions),
        target: data.get(#target, or: $value.target),
      );

  @override
  BrickGenConfigCopyWith<$R2, BrickGenConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _BrickGenConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
