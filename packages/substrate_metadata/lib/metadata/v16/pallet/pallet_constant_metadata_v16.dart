part of metadata;

/// Pallet constant metadata for V16, including deprecation information.
///
/// V16 extends the base PalletConstantMetadata with ItemDeprecationInfo to allow
/// runtime developers to mark constants as deprecated while maintaining
/// backward compatibility. Constants are compile-time values configured in
/// the runtime that cannot be changed without a runtime upgrade.
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L343-L362
class PalletConstantMetadataV16 extends PalletConstantMetadata {
  /// Deprecation information for this constant.
  ///
  /// Indicates whether this constant is deprecated and provides
  /// optional notes and version information about the deprecation.
  final ItemDeprecationInfo deprecationInfo;

  const PalletConstantMetadataV16({
    required super.name,
    required super.type,
    required super.value,
    required super.docs,
    required this.deprecationInfo,
  });

  /// Codec instance for PalletConstantMetadataV16
  static const $PalletConstantMetadataV16 codec = $PalletConstantMetadataV16._();

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'deprecationInfo': deprecationInfo.toJson()};
}

/// Codec for PalletConstantMetadataV16
///
/// SCALE encoding order:
/// 1. All base PalletConstantMetadata fields (name, type, value, docs)
/// 2. ItemDeprecationInfo (enum variant)
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L343-L362
class $PalletConstantMetadataV16 with Codec<PalletConstantMetadataV16> {
  const $PalletConstantMetadataV16._();

  @override
  PalletConstantMetadataV16 decode(Input input) {
    // Decode all base fields first
    final base = PalletConstantMetadata.codec.decode(input);

    // Decode deprecation info (NEW in V16)
    final deprecationInfo = ItemDeprecationInfo.codec.decode(input);

    return PalletConstantMetadataV16(
      name: base.name,
      type: base.type,
      value: base.value,
      docs: base.docs,
      deprecationInfo: deprecationInfo,
    );
  }

  @override
  void encodeTo(PalletConstantMetadataV16 value, Output output) {
    // Encode all base fields first
    PalletConstantMetadata.codec.encodeTo(value, output);

    // Encode deprecation info (NEW in V16)
    ItemDeprecationInfo.codec.encodeTo(value.deprecationInfo, output);
  }

  @override
  int sizeHint(PalletConstantMetadataV16 value) {
    return PalletConstantMetadata.codec.sizeHint(value) +
        ItemDeprecationInfo.codec.sizeHint(value.deprecationInfo);
  }

  @override
  bool isSizeZero() => false;
}
