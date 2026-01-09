part of metadata;

/// Pallet storage metadata for V16
///
/// Contains storage entries with V16-specific deprecation information.
/// The structure is similar to base PalletStorageMetadata but uses
/// StorageEntryMetadataV16 which includes deprecation info per entry.
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L307-L322
class PalletStorageMetadataV16 {
  /// Prefix used for all storage items in this pallet
  final String prefix;

  /// List of storage entries in this pallet (V16 with deprecation info)
  final List<StorageEntryMetadataV16> entries;

  const PalletStorageMetadataV16({required this.prefix, required this.entries});

  /// Codec instance for PalletStorageMetadataV16
  static const $PalletStorageMetadataV16 codec = $PalletStorageMetadataV16._();

  Map<String, dynamic> toJson() => {
    'prefix': prefix,
    'entries': entries.map((e) => e.toJson()).toList(),
  };
}

/// Codec for PalletStorageMetadataV16
///
/// SCALE encoding order:
/// 1. prefix: String
/// 2. entries: Vec<StorageEntryMetadataV16>
class $PalletStorageMetadataV16 with Codec<PalletStorageMetadataV16> {
  const $PalletStorageMetadataV16._();

  @override
  PalletStorageMetadataV16 decode(Input input) {
    final prefix = StrCodec.codec.decode(input);
    final entries = SequenceCodec(StorageEntryMetadataV16.codec).decode(input);
    return PalletStorageMetadataV16(prefix: prefix, entries: entries);
  }

  @override
  void encodeTo(PalletStorageMetadataV16 value, Output output) {
    StrCodec.codec.encodeTo(value.prefix, output);
    SequenceCodec(StorageEntryMetadataV16.codec).encodeTo(value.entries, output);
  }

  @override
  int sizeHint(PalletStorageMetadataV16 value) {
    return StrCodec.codec.sizeHint(value.prefix) +
        SequenceCodec(StorageEntryMetadataV16.codec).sizeHint(value.entries);
  }

  @override
  bool isSizeZero() => false;
}
