part of metadata;

/// Metadata about a single pallet (module) in MetadataV16
///
/// V16 significantly extends V15 with:
/// - Deprecation information for the pallet itself
/// - V16-specific calls/events/errors with EnumDeprecationInfo
/// - Associated types from Config traits
/// - View functions (read-only queries)
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L211-L252
class PalletMetadataV16 extends PalletMetadata {
  /// Optional storage metadata for this pallet (V16 version with deprecation)
  final PalletStorageMetadataV16? storageV16;

  /// Optional calls metadata (V16 version with EnumDeprecationInfo)
  final PalletCallMetadataV16? callsV16;

  /// Optional events metadata (V16 version with EnumDeprecationInfo)
  final PalletEventMetadataV16? eventV16;

  /// List of constants with V16 deprecation info
  final List<PalletConstantMetadataV16> constantsV16;

  /// Optional error metadata (V16 version with EnumDeprecationInfo)
  final PalletErrorMetadataV16? errorV16;

  /// Associated types from Config trait (NEW in V16)
  final List<PalletAssociatedTypeMetadata> associatedTypes;

  /// View functions for read-only queries (NEW in V16)
  final List<PalletViewFunctionMetadata> viewFunctions;

  /// Documentation for this pallet
  final List<String> docs;

  /// Deprecation information for this pallet (NEW in V16)
  final ItemDeprecationInfo deprecationInfo;

  PalletMetadataV16({
    required super.name,
    this.storageV16,
    this.callsV16,
    this.eventV16,
    required this.constantsV16,
    this.errorV16,
    required this.associatedTypes,
    required this.viewFunctions,
    required super.index,
    this.docs = const <String>[],
    required this.deprecationInfo,
  }) : super(
         // Provide base class compatibility by wrapping V16 types
         storage: null,
         calls: callsV16 != null ? PalletCallMetadata(type: callsV16.type) : null,
         event: eventV16 != null ? PalletEventMetadata(type: eventV16.type) : null,
         constants: constantsV16
             .map(
               (c) =>
                   PalletConstantMetadata(name: c.name, type: c.type, value: c.value, docs: c.docs),
             )
             .toList(),
         error: errorV16 != null ? PalletErrorMetadata(type: errorV16.type) : null,
       );

  /// Codec instance for PalletMetadataV16
  static const $PalletMetadataV16 codec = $PalletMetadataV16._();

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'storage': storageV16?.toJson(),
    'calls': callsV16?.toJson(),
    'event': eventV16?.toJson(),
    'constants': constantsV16.map((c) => c.toJson()).toList(),
    'error': errorV16?.toJson(),
    'associatedTypes': associatedTypes.map((a) => a.toJson()).toList(),
    'viewFunctions': viewFunctions.map((v) => v.toJson()).toList(),
    'index': index,
    'docs': docs,
    'deprecationInfo': deprecationInfo.toJson(),
  };
}

/// Codec for PalletMetadataV16
///
/// SCALE encoding order (per frame-metadata v16.rs):
/// 1. name: String
/// 2. storage: Option<PalletStorageMetadata>
/// 3. calls: Option<PalletCallMetadata>
/// 4. event: Option<PalletEventMetadata>
/// 5. constants: Vec<PalletConstantMetadata>
/// 6. error: Option<PalletErrorMetadata>
/// 7. associated_types: Vec<PalletAssociatedTypeMetadata>
/// 8. view_functions: Vec<PalletViewFunctionMetadata>
/// 9. index: u8
/// 10. docs: Vec<String>
/// 11. deprecation_info: ItemDeprecationInfo
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L211-L252
class $PalletMetadataV16 with Codec<PalletMetadataV16> {
  const $PalletMetadataV16._();

  @override
  PalletMetadataV16 decode(Input input) {
    final name = StrCodec.codec.decode(input);
    final storage = OptionCodec(PalletStorageMetadataV16.codec).decode(input);
    final calls = OptionCodec(PalletCallMetadataV16.codec).decode(input);
    final event = OptionCodec(PalletEventMetadataV16.codec).decode(input);
    final constants = SequenceCodec(PalletConstantMetadataV16.codec).decode(input);
    final error = OptionCodec(PalletErrorMetadataV16.codec).decode(input);
    final associatedTypes = SequenceCodec(PalletAssociatedTypeMetadata.codec).decode(input);
    final viewFunctions = SequenceCodec(PalletViewFunctionMetadata.codec).decode(input);
    final index = U8Codec.codec.decode(input);
    final docs = SequenceCodec(StrCodec.codec).decode(input);
    final deprecationInfo = ItemDeprecationInfo.codec.decode(input);

    return PalletMetadataV16(
      name: name,
      storageV16: storage,
      callsV16: calls,
      eventV16: event,
      constantsV16: constants,
      errorV16: error,
      associatedTypes: associatedTypes,
      viewFunctions: viewFunctions,
      index: index,
      docs: docs,
      deprecationInfo: deprecationInfo,
    );
  }

  @override
  void encodeTo(PalletMetadataV16 value, Output output) {
    StrCodec.codec.encodeTo(value.name, output);
    OptionCodec(PalletStorageMetadataV16.codec).encodeTo(value.storageV16, output);
    OptionCodec(PalletCallMetadataV16.codec).encodeTo(value.callsV16, output);
    OptionCodec(PalletEventMetadataV16.codec).encodeTo(value.eventV16, output);
    SequenceCodec(PalletConstantMetadataV16.codec).encodeTo(value.constantsV16, output);
    OptionCodec(PalletErrorMetadataV16.codec).encodeTo(value.errorV16, output);
    SequenceCodec(PalletAssociatedTypeMetadata.codec).encodeTo(value.associatedTypes, output);
    SequenceCodec(PalletViewFunctionMetadata.codec).encodeTo(value.viewFunctions, output);
    U8Codec.codec.encodeTo(value.index, output);
    SequenceCodec(StrCodec.codec).encodeTo(value.docs, output);
    ItemDeprecationInfo.codec.encodeTo(value.deprecationInfo, output);
  }

  @override
  int sizeHint(PalletMetadataV16 value) {
    var size = 0;
    size += StrCodec.codec.sizeHint(value.name);
    size += OptionCodec(PalletStorageMetadataV16.codec).sizeHint(value.storageV16);
    size += OptionCodec(PalletCallMetadataV16.codec).sizeHint(value.callsV16);
    size += OptionCodec(PalletEventMetadataV16.codec).sizeHint(value.eventV16);
    size += SequenceCodec(PalletConstantMetadataV16.codec).sizeHint(value.constantsV16);
    size += OptionCodec(PalletErrorMetadataV16.codec).sizeHint(value.errorV16);
    size += SequenceCodec(PalletAssociatedTypeMetadata.codec).sizeHint(value.associatedTypes);
    size += SequenceCodec(PalletViewFunctionMetadata.codec).sizeHint(value.viewFunctions);
    size += U8Codec.codec.sizeHint(value.index);
    size += SequenceCodec(StrCodec.codec).sizeHint(value.docs);
    size += ItemDeprecationInfo.codec.sizeHint(value.deprecationInfo);
    return size;
  }

  @override
  bool isSizeZero() => false;
}
