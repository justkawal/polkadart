part of metadata;

/// Metadata about events in a pallet
///
/// References an enum type in the type registry that contains all
/// events that can be emitted by this pallet.
class PalletEventMetadata {
  /// Type ID referencing the enum of all events in this pallet
  ///
  /// Points to a TypeDefVariant in the PortableRegistry where each
  /// variant represents an event with its data fields.
  final int type;
  const PalletEventMetadata({required this.type});

  /// Codec instance for PalletEventMetadata
  static const $PalletEventMetadata codec = $PalletEventMetadata._();

  Map<String, dynamic> toJson() => {'type': type};
}

/// Codec for PalletEventMetadata
class $PalletEventMetadata with Codec<PalletEventMetadata> {
  const $PalletEventMetadata._();

  @override
  PalletEventMetadata decode(Input input) {
    final type = CompactCodec.codec.decode(input);
    return PalletEventMetadata(type: type);
  }

  @override
  void encodeTo(PalletEventMetadata value, Output output) {
    CompactCodec.codec.encodeTo(value.type, output);
  }

  @override
  int sizeHint(PalletEventMetadata value) {
    return CompactCodec.codec.sizeHint(value.type);
  }

  @override
  bool isSizeZero() => CompactCodec.codec.isSizeZero();
}
