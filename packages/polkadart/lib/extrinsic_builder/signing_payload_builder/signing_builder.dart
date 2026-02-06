part of extrinsic_builder;

/// Builder for creating and signing transaction payloads
///
/// This class handles the creation of signing payloads from extension values,
/// signs them with the signing callback method call, and returns a signed result ready for encoding
/// into an extrinsic.
class SigningBuilder {
  final ChainInfo chainInfo;
  final ExtensionBuilder extensionBuilder;

  const SigningBuilder({required this.chainInfo, required this.extensionBuilder});

  /// Create and sign an extrinsic
  ///
  /// This method:
  /// 1. Validates all required extensions are present
  /// 2. Creates the signing payload
  /// 3. Signs it with the signing callback
  /// 4. Returns a SignedData result
  SignedData createSignedExtrinsic({
    required final Uint8List callData,
    required final SigningCallback signingCallback,
    required final Uint8List signer,
  }) {
    // 1. Validate we have all required extensions
    extensionBuilder.validate();

    // 2. Create the signing payload
    final signingPayload = _createSigningPayload(callData);

    // 3. Sign the payload
    final signature = signingCallback(signingPayload);

    // 4. Return signed data
    return SignedData(
      signer: signer,
      signature: signature,
      extensions: Map.from(extensionBuilder.extensions),
      additionalSigned: Map.from(extensionBuilder.additionalSigned),
      callData: callData,
      signingPayload: signingPayload,
    );
  }

  /// Create the signing payload from call data and extensions
  ///
  /// The signing payload consists of:
  /// 1. The encoded call data
  /// 2. Extension values (non-zero-sized only)
  /// 3. Additional signed data (non-zero-sized only)
  ///
  /// If the resulting payload is > 256 bytes, it will be hashed with Blake2b-256
  Uint8List _createSigningPayload(Uint8List callData) {
    final output = ByteOutput();

    // 1. Add the call data first
    output.write(callData);

    // 2. Add extension values (in metadata order, skip zero-sized)
    for (final ext in _getUnifiedExtensions(chainInfo)) {
      final codec = chainInfo.registry.codecFor(ext.type);

      // Skip zero-sized extensions for efficiency
      if (codec is NullCodec || codec.isSizeZero()) {
        continue;
      }

      final value = extensionBuilder.extensions[ext.identifier];
      /* if (value == null) {
        // This shouldn't happen if validate() passed
        throw StateError('Missing extension value for ${ext.identifier} during signing. '
            'This should have been caught during validation.');
      } */

      try {
        // Special handling for CheckMortality/CheckEra
        // Era uses custom encoding (1 or 2 bytes), not standard SCALE enum
        if (ext.identifier == 'CheckMortality' || ext.identifier == 'CheckEra') {
          if (value is Uint8List) {
            // Pre-encoded era bytes from Era.codec
            output.write(value);
          } else {
            throw SigningError(
              'CheckMortality/CheckEra value must be Uint8List (pre-encoded era bytes)',
            );
          }
        } else {
          // Use standard codec for other extensions
          codec.encodeTo(value, output);
        }
      } catch (e) {
        throw SigningError(
          'Failed to encode extension ${ext.identifier}: $e\n'
          'Value: $value\n'
          'Codec: ${codec.runtimeType}',
        );
      }
    }

    // 3. Add additional signed data (in metadata order, skip zero-sized)
    for (final ext in _getUnifiedExtensions(chainInfo)) {
      final codec = chainInfo.registry.codecFor(ext.additionalSigned);

      // Skip zero-sized for efficiency
      if (codec is NullCodec || codec.isSizeZero()) {
        continue;
      }

      final value = extensionBuilder.additionalSigned[ext.identifier];
      /* if (value == null) {
        // This shouldn't happen if validate() passed
        throw StateError('Missing additional signed for ${ext.identifier} during signing. '
            'This should have been caught during validation.');
      } */

      try {
        codec.encodeTo(value, output);
      } catch (e) {
        throw SigningError(
          'Failed to encode additional signed ${ext.identifier}: $e\n'
          'Value: $value\n'
          'Codec: ${codec.runtimeType}',
        );
      }
    }

    final payload = output.toBytes();

    // Hash if payload > 256 bytes (Substrate convention)
    if (payload.length > 256) {
      return Hasher.blake2b256.hash(payload);
    }

    return payload;
  }

  /// Create signing payload without signing (useful for testing or external signing)
  Uint8List createPayloadToSign(Uint8List callData) {
    // Validate first
    extensionBuilder.validate();

    // Return the signing payload
    return _createSigningPayload(callData);
  }

  /// Get information about what will be signed
  SigningInfo getSigningInfo(Uint8List callData) {
    // Create the raw payload to check size
    final output = ByteOutput();
    output.write(callData);

    // Count non-zero extensions
    int extensionCount = 0;
    int additionalCount = 0;

    for (final ext in _getUnifiedExtensions(chainInfo)) {
      final valueCodec = chainInfo.registry.codecFor(ext.type);
      final additionalCodec = chainInfo.registry.codecFor(ext.additionalSigned);

      if (!(valueCodec is NullCodec || valueCodec.isSizeZero())) {
        extensionCount++;
        final value = extensionBuilder.extensions[ext.identifier];
        if (value != null) {
          valueCodec.encodeTo(value, output);
        }
      }

      if (!(additionalCodec is NullCodec || additionalCodec.isSizeZero())) {
        additionalCount++;
        final value = extensionBuilder.additionalSigned[ext.identifier];
        if (value != null) {
          additionalCodec.encodeTo(value, output);
        }
      }
    }

    final rawPayload = output.toBytes();

    return SigningInfo(
      callDataSize: callData.length,
      extensionCount: extensionCount,
      additionalSignedCount: additionalCount,
      rawPayloadSize: rawPayload.length,
      willBeHashed: rawPayload.length > 256,
      extensions: Map.from(extensionBuilder.extensions),
      additionalSigned: Map.from(extensionBuilder.additionalSigned),
    );
  }
}

/// Error thrown during signing operations
class SigningError implements Exception {
  final String message;

  SigningError(this.message);

  @override
  String toString() => 'SigningError: $message';
}
