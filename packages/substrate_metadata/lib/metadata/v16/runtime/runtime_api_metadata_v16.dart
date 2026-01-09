part of metadata;

/// Metadata about a runtime API method (V16)
///
/// Describes a single method within a runtime API.
/// V16 adds deprecation information to track deprecated methods.
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L117-L146
class RuntimeApiMethodMetadataV16 {
  /// Name of the method
  final String name;

  /// Input parameters for this method
  ///
  /// Reuses V15 parameter metadata as the structure is identical
  final List<RuntimeApiMethodParamMetadataV15> inputs;

  /// Type ID of the return value
  final int output;

  /// Documentation for this method
  final List<String> docs;

  /// Deprecation information for this method (NEW in V16)
  final ItemDeprecationInfo deprecationInfo;

  const RuntimeApiMethodMetadataV16({
    required this.name,
    required this.inputs,
    required this.output,
    this.docs = const [],
    required this.deprecationInfo,
  });

  /// Codec instance for RuntimeApiMethodMetadataV16
  static const $RuntimeApiMethodMetadataV16 codec = $RuntimeApiMethodMetadataV16._();

  Map<String, dynamic> toJson() => {
    'name': name,
    'inputs': inputs.map((i) => i.toJson()).toList(),
    'output': output,
    'docs': docs,
    'deprecationInfo': deprecationInfo.toJson(),
  };
}

/// Codec for RuntimeApiMethodMetadataV16
///
/// SCALE encoding order:
/// 1. name: String
/// 2. inputs: Vec<RuntimeApiMethodParamMetadata>
/// 3. output: Compact<u32>
/// 4. docs: Vec<String>
/// 5. deprecation_info: ItemDeprecationInfo
class $RuntimeApiMethodMetadataV16 with Codec<RuntimeApiMethodMetadataV16> {
  const $RuntimeApiMethodMetadataV16._();

  @override
  RuntimeApiMethodMetadataV16 decode(Input input) {
    final name = StrCodec.codec.decode(input);
    final inputs = SequenceCodec(RuntimeApiMethodParamMetadataV15.codec).decode(input);
    final output = CompactCodec.codec.decode(input);
    final docs = SequenceCodec(StrCodec.codec).decode(input);
    final deprecationInfo = ItemDeprecationInfo.codec.decode(input);

    return RuntimeApiMethodMetadataV16(
      name: name,
      inputs: inputs,
      output: output,
      docs: docs,
      deprecationInfo: deprecationInfo,
    );
  }

  @override
  void encodeTo(RuntimeApiMethodMetadataV16 value, Output output) {
    StrCodec.codec.encodeTo(value.name, output);
    SequenceCodec(RuntimeApiMethodParamMetadataV15.codec).encodeTo(value.inputs, output);
    CompactCodec.codec.encodeTo(value.output, output);
    SequenceCodec(StrCodec.codec).encodeTo(value.docs, output);
    ItemDeprecationInfo.codec.encodeTo(value.deprecationInfo, output);
  }

  @override
  int sizeHint(RuntimeApiMethodMetadataV16 value) {
    return StrCodec.codec.sizeHint(value.name) +
        SequenceCodec(RuntimeApiMethodParamMetadataV15.codec).sizeHint(value.inputs) +
        CompactCodec.codec.sizeHint(value.output) +
        SequenceCodec(StrCodec.codec).sizeHint(value.docs) +
        ItemDeprecationInfo.codec.sizeHint(value.deprecationInfo);
  }

  @override
  bool isSizeZero() => false;
}

/// Metadata about a runtime API (V16)
///
/// Runtime APIs are interfaces exposed by the runtime that can be called
/// via the state_call RPC method. They provide versioned access to runtime
/// functionality.
///
/// V16 adds:
/// - version field for API versioning
/// - deprecation information to track deprecated APIs
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L87-L116
class RuntimeApiMetadataV16 {
  /// Name of the runtime API
  ///
  /// Examples: "Core", "Metadata", "BlockBuilder", "TaggedTransactionQueue"
  final String name;

  /// List of methods in this API
  final List<RuntimeApiMethodMetadataV16> methods;

  /// Documentation for this API
  final List<String> docs;

  /// Version of this runtime API (NEW in V16)
  final int version;

  /// Deprecation information for this API (NEW in V16)
  final ItemDeprecationInfo deprecationInfo;

  const RuntimeApiMetadataV16({
    required this.name,
    required this.methods,
    this.docs = const [],
    required this.version,
    required this.deprecationInfo,
  });

  /// Codec instance for RuntimeApiMetadataV16
  static const $RuntimeApiMetadataV16 codec = $RuntimeApiMetadataV16._();

  Map<String, dynamic> toJson() => {
    'name': name,
    'methods': methods.map((m) => m.toJson()).toList(),
    'docs': docs,
    'version': version,
    'deprecationInfo': deprecationInfo.toJson(),
  };
}

/// Codec for RuntimeApiMetadataV16
///
/// SCALE encoding order (per frame-metadata v16.rs):
/// 1. name: String
/// 2. methods: Vec<RuntimeApiMethodMetadata>
/// 3. docs: Vec<String>
/// 4. version: Compact<u32>
/// 5. deprecation_info: ItemDeprecationInfo
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L87-L116
class $RuntimeApiMetadataV16 with Codec<RuntimeApiMetadataV16> {
  const $RuntimeApiMetadataV16._();

  @override
  RuntimeApiMetadataV16 decode(Input input) {
    final name = StrCodec.codec.decode(input);
    final methods = SequenceCodec(RuntimeApiMethodMetadataV16.codec).decode(input);
    final docs = SequenceCodec(StrCodec.codec).decode(input);
    final version = CompactCodec.codec.decode(input);
    final deprecationInfo = ItemDeprecationInfo.codec.decode(input);

    return RuntimeApiMetadataV16(
      name: name,
      methods: methods,
      docs: docs,
      version: version,
      deprecationInfo: deprecationInfo,
    );
  }

  @override
  void encodeTo(RuntimeApiMetadataV16 value, Output output) {
    StrCodec.codec.encodeTo(value.name, output);
    SequenceCodec(RuntimeApiMethodMetadataV16.codec).encodeTo(value.methods, output);
    SequenceCodec(StrCodec.codec).encodeTo(value.docs, output);
    CompactCodec.codec.encodeTo(value.version, output);
    ItemDeprecationInfo.codec.encodeTo(value.deprecationInfo, output);
  }

  @override
  int sizeHint(RuntimeApiMetadataV16 value) {
    return StrCodec.codec.sizeHint(value.name) +
        SequenceCodec(RuntimeApiMethodMetadataV16.codec).sizeHint(value.methods) +
        SequenceCodec(StrCodec.codec).sizeHint(value.docs) +
        CompactCodec.codec.sizeHint(value.version) +
        ItemDeprecationInfo.codec.sizeHint(value.deprecationInfo);
  }

  @override
  bool isSizeZero() => false;
}
