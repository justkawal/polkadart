part of metadata;

/// Metadata about a pallet's associated type (V16)
///
/// Associated types from Config traits exposed in the metadata.
/// This is new in V16 and allows tooling to understand the concrete
/// types used for pallet configuration.
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L383-L398
class PalletAssociatedTypeMetadata {
  /// Name of the associated type
  final String name;

  /// Type ID of the associated type
  final int type;

  /// Documentation for this associated type
  final List<String> docs;

  const PalletAssociatedTypeMetadata({
    required this.name,
    required this.type,
    this.docs = const [],
  });

  /// Codec instance for PalletAssociatedTypeMetadata
  static const $PalletAssociatedTypeMetadata codec = $PalletAssociatedTypeMetadata._();

  Map<String, dynamic> toJson() => {'name': name, 'type': type, 'docs': docs};
}

/// Codec for PalletAssociatedTypeMetadata
///
/// SCALE encoding order:
/// 1. name: String
/// 2. type: Compact<u32>
/// 3. docs: Vec<String>
class $PalletAssociatedTypeMetadata with Codec<PalletAssociatedTypeMetadata> {
  const $PalletAssociatedTypeMetadata._();

  @override
  PalletAssociatedTypeMetadata decode(Input input) {
    final name = StrCodec.codec.decode(input);
    final type = CompactCodec.codec.decode(input);
    final docs = SequenceCodec(StrCodec.codec).decode(input);
    return PalletAssociatedTypeMetadata(name: name, type: type, docs: docs);
  }

  @override
  void encodeTo(PalletAssociatedTypeMetadata value, Output output) {
    StrCodec.codec.encodeTo(value.name, output);
    CompactCodec.codec.encodeTo(value.type, output);
    SequenceCodec(StrCodec.codec).encodeTo(value.docs, output);
  }

  @override
  int sizeHint(PalletAssociatedTypeMetadata value) {
    return StrCodec.codec.sizeHint(value.name) +
        CompactCodec.codec.sizeHint(value.type) +
        SequenceCodec(StrCodec.codec).sizeHint(value.docs);
  }

  @override
  bool isSizeZero() => false;
}
