part of metadata;

/// Metadata about a transaction extension (V16)
///
/// Transaction extensions replace signed extensions in V16.
/// They provide a more flexible mechanism for extending extrinsic functionality.
/// Each extension can contribute both explicit data (included in the extrinsic)
/// and implicit data (derived and included in the signed payload).
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L181-L196
class TransactionExtensionMetadata {
  /// Identifier for this extension
  final String identifier;

  /// Type ID of the extension data (included in extrinsic)
  final int type;

  /// Type ID of the implicit data (derived, included in signed payload)
  final int implicit;

  const TransactionExtensionMetadata({
    required this.identifier,
    required this.type,
    required this.implicit,
  });

  /// Codec instance for TransactionExtensionMetadata
  static const $TransactionExtensionMetadata codec = $TransactionExtensionMetadata._();

  Map<String, dynamic> toJson() => {'identifier': identifier, 'type': type, 'implicit': implicit};
}

/// Codec for TransactionExtensionMetadata
///
/// SCALE encoding order:
/// 1. identifier: String
/// 2. type: Compact<u32>
/// 3. implicit: Compact<u32>
class $TransactionExtensionMetadata with Codec<TransactionExtensionMetadata> {
  const $TransactionExtensionMetadata._();

  @override
  TransactionExtensionMetadata decode(Input input) {
    final identifier = StrCodec.codec.decode(input);
    final type = CompactCodec.codec.decode(input);
    final implicit = CompactCodec.codec.decode(input);

    return TransactionExtensionMetadata(identifier: identifier, type: type, implicit: implicit);
  }

  @override
  void encodeTo(TransactionExtensionMetadata value, Output output) {
    StrCodec.codec.encodeTo(value.identifier, output);
    CompactCodec.codec.encodeTo(value.type, output);
    CompactCodec.codec.encodeTo(value.implicit, output);
  }

  @override
  int sizeHint(TransactionExtensionMetadata value) {
    return StrCodec.codec.sizeHint(value.identifier) +
        CompactCodec.codec.sizeHint(value.type) +
        CompactCodec.codec.sizeHint(value.implicit);
  }

  @override
  bool isSizeZero() => false;
}
