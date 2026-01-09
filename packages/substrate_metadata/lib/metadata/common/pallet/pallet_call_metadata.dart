part of metadata;

/// Metadata about callable functions in a pallet
///
/// References an enum type in the type registry that contains all
/// dispatchable functions (calls) available in this pallet.
class PalletCallMetadata {
  /// Type ID referencing the enum of all calls in this pallet
  ///
  /// Points to a TypeDefVariant in the PortableRegistry where each
  /// variant represents a callable function with its parameters.
  final int type;
  const PalletCallMetadata({required this.type});

  /// Codec instance for PalletCallMetadata
  static const $PalletCallMetadata codec = $PalletCallMetadata._();

  Map<String, dynamic> toJson() => {'type': type};
}

/// Codec for PalletCallMetadata
class $PalletCallMetadata with Codec<PalletCallMetadata> {
  const $PalletCallMetadata._();

  @override
  PalletCallMetadata decode(Input input) {
    final type = CompactCodec.codec.decode(input);
    return PalletCallMetadata(type: type);
  }

  @override
  void encodeTo(PalletCallMetadata value, Output output) {
    CompactCodec.codec.encodeTo(value.type, output);
  }

  @override
  int sizeHint(PalletCallMetadata value) {
    return CompactCodec.codec.sizeHint(value.type);
  }

  @override
  bool isSizeZero() => CompactCodec.codec.isSizeZero();
}
