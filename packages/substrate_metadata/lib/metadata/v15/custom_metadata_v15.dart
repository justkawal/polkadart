part of metadata;

class CustomMetadataV15 {
  final Map<String, CustomMetadataV15Value> map;
  CustomMetadataV15({this.map = const <String, CustomMetadataV15Value>{}});

  static const $CustomMetadataV15 codec = $CustomMetadataV15._();

  Map<String, dynamic> toJson() => {'map': map.map((k, v) => MapEntry(k, v.toJson()))};
}

class $CustomMetadataV15 with Codec<CustomMetadataV15> {
  const $CustomMetadataV15._();

  @override
  CustomMetadataV15 decode(Input input) {
    final map = BTreeMapCodec(
      keyCodec: StrCodec.codec,
      valueCodec: CustomMetadataV15Value.codec,
    ).decode(input);
    return CustomMetadataV15(map: map);
  }

  @override
  void encodeTo(CustomMetadataV15 metadata, Output output) {
    BTreeMapCodec(
      keyCodec: StrCodec.codec,
      valueCodec: CustomMetadataV15Value.codec,
    ).encodeTo(metadata.map, output);
  }

  @override
  int sizeHint(CustomMetadataV15 value) {
    return BTreeMapCodec(
      keyCodec: StrCodec.codec,
      valueCodec: CustomMetadataV15Value.codec,
    ).sizeHint(value.map);
  }

  @override
  bool isSizeZero() => BTreeMapCodec(
    keyCodec: StrCodec.codec,
    valueCodec: CustomMetadataV15Value.codec,
  ).isSizeZero();
}

class CustomMetadataV15Value {
  final int type;
  final List<int> value;
  const CustomMetadataV15Value({required this.type, required this.value});

  static const $CustomMetadataV15Value codec = $CustomMetadataV15Value._();

  Map<String, dynamic> toJson() => {'type': type, 'value': value.toHexString()};
}

class $CustomMetadataV15Value with Codec<CustomMetadataV15Value> {
  const $CustomMetadataV15Value._();

  @override
  CustomMetadataV15Value decode(Input input) {
    final type = CompactCodec.codec.decode(input);
    final value = U8SequenceCodec.codec.decode(input);

    return CustomMetadataV15Value(type: type, value: value);
  }

  @override
  void encodeTo(CustomMetadataV15Value metadata, Output output) {
    CompactCodec.codec.encodeTo(metadata.type, output);
    U8SequenceCodec.codec.encodeTo(metadata.value, output);
  }

  @override
  int sizeHint(CustomMetadataV15Value value) {
    int size = CompactCodec.codec.sizeHint(value.type);
    size += U8SequenceCodec.codec.sizeHint(value.value);
    return size;
  }

  @override
  bool isSizeZero() => CompactCodec.codec.isSizeZero() && U8SequenceCodec.codec.isSizeZero();
}
