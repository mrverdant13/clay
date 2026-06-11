// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'line_range.dart';

class LineRangeMapper extends ClassMapperBase<LineRange> {
  LineRangeMapper._();

  static LineRangeMapper? _instance;
  static LineRangeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LineRangeMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'LineRange';

  static int _$start(LineRange v) => v.start;
  static const Field<LineRange, int> _f$start = Field('start', _$start);
  static int _$end(LineRange v) => v.end;
  static const Field<LineRange, int> _f$end = Field('end', _$end);

  @override
  final MappableFields<LineRange> fields = const {
    #start: _f$start,
    #end: _f$end,
  };

  static LineRange _instantiate(DecodingData data) {
    return LineRange(start: data.dec(_f$start), end: data.dec(_f$end));
  }

  @override
  final Function instantiate = _instantiate;

  static LineRange fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LineRange>(map);
  }

  static LineRange fromJson(String json) {
    return ensureInitialized().decodeJson<LineRange>(json);
  }
}

mixin LineRangeMappable {
  String toJson() {
    return LineRangeMapper.ensureInitialized().encodeJson<LineRange>(
      this as LineRange,
    );
  }

  Map<String, dynamic> toMap() {
    return LineRangeMapper.ensureInitialized().encodeMap<LineRange>(
      this as LineRange,
    );
  }

  LineRangeCopyWith<LineRange, LineRange, LineRange> get copyWith =>
      _LineRangeCopyWithImpl<LineRange, LineRange>(
        this as LineRange,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return LineRangeMapper.ensureInitialized().stringifyValue(
      this as LineRange,
    );
  }

  @override
  bool operator ==(Object other) {
    return LineRangeMapper.ensureInitialized().equalsValue(
      this as LineRange,
      other,
    );
  }

  @override
  int get hashCode {
    return LineRangeMapper.ensureInitialized().hashValue(this as LineRange);
  }
}

extension LineRangeValueCopy<$R, $Out> on ObjectCopyWith<$R, LineRange, $Out> {
  LineRangeCopyWith<$R, LineRange, $Out> get $asLineRange =>
      $base.as((v, t, t2) => _LineRangeCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class LineRangeCopyWith<$R, $In extends LineRange, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? start, int? end});
  LineRangeCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _LineRangeCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LineRange, $Out>
    implements LineRangeCopyWith<$R, LineRange, $Out> {
  _LineRangeCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LineRange> $mapper =
      LineRangeMapper.ensureInitialized();
  @override
  $R call({int? start, int? end}) => $apply(
        FieldCopyWithData({
          if (start != null) #start: start,
          if (end != null) #end: end,
        }),
      );
  @override
  LineRange $make(CopyWithData data) => LineRange(
        start: data.get(#start, or: $value.start),
        end: data.get(#end, or: $value.end),
      );

  @override
  LineRangeCopyWith<$R2, LineRange, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _LineRangeCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
