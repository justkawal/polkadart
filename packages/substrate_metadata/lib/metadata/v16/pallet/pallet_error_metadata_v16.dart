part of metadata;

/// Metadata about errors in a pallet (V16)
///
/// V16 extends the base PalletErrorMetadata by adding deprecation information
/// for individual error variants. This allows runtime developers to mark
/// specific errors as deprecated while maintaining backward compatibility.
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L289-L306
class PalletErrorMetadataV16 extends PalletErrorMetadata {
  /// Deprecation information for error variants
  ///
  /// Maps variant indices to their deprecation status. Variants not in
  /// the map are implicitly not deprecated.
  final EnumDeprecationInfo deprecationInfo;

  const PalletErrorMetadataV16({required super.type, required this.deprecationInfo});

  /// Codec instance for PalletErrorMetadataV16
  static const $PalletErrorMetadataV16 codec = $PalletErrorMetadataV16._();

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'deprecationInfo': deprecationInfo.toJson()};
}

/// Codec for PalletErrorMetadataV16
///
/// SCALE encoding order:
/// 1. type: Compact<u32> (from base class)
/// 2. deprecation_info: EnumDeprecationInfo (BTreeMap<u8, VariantDeprecationInfo>)
class $PalletErrorMetadataV16 with Codec<PalletErrorMetadataV16> {
  const $PalletErrorMetadataV16._();

  @override
  PalletErrorMetadataV16 decode(Input input) {
    final type = CompactCodec.codec.decode(input);
    final deprecationInfo = EnumDeprecationInfo.codec.decode(input);
    return PalletErrorMetadataV16(type: type, deprecationInfo: deprecationInfo);
  }

  @override
  void encodeTo(PalletErrorMetadataV16 value, Output output) {
    CompactCodec.codec.encodeTo(value.type, output);
    EnumDeprecationInfo.codec.encodeTo(value.deprecationInfo, output);
  }

  @override
  int sizeHint(PalletErrorMetadataV16 value) {
    return CompactCodec.codec.sizeHint(value.type) +
        EnumDeprecationInfo.codec.sizeHint(value.deprecationInfo);
  }

  @override
  bool isSizeZero() => false;
}
