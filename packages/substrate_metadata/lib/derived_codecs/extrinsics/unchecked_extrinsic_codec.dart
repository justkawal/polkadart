part of derived_codecs;

/// Version byte bit masks for extrinsic encoding
///
/// Extrinsic v4:
/// - `0b0XXX_0100` (0x04) = unsigned/bare
/// - `0b1XXX_0100` (0x84) = signed
///
/// Extrinsic v5:
/// - `0b0000_0101` (0x05) = bare (inherent)
/// - `0b1000_0101` (0x85) = signed (old-school)
/// - `0b0100_0101` (0x45) = general (new-school, extensions without signature)
const int _signedBit = 0x80; // Bit 7: signed flag
const int _generalBit = 0x40; // Bit 6: general flag (v5 only)
const int _versionMask = 0x3F; // Lower 6 bits: version number

/// Supported extrinsic format versions
const int _extrinsicV4 = 4;
const int _extrinsicV5 = 5;

/// Codec for a single UncheckedExtrinsic
///
/// Handles the core extrinsic encoding/decoding logic for both v4 and v5 formats:
/// - v4: Traditional signed/unsigned model
/// - v5: New bare/signed/general model with TransactionExtension support
class UncheckedExtrinsicCodec with Codec<UncheckedExtrinsic> {
  final MetadataTypeRegistry registry;
  late final RuntimeCallCodec _callCodec;
  late final ExtrinsicSignatureCodec _signatureCodec;
  late final SignedExtensionsCodec _extensionsCodec;

  UncheckedExtrinsicCodec(this.registry) {
    _callCodec = RuntimeCallCodec(registry);
    _signatureCodec = ExtrinsicSignatureCodec(registry);
    _extensionsCodec = SignedExtensionsCodec(registry);
  }

  /// Parse the version byte to extract version number and extrinsic type
  (int version, ExtrinsicType type) _parseVersionByte(final int versionByte) {
    final int version = versionByte & _versionMask;
    final bool isSigned = (versionByte & _signedBit) != 0;
    final bool isGeneral = (versionByte & _generalBit) != 0;

    // Determine extrinsic type based on flags
    if (isSigned) {
      // Signed extrinsic (v4: 0x84, v5: 0x85)
      return (version, ExtrinsicType.signed);
    } else if (isGeneral) {
      // General extrinsic - v5 only (0x45)
      if (version != _extrinsicV5) {
        throw MetadataException(
          'General extrinsics are only supported in v5, got version $version',
        );
      }
      return (version, ExtrinsicType.general);
    } else {
      // Bare/unsigned extrinsic (v4: 0x04, v5: 0x05)
      return (version, ExtrinsicType.bare);
    }
  }

  /// Build the version byte from version number and extrinsic type
  int _buildVersionByte(final int version, final ExtrinsicType type) {
    int versionByte = version & _versionMask;

    switch (type) {
      case ExtrinsicType.signed:
        versionByte |= _signedBit;
        break;
      case ExtrinsicType.general:
        if (version != _extrinsicV5) {
          throw MetadataException(
            'General extrinsics are only supported in v5, got version $version',
          );
        }
        versionByte |= _generalBit;
        break;
      case ExtrinsicType.bare:
        // No flags set for bare extrinsics
        break;
    }

    return versionByte;
  }

  @override
  UncheckedExtrinsic decode(final Input input) {
    // Read version byte and extract the actual version and type
    final int versionByte = input.read();
    final (int version, ExtrinsicType type) = _parseVersionByte(versionByte);

    // Validate version - accept both v4 and v5
    // Note: Metadata may report v4 even when v5 extrinsics are used (known issue)
    if (version != _extrinsicV4 && version != _extrinsicV5) {
      throw MetadataException(
        'Unsupported extrinsic version: $version (supported: $_extrinsicV4, $_extrinsicV5)',
      );
    }

    ExtrinsicSignature? signature;
    Map<String, dynamic>? extensions;

    switch (type) {
      case ExtrinsicType.signed:
        // Signed extrinsic: signature (address + sig + extra) followed by call
        signature = _signatureCodec.decode(input);
        break;

      case ExtrinsicType.general:
        // General extrinsic (v5): extension version byte + extensions followed by call
        final extensionVersion = input.read();
        extensions = {'extensionVersion': extensionVersion, ..._extensionsCodec.decode(input)};
        break;

      case ExtrinsicType.bare:
        // Bare extrinsic: just the call, no signature or extensions
        break;
    }

    final call = _callCodec.decode(input);

    return UncheckedExtrinsic(
      version: version,
      type: type,
      signature: signature,
      extensions: extensions,
      call: call,
    );
  }

  @override
  void encodeTo(final UncheckedExtrinsic value, final Output output) {
    // Build and write version byte
    final versionByte = _buildVersionByte(value.version, value.type);
    output.pushByte(versionByte);

    switch (value.type) {
      case ExtrinsicType.signed:
        // Encode signature
        if (value.signature == null) {
          throw MetadataException('Signed extrinsic must have a signature');
        }
        _signatureCodec.encodeTo(value.signature!, output);
        break;

      case ExtrinsicType.general:
        // Encode extension version byte + extensions
        if (value.extensions == null) {
          throw MetadataException('General extrinsic must have extensions');
        }
        final extensionVersion = value.extensions!['extensionVersion'] as int? ?? 0;
        output.pushByte(extensionVersion);

        // Encode the extensions data
        final extData = Map<String, dynamic>.from(value.extensions!);
        extData.remove('extensionVersion');
        _extensionsCodec.encodeTo(extData, output);
        break;

      case ExtrinsicType.bare:
        // No additional data for bare extrinsics
        break;
    }

    // Encode call
    _callCodec.encodeTo(value.call, output);
  }

  @override
  int sizeHint(final UncheckedExtrinsic value) {
    int size = 1; // Version byte

    switch (value.type) {
      case ExtrinsicType.signed:
        if (value.signature != null) {
          size += _signatureCodec.sizeHint(value.signature!);
        }
        break;

      case ExtrinsicType.general:
        size += 1; // Extension version byte
        if (value.extensions != null) {
          final extData = Map<String, dynamic>.from(value.extensions!);
          extData.remove('extensionVersion');
          size += _extensionsCodec.sizeHint(extData);
        }
        break;

      case ExtrinsicType.bare:
        // No additional size for bare extrinsics
        break;
    }

    size += _callCodec.sizeHint(value.call);
    return size;
  }

  @override
  bool isSizeZero() {
    // This class directly encodes a version byte
    return false;
  }
}
