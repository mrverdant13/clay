// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'line_deletion.dart';

class LineDeletionMapper extends ClassMapperBase<LineDeletion> {
  LineDeletionMapper._();

  static LineDeletionMapper? _instance;
  static LineDeletionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LineDeletionMapper._());
      LineRangeMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'LineDeletion';

  static String _$filePath(LineDeletion v) => v.filePath;
  static const Field<LineDeletion, String> _f$filePath = Field(
    'filePath',
    _$filePath,
  );
  static List<LineRange> _$ranges(LineDeletion v) => v.ranges;
  static const Field<LineDeletion, List<LineRange>> _f$ranges = Field(
    'ranges',
    _$ranges,
  );

  @override
  final MappableFields<LineDeletion> fields = const {
    #filePath: _f$filePath,
    #ranges: _f$ranges,
  };

  static LineDeletion _instantiate(DecodingData data) {
    return LineDeletion(
      filePath: data.dec(_f$filePath),
      ranges: data.dec(_f$ranges),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static LineDeletion fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LineDeletion>(map);
  }

  static LineDeletion fromJson(String json) {
    return ensureInitialized().decodeJson<LineDeletion>(json);
  }
}

mixin LineDeletionMappable {
  String toJson() {
    return LineDeletionMapper.ensureInitialized().encodeJson<LineDeletion>(
      this as LineDeletion,
    );
  }

  Map<String, dynamic> toMap() {
    return LineDeletionMapper.ensureInitialized().encodeMap<LineDeletion>(
      this as LineDeletion,
    );
  }

  LineDeletionCopyWith<LineDeletion, LineDeletion, LineDeletion> get copyWith =>
      _LineDeletionCopyWithImpl<LineDeletion, LineDeletion>(
        this as LineDeletion,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return LineDeletionMapper.ensureInitialized().stringifyValue(
      this as LineDeletion,
    );
  }

  @override
  bool operator ==(Object other) {
    return LineDeletionMapper.ensureInitialized().equalsValue(
      this as LineDeletion,
      other,
    );
  }

  @override
  int get hashCode {
    return LineDeletionMapper.ensureInitialized().hashValue(
      this as LineDeletion,
    );
  }
}

extension LineDeletionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, LineDeletion, $Out> {
  LineDeletionCopyWith<$R, LineDeletion, $Out> get $asLineDeletion =>
      $base.as((v, t, t2) => _LineDeletionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class LineDeletionCopyWith<$R, $In extends LineDeletion, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, LineRange, LineRangeCopyWith<$R, LineRange, LineRange>>
      get ranges;
  $R call({String? filePath, List<LineRange>? ranges});
  LineDeletionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _LineDeletionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LineDeletion, $Out>
    implements LineDeletionCopyWith<$R, LineDeletion, $Out> {
  _LineDeletionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LineDeletion> $mapper =
      LineDeletionMapper.ensureInitialized();
  @override
  ListCopyWith<$R, LineRange, LineRangeCopyWith<$R, LineRange, LineRange>>
      get ranges => ListCopyWith(
            $value.ranges,
            (v, t) => v.copyWith.$chain(t),
            (v) => call(ranges: v),
          );
  @override
  $R call({String? filePath, List<LineRange>? ranges}) => $apply(
        FieldCopyWithData({
          if (filePath != null) #filePath: filePath,
          if (ranges != null) #ranges: ranges,
        }),
      );
  @override
  LineDeletion $make(CopyWithData data) => LineDeletion(
        filePath: data.get(#filePath, or: $value.filePath),
        ranges: data.get(#ranges, or: $value.ranges),
      );

  @override
  LineDeletionCopyWith<$R2, LineDeletion, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _LineDeletionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
