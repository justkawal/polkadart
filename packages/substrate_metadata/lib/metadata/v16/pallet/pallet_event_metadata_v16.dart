part of metadata;

/// Metadata about events in a pallet (V16)
///
/// V16 extends the base PalletEventMetadata by adding deprecation information
/// for individual event variants. This allows runtime developers to mark
/// specific events as deprecated while maintaining backward compatibility.
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L271-L288
class PalletEventMetadataV16 extends PalletEventMetadata {
  /// Deprecation information for event variants
  ///
  /// Maps variant indices to their deprecation status. Variants not in
  /// the map are implicitly not deprecated.
  final EnumDeprecationInfo deprecationInfo;

  const PalletEventMetadataV16({required super.type, required this.deprecationInfo});

  /// Codec instance for PalletEventMetadataV16
  static const $PalletEventMetadataV16 codec = $PalletEventMetadataV16._();

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'deprecationInfo': deprecationInfo.toJson()};
}

/// Codec for PalletEventMetadataV16
///
/// SCALE encoding order:
/// 1. type: Compact<u32> (from base class)
/// 2. deprecation_info: EnumDeprecationInfo (BTreeMap<u8, VariantDeprecationInfo>)
class $PalletEventMetadataV16 with Codec<PalletEventMetadataV16> {
  const $PalletEventMetadataV16._();

  @override
  PalletEventMetadataV16 decode(Input input) {
    final type = CompactCodec.codec.decode(input);
    final deprecationInfo = EnumDeprecationInfo.codec.decode(input);
    return PalletEventMetadataV16(type: type, deprecationInfo: deprecationInfo);
  }

  @override
  void encodeTo(PalletEventMetadataV16 value, Output output) {
    CompactCodec.codec.encodeTo(value.type, output);
    EnumDeprecationInfo.codec.encodeTo(value.deprecationInfo, output);
  }

  @override
  int sizeHint(PalletEventMetadataV16 value) {
    return CompactCodec.codec.sizeHint(value.type) +
        EnumDeprecationInfo.codec.sizeHint(value.deprecationInfo);
  }

  @override
  bool isSizeZero() => false;
}
