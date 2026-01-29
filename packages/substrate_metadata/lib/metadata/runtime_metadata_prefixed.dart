part of metadata;

/// Magic number prefix for metadata: 'meta' in ASCII (0x6174656d)
const int metaReserved = 0x6174656d;

/// Versioned metadata enum
///
/// Substrate uses this enum to support multiple metadata versions.
/// This allows nodes to upgrade their metadata format while maintaining
/// backward compatibility.
sealed class RuntimeMetadata {
  const RuntimeMetadata();

  /// Get the metadata version number
  int get version;
  Map<String, dynamic> toJson();
  PortableType typeById(final int id);
}

/// Wrapper for prefixed runtime metadata
///
/// This is the top-level structure returned by the `state_getMetadata` RPC call.
/// It includes a magic number and version before the actual metadata.
class RuntimeMetadataPrefixed {
  /// Magic number (should be [metaReserved]: 0x6174656d / "meta")
  final int magicNumber;

  /// The actual metadata (versioned enum)
  final RuntimeMetadata metadata;

  const RuntimeMetadataPrefixed({required this.magicNumber, required this.metadata});

  /// Codec instance for RuntimeMetadataPrefixed
  static const $RuntimeMetadataPrefixed codec = $RuntimeMetadataPrefixed._();

  factory RuntimeMetadataPrefixed.fromHex(String hexString) {
    final List<int> rawData = decodeHex(hexString);
    final input = ByteInput.fromBytes(rawData);
    return codec.decode(input);
  }

  factory RuntimeMetadataPrefixed.fromBytes(Uint8List rawData) {
    final input = ByteInput.fromBytes(rawData);
    return codec.decode(input);
  }

  MetadataTypeRegistry buildRegistry() => MetadataTypeRegistry(this);

  ChainInfo buildChainInfo() => ChainInfo.fromRuntimeMetadataPrefixed(this);

  /// Check if the magic number is valid
  bool get isValidMagicNumber => magicNumber == metaReserved;

  Map<String, dynamic> toJson() => {
    'magicNumber': magicNumber,
    'metadata': {'V${metadata.version}': metadata.toJson()},
  };
}

/// Codec for RuntimeMetadataPrefixed
///
/// Handles decoding of the prefixed metadata structure including
/// version detection and routing to appropriate version-specific codecs.
class $RuntimeMetadataPrefixed with Codec<RuntimeMetadataPrefixed> {
  const $RuntimeMetadataPrefixed._();

  @override
  RuntimeMetadataPrefixed decode(Input input) {
    // Decode magic number
    final magicNumber = U32Codec.codec.decode(input);

    // Decode version
    final version = U8Codec.codec.decode(input);
    switch (version) {
      case 14:
        return RuntimeMetadataPrefixed(
          magicNumber: magicNumber,
          metadata: RuntimeMetadataV14.codec.decode(input),
        );

      case 15:
        return RuntimeMetadataPrefixed(
          magicNumber: magicNumber,
          metadata: RuntimeMetadataV15.codec.decode(input),
        );

      case 16:
        return RuntimeMetadataPrefixed(
          magicNumber: magicNumber,
          metadata: RuntimeMetadataV16.codec.decode(input),
        );

      default:
        throw Exception('Unsupported metadata version: $version');
    }
  }

  @override
  void encodeTo(RuntimeMetadataPrefixed value, Output output) {
    // Encode magic number
    U32Codec.codec.encodeTo(value.magicNumber, output);

    // Encode version and metadata based on variant
    switch (value.metadata) {
      case final RuntimeMetadataV14 v14:
        U8Codec.codec.encodeTo(14, output);
        RuntimeMetadataV14.codec.encodeTo(v14, output);

      case final RuntimeMetadataV15 v15:
        U8Codec.codec.encodeTo(15, output);
        RuntimeMetadataV15.codec.encodeTo(v15, output);

      case final RuntimeMetadataV16 v16:
        U8Codec.codec.encodeTo(16, output);
        RuntimeMetadataV16.codec.encodeTo(v16, output);
    }
  }

  @override
  int sizeHint(RuntimeMetadataPrefixed value) {
    var size = 0;
    size += U32Codec.codec.sizeHint(value.magicNumber);
    size += 1; // version byte

    switch (value.metadata) {
      case final RuntimeMetadataV14 v14:
        size += RuntimeMetadataV14.codec.sizeHint(v14);

      case final RuntimeMetadataV15 v15:
        size += RuntimeMetadataV15.codec.sizeHint(v15);

      case final RuntimeMetadataV16 v16:
        size += RuntimeMetadataV16.codec.sizeHint(v16);
    }

    return size;
  }

  @override
  bool isSizeZero() {
    // This class directly encodes magic number (U32) + version byte (U8)
    return false;
  }
}
