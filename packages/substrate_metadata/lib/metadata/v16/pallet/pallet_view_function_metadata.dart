part of metadata;

/// Parameter metadata for view functions (V16)
///
/// Describes a single parameter of a view function.
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L399-L408
class ViewFunctionParamMetadata {
  /// Name of the parameter
  final String name;

  /// Type ID of the parameter
  final int type;

  const ViewFunctionParamMetadata({required this.name, required this.type});

  /// Codec instance for ViewFunctionParamMetadata
  static const $ViewFunctionParamMetadata codec = $ViewFunctionParamMetadata._();

  Map<String, dynamic> toJson() => {'name': name, 'type': type};
}

/// Codec for ViewFunctionParamMetadata
class $ViewFunctionParamMetadata with Codec<ViewFunctionParamMetadata> {
  const $ViewFunctionParamMetadata._();

  @override
  ViewFunctionParamMetadata decode(Input input) {
    final name = StrCodec.codec.decode(input);
    final type = CompactCodec.codec.decode(input);
    return ViewFunctionParamMetadata(name: name, type: type);
  }

  @override
  void encodeTo(ViewFunctionParamMetadata value, Output output) {
    StrCodec.codec.encodeTo(value.name, output);
    CompactCodec.codec.encodeTo(value.type, output);
  }

  @override
  int sizeHint(ViewFunctionParamMetadata value) {
    return StrCodec.codec.sizeHint(value.name) + CompactCodec.codec.sizeHint(value.type);
  }

  @override
  bool isSizeZero() => false;
}

/// Metadata about a pallet's view function (V16)
///
/// View functions are read-only queries that can be executed without
/// submitting a transaction. They provide a way to query pallet state
/// with typed inputs and outputs.
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L409-L430
class PalletViewFunctionMetadata {
  /// Unique identifier for this view function (32 bytes)
  final Uint8List id;

  /// Name of the view function
  final String name;

  /// Input parameters for this view function
  final List<ViewFunctionParamMetadata> inputs;

  /// Type ID of the return value
  final int output;

  /// Documentation for this view function
  final List<String> docs;

  /// Deprecation information for this view function
  final ItemDeprecationInfo deprecationInfo;

  const PalletViewFunctionMetadata({
    required this.id,
    required this.name,
    required this.inputs,
    required this.output,
    this.docs = const [],
    required this.deprecationInfo,
  });

  /// Codec instance for PalletViewFunctionMetadata
  static const $PalletViewFunctionMetadata codec = $PalletViewFunctionMetadata._();

  Map<String, dynamic> toJson() => {
    'id': encodeHex(id),
    'name': name,
    'inputs': inputs.map((i) => i.toJson()).toList(),
    'output': output,
    'docs': docs,
    'deprecationInfo': deprecationInfo.toJson(),
  };
}

/// Codec for PalletViewFunctionMetadata
///
/// SCALE encoding order:
/// 1. id: [u8; 32] (fixed 32 bytes)
/// 2. name: String
/// 3. inputs: Vec<ViewFunctionParamMetadata>
/// 4. output: Compact<u32>
/// 5. docs: Vec<String>
/// 6. deprecation_info: ItemDeprecationInfo
class $PalletViewFunctionMetadata with Codec<PalletViewFunctionMetadata> {
  const $PalletViewFunctionMetadata._();

  @override
  PalletViewFunctionMetadata decode(Input input) {
    // Decode 32-byte ID as fixed array
    final id = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      id[i] = U8Codec.codec.decode(input);
    }
    final name = StrCodec.codec.decode(input);
    final inputs = SequenceCodec(ViewFunctionParamMetadata.codec).decode(input);
    final output = CompactCodec.codec.decode(input);
    final docs = SequenceCodec(StrCodec.codec).decode(input);
    final deprecationInfo = ItemDeprecationInfo.codec.decode(input);

    return PalletViewFunctionMetadata(
      id: id,
      name: name,
      inputs: inputs,
      output: output,
      docs: docs,
      deprecationInfo: deprecationInfo,
    );
  }

  @override
  void encodeTo(PalletViewFunctionMetadata value, Output output) {
    // Encode 32-byte ID as fixed array
    for (var i = 0; i < 32; i++) {
      U8Codec.codec.encodeTo(value.id[i], output);
    }
    StrCodec.codec.encodeTo(value.name, output);
    SequenceCodec(ViewFunctionParamMetadata.codec).encodeTo(value.inputs, output);
    CompactCodec.codec.encodeTo(value.output, output);
    SequenceCodec(StrCodec.codec).encodeTo(value.docs, output);
    ItemDeprecationInfo.codec.encodeTo(value.deprecationInfo, output);
  }

  @override
  int sizeHint(PalletViewFunctionMetadata value) {
    var size = 32; // Fixed 32-byte ID
    size += StrCodec.codec.sizeHint(value.name);
    size += SequenceCodec(ViewFunctionParamMetadata.codec).sizeHint(value.inputs);
    size += CompactCodec.codec.sizeHint(value.output);
    size += SequenceCodec(StrCodec.codec).sizeHint(value.docs);
    size += ItemDeprecationInfo.codec.sizeHint(value.deprecationInfo);
    return size;
  }

  @override
  bool isSizeZero() => false;
}
