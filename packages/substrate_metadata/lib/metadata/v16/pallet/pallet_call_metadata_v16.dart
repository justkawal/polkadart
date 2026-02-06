part of metadata;

/// Metadata about callable functions in a pallet (V16)
///
/// V16 extends the base PalletCallMetadata by adding deprecation information
/// for individual call variants. This allows runtime developers to mark
/// specific extrinsic calls as deprecated while maintaining backward compatibility.
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L253-L270
class PalletCallMetadataV16 extends PalletCallMetadata {
  /// Deprecation information for call variants
  ///
  /// Maps variant indices to their deprecation status. Variants not in
  /// the map are implicitly not deprecated.
  final EnumDeprecationInfo deprecationInfo;

  const PalletCallMetadataV16({required super.type, required this.deprecationInfo});

  /// Codec instance for PalletCallMetadataV16
  static const $PalletCallMetadataV16 codec = $PalletCallMetadataV16._();

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'deprecationInfo': deprecationInfo.toJson()};
}

/// Codec for PalletCallMetadataV16
///
/// SCALE encoding order:
/// 1. type: Compact<u32> (from base class)
/// 2. deprecation_info: EnumDeprecationInfo (BTreeMap<u8, VariantDeprecationInfo>)
class $PalletCallMetadataV16 with Codec<PalletCallMetadataV16> {
  const $PalletCallMetadataV16._();

  @override
  PalletCallMetadataV16 decode(Input input) {
    final type = CompactCodec.codec.decode(input);
    final deprecationInfo = EnumDeprecationInfo.codec.decode(input);
    return PalletCallMetadataV16(type: type, deprecationInfo: deprecationInfo);
  }

  @override
  void encodeTo(PalletCallMetadataV16 value, Output output) {
    CompactCodec.codec.encodeTo(value.type, output);
    EnumDeprecationInfo.codec.encodeTo(value.deprecationInfo, output);
  }

  @override
  int sizeHint(PalletCallMetadataV16 value) {
    return CompactCodec.codec.sizeHint(value.type) +
        EnumDeprecationInfo.codec.sizeHint(value.deprecationInfo);
  }

  @override
  bool isSizeZero() => false;
}
