part of metadata;

/// Main metadata container for a Substrate runtime (Version 16)
///
/// V16 significantly changes from V15:
/// - Removes the `type` field (Runtime type ID)
/// - Adds deprecation information throughout
/// - Changes extrinsic structure with transaction extensions
/// - Adds associated types and view functions to pallets
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L47-L66
class RuntimeMetadataV16 extends RuntimeMetadata {
  /// List of all registered types
  final List<PortableType> types;

  /// List of all pallets (modules) in the runtime
  final List<PalletMetadataV16> pallets;

  /// Metadata about the extrinsic format used by the runtime
  final ExtrinsicMetadataV16 extrinsic;

  /// List of runtime APIs exposed by the runtime
  final List<RuntimeApiMetadataV16> apis;

  /// Outer enum type IDs (same structure as V15)
  final OuterEnumsV16 outerEnums;

  /// Custom metadata fields (same structure as V15)
  final CustomMetadataV16 customMetadata;

  const RuntimeMetadataV16({
    required this.types,
    required this.pallets,
    required this.extrinsic,
    required this.apis,
    required this.outerEnums,
    required this.customMetadata,
  });

  /// Codec instance for RuntimeMetadataV16
  static const $RuntimeMetadataV16 codec = $RuntimeMetadataV16._();

  @override
  int get version => 16;

  @override
  PortableType typeById(int id) {
    return types.firstWhere((type) => type.id == id);
  }

  @override
  Map<String, dynamic> toJson() => {
    'types': types.map((final PortableType value) => value.toJson()).toList(growable: false),
    'pallets': pallets.map((p) => p.toJson()).toList(),
    'extrinsic': extrinsic.toJson(),
    'apis': apis.map((a) => a.toJson()).toList(),
    'outerEnums': outerEnums.toJson(),
    'customMetadata': customMetadata.toJson(),
  };
}

/// Codec for RuntimeMetadataV16
///
/// SCALE encoding order (per frame-metadata v16.rs):
/// 1. types: PortableRegistry (Vec<PortableType>)
/// 2. pallets: Vec<PalletMetadataV16>
/// 3. extrinsic: ExtrinsicMetadataV16
/// 4. apis: Vec<RuntimeApiMetadataV16>
/// 5. outer_enums: OuterEnumsV16 (same as OuterEnumsV15)
/// 6. custom: CustomMetadataV16 (same as CustomMetadataV15)
///
/// Note: V16 removes the `type` field that was present in V15.
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L47-L66
class $RuntimeMetadataV16 with Codec<RuntimeMetadataV16> {
  const $RuntimeMetadataV16._();

  @override
  RuntimeMetadataV16 decode(Input input) {
    final types = SequenceCodec(PortableType.codec).decode(input);
    final pallets = SequenceCodec(PalletMetadataV16.codec).decode(input);
    final extrinsic = ExtrinsicMetadataV16.codec.decode(input);
    final apis = SequenceCodec(RuntimeApiMetadataV16.codec).decode(input);
    final outerEnums = OuterEnumsV15.codec.decode(input);
    final customMetadata = CustomMetadataV15.codec.decode(input);

    return RuntimeMetadataV16(
      types: types,
      pallets: pallets,
      extrinsic: extrinsic,
      apis: apis,
      outerEnums: outerEnums,
      customMetadata: customMetadata,
    );
  }

  @override
  void encodeTo(RuntimeMetadataV16 metadata, Output output) {
    SequenceCodec(PortableType.codec).encodeTo(metadata.types, output);
    SequenceCodec(PalletMetadataV16.codec).encodeTo(metadata.pallets, output);
    ExtrinsicMetadataV16.codec.encodeTo(metadata.extrinsic, output);
    SequenceCodec(RuntimeApiMetadataV16.codec).encodeTo(metadata.apis, output);
    OuterEnumsV15.codec.encodeTo(metadata.outerEnums, output);
    CustomMetadataV15.codec.encodeTo(metadata.customMetadata, output);
  }

  @override
  int sizeHint(RuntimeMetadataV16 value) {
    var size = 0;
    size += SequenceCodec(PortableType.codec).sizeHint(value.types);
    size += SequenceCodec(PalletMetadataV16.codec).sizeHint(value.pallets);
    size += ExtrinsicMetadataV16.codec.sizeHint(value.extrinsic);
    size += SequenceCodec(RuntimeApiMetadataV16.codec).sizeHint(value.apis);
    size += OuterEnumsV15.codec.sizeHint(value.outerEnums);
    size += CustomMetadataV15.codec.sizeHint(value.customMetadata);
    return size;
  }

  @override
  bool isSizeZero() => false;
}
