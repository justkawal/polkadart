part of metadata;

/// Metadata of the extrinsic used by the runtime (Version 16)
///
/// V16 extends ExtrinsicMetadata with significant changes:
/// - versions: Vec<u8> instead of single version
/// - Replaces signedExtensions with transactionExtensions
/// - Adds transactionExtensionsByVersion mapping
/// - extraType and signedExtensions are not used (return -1 and [] respectively)
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L147-L180
class ExtrinsicMetadataV16 extends ExtrinsicMetadata {
  /// Supported extrinsic versions
  final List<int> versions;

  /// Mapping from extrinsic version to active transaction extension indices
  ///
  /// For each supported version, lists the indices into transactionExtensions
  /// that are active for that version.
  final Map<int, List<int>> transactionExtensionsByVersion;

  /// List of all transaction extensions
  final List<TransactionExtensionMetadata> transactionExtensions;

  const ExtrinsicMetadataV16({
    required this.versions,
    required super.addressType,
    required super.callType,
    required super.signatureType,
    required this.transactionExtensionsByVersion,
    required this.transactionExtensions,
  }) : super(
         version: 0, // Will be overridden by getter
         extraType: -1, // Not used in V16
         signedExtensions: const [], // Not used in V16, use transactionExtensions
       );

  /// Codec instance for ExtrinsicMetadataV16
  static const $ExtrinsicMetadataV16 codec = $ExtrinsicMetadataV16._();

  /// Get the primary/default version (first in the list)
  @override
  int get version => versions.isNotEmpty ? versions.first : 0;

  /// Get transaction extensions for a specific version
  ///
  /// Falls back to version 0 if the specific version is not found.
  /// Version 0 acts as a default/fallback for all extrinsic versions.
  List<TransactionExtensionMetadata> extensionsForVersion(final int ver) {
    List<int>? indices = transactionExtensionsByVersion[ver];

    // Fallback to version 0 if the specific version is not found
    // Version 0 appears to be used as a default in Polkadot metadata
    if (indices == null && ver != 0) {
      indices = transactionExtensionsByVersion[0];
    }
    if (indices == null) return [];
    return indices
        .where((i) => i < transactionExtensions.length)
        .map((i) => transactionExtensions[i])
        .toList();
  }

  @override
  Map<String, dynamic> toJson() => {
    'versions': versions,
    'addressType': addressType,
    'callType': callType,
    'signatureType': signatureType,
    'transactionExtensionsByVersion': transactionExtensionsByVersion.map(
      (k, v) => MapEntry(k.toString(), v),
    ),
    'transactionExtensions': transactionExtensions.map((e) => e.toJson()).toList(),
  };
}

/// Codec for ExtrinsicMetadataV16
///
/// SCALE encoding order (per frame-metadata v16.rs):
/// 1. versions: Vec<u8>
/// 2. address_ty: Compact<u32>
/// 3. call_ty: Compact<u32>
/// 4. signature_ty: Compact<u32>
/// 5. transaction_extensions_by_version: BTreeMap<u8, Vec<Compact<u32>>>
/// 6. transaction_extensions: Vec<TransactionExtensionMetadata>
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L147-L180
class $ExtrinsicMetadataV16 with Codec<ExtrinsicMetadataV16> {
  const $ExtrinsicMetadataV16._();

  @override
  ExtrinsicMetadataV16 decode(Input input) {
    // Decode versions as Vec<u8>
    final versions = SequenceCodec(U8Codec.codec).decode(input);

    final addressType = CompactCodec.codec.decode(input);
    final callType = CompactCodec.codec.decode(input);
    final signatureType = CompactCodec.codec.decode(input);

    // Decode BTreeMap<u8, Vec<Compact<u32>>>
    final mapLength = CompactCodec.codec.decode(input);
    final transactionExtensionsByVersion = <int, List<int>>{};
    for (var i = 0; i < mapLength; i++) {
      final key = U8Codec.codec.decode(input);
      final valueLength = CompactCodec.codec.decode(input);
      final value = <int>[];
      for (var j = 0; j < valueLength; j++) {
        value.add(CompactCodec.codec.decode(input));
      }
      transactionExtensionsByVersion[key] = value;
    }

    final transactionExtensions = SequenceCodec(TransactionExtensionMetadata.codec).decode(input);

    return ExtrinsicMetadataV16(
      versions: versions,
      addressType: addressType,
      callType: callType,
      signatureType: signatureType,
      transactionExtensionsByVersion: transactionExtensionsByVersion,
      transactionExtensions: transactionExtensions,
    );
  }

  @override
  void encodeTo(ExtrinsicMetadataV16 value, Output output) {
    // Encode versions as Vec<u8>
    SequenceCodec(U8Codec.codec).encodeTo(value.versions, output);

    CompactCodec.codec.encodeTo(value.addressType, output);
    CompactCodec.codec.encodeTo(value.callType, output);
    CompactCodec.codec.encodeTo(value.signatureType, output);

    // Encode BTreeMap<u8, Vec<Compact<u32>>>
    final entries = value.transactionExtensionsByVersion.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    CompactCodec.codec.encodeTo(entries.length, output);
    for (final entry in entries) {
      U8Codec.codec.encodeTo(entry.key, output);
      CompactCodec.codec.encodeTo(entry.value.length, output);
      for (final v in entry.value) {
        CompactCodec.codec.encodeTo(v, output);
      }
    }

    SequenceCodec(TransactionExtensionMetadata.codec).encodeTo(value.transactionExtensions, output);
  }

  @override
  int sizeHint(ExtrinsicMetadataV16 value) {
    var size = 0;
    size += SequenceCodec(U8Codec.codec).sizeHint(value.versions);
    size += CompactCodec.codec.sizeHint(value.addressType);
    size += CompactCodec.codec.sizeHint(value.callType);
    size += CompactCodec.codec.sizeHint(value.signatureType);

    // BTreeMap size hint
    size += CompactCodec.codec.sizeHint(value.transactionExtensionsByVersion.length);
    for (final entry in value.transactionExtensionsByVersion.entries) {
      size += 1; // u8 key
      size += CompactCodec.codec.sizeHint(entry.value.length);
      for (final v in entry.value) {
        size += CompactCodec.codec.sizeHint(v);
      }
    }

    size += SequenceCodec(TransactionExtensionMetadata.codec).sizeHint(value.transactionExtensions);
    return size;
  }

  @override
  bool isSizeZero() => false;
}
