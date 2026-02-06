part of metadata;

/// Storage entry metadata for V16, including deprecation information.
///
/// V16 extends the base StorageEntryMetadata with ItemDeprecationInfo to allow
/// runtime developers to mark storage entries as deprecated while maintaining
/// backward compatibility.
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L293-L322
class StorageEntryMetadataV16 extends StorageEntryMetadata {
  /// Deprecation information for this storage entry.
  ///
  /// Indicates whether this storage entry is deprecated and provides
  /// optional notes and version information about the deprecation.
  final ItemDeprecationInfo deprecationInfo;

  const StorageEntryMetadataV16({
    required super.name,
    required super.modifier,
    required super.type,
    required super.defaultValue,
    required super.docs,
    required this.deprecationInfo,
  });

  /// Codec instance for StorageEntryMetadataV16
  static const $StorageEntryMetadataV16 codec = $StorageEntryMetadataV16._();

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'deprecationInfo': deprecationInfo.toJson()};
}

/// Codec for StorageEntryMetadataV16
///
/// SCALE encoding order:
/// 1. All base StorageEntryMetadata fields (name, modifier, type, defaultValue, docs)
/// 2. ItemDeprecationInfo (enum variant)
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L293-L322
class $StorageEntryMetadataV16 with Codec<StorageEntryMetadataV16> {
  const $StorageEntryMetadataV16._();

  @override
  StorageEntryMetadataV16 decode(Input input) {
    // Decode all base fields first
    final base = StorageEntryMetadata.codec.decode(input);

    // Decode deprecation info (NEW in V16)
    final deprecationInfo = ItemDeprecationInfo.codec.decode(input);

    return StorageEntryMetadataV16(
      name: base.name,
      modifier: base.modifier,
      type: base.type,
      defaultValue: base.defaultValue,
      docs: base.docs,
      deprecationInfo: deprecationInfo,
    );
  }

  @override
  void encodeTo(StorageEntryMetadataV16 value, Output output) {
    // Encode all base fields first
    StorageEntryMetadata.codec.encodeTo(value, output);

    // Encode deprecation info (NEW in V16)
    ItemDeprecationInfo.codec.encodeTo(value.deprecationInfo, output);
  }

  @override
  int sizeHint(StorageEntryMetadataV16 value) {
    return StorageEntryMetadata.codec.sizeHint(value) +
        ItemDeprecationInfo.codec.sizeHint(value.deprecationInfo);
  }

  @override
  bool isSizeZero() => false;
}
