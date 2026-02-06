part of extrinsic_builder;

/// Unified extension info that normalizes V14/V15 SignedExtensionMetadata
/// and V16 TransactionExtensionMetadata into a common type.
///
/// - For V14/V15: `type` is the extension data type, `additionalSigned` is the
///   additional data type from [SignedExtensionMetadata].
/// - For V16: `type` is the extension data type, `additionalSigned` maps to the
///   `implicit` field from [TransactionExtensionMetadata].
class UnifiedExtensionMetadata {
  final String identifier;
  final int type;
  final int additionalSigned;

  const UnifiedExtensionMetadata({
    required this.identifier,
    required this.type,
    required this.additionalSigned,
  });

  /// Create from V14/V15 SignedExtensionMetadata
  factory UnifiedExtensionMetadata.fromSigned(SignedExtensionMetadata ext) {
    return UnifiedExtensionMetadata(
      identifier: ext.identifier,
      type: ext.type,
      additionalSigned: ext.additionalSigned,
    );
  }

  /// Create from V16 TransactionExtensionMetadata
  factory UnifiedExtensionMetadata.fromTransaction(TransactionExtensionMetadata ext) {
    return UnifiedExtensionMetadata(
      identifier: ext.identifier,
      type: ext.type,
      additionalSigned: ext.implicit,
    );
  }
}

/// Get the unified list of extensions from chain metadata.
///
/// For V14/V15, wraps SignedExtensionMetadata.
/// For V16, wraps TransactionExtensionMetadata using the primary version's extensions.
List<UnifiedExtensionMetadata> _getUnifiedExtensions(ChainInfo chainInfo) {
  final ExtrinsicMetadata extrinsic = chainInfo.registry.extrinsic;

  if (extrinsic is ExtrinsicMetadataV16) {
    // V16: Use transaction extensions for the highest supported version
    final int targetVersion = extrinsic.versions.isNotEmpty
        ? extrinsic.versions.reduce((a, b) => a > b ? a : b)
        : 0;
    final txExtensions = extrinsic.extensionsForVersion(targetVersion);
    return txExtensions
        .map((ext) => UnifiedExtensionMetadata.fromTransaction(ext))
        .toList(growable: false);
  } else {
    // V14/V15: Use signed extensions
    return extrinsic.signedExtensions
        .map((ext) => UnifiedExtensionMetadata.fromSigned(ext))
        .toList(growable: false);
  }
}

/// Detect the extrinsic version to use based on metadata.
///
/// For V16 metadata with versions containing 5, returns 5.
/// Otherwise returns 4.
int _detectExtrinsicVersion(ChainInfo chainInfo) {
  final ExtrinsicMetadata extrinsic = chainInfo.registry.extrinsic;

  if (extrinsic is ExtrinsicMetadataV16) {
    // Prefer the highest supported version
    if (extrinsic.versions.contains(5)) return 5;
    if (extrinsic.versions.contains(4)) return 4;
    return extrinsic.versions.isNotEmpty ? extrinsic.versions.reduce((a, b) => a > b ? a : b) : 4;
  }

  // V14/V15 always use version 4
  return 4;
}

/// Builder for managing signed extension values and additional signed data.
///
/// This class handles the construction and management of signed extensions that are
/// attached to extrinsics in Substrate-based blockchains. Signed extensions provide
/// additional data and validation for transactions, such as:
///
/// - **CheckNonce**: Prevents replay attacks using account nonce
/// - **CheckEra/CheckMortality**: Limits transaction validity period
/// - **CheckSpecVersion/CheckTxVersion**: Ensures runtime compatibility
/// - **CheckGenesis**: Verifies correct chain
/// - **ChargeTransactionPayment**: Handles transaction fees and tips
/// - **CheckMetadataHash**: Validates metadata version
///
/// Extensions have two components:
/// 1. **Extension values**: Included in the extrinsic payload
/// 2. **Additional signed**: Included in signing payload but not in extrinsic
///
/// ## Example Usage:
///
/// ```dart
/// final builder = ExtensionBuilder(chainInfo);
///
/// // Set standard extensions
/// builder.setStandardExtensions(
///   specVersion: 1000,
///   transactionVersion: 1,
///   genesisHash: genesisHash,
///   blockHash: currentBlockHash,
///   blockNumber: currentBlockNumber,
///   nonce: 5,
///   eraPeriod: 64,
/// );
///
/// // Override specific values
/// builder.tip(BigInt.from(1000));
/// builder.immortal();
/// ```
class ExtensionBuilder {
  /// Chain metadata and configuration information.
  final ChainInfo chainInfo;

  /// Extension values that will be included in the extrinsic.
  ///
  /// These are SCALE-encoded and included in the final transaction.
  final Map<String, dynamic> extensions = <String, dynamic>{};

  /// Additional signed data included in signing payload but not in extrinsic.
  ///
  /// This data is hashed together with the call data during signing but
  /// not transmitted with the extrinsic.
  final Map<String, dynamic> additionalSigned = <String, dynamic>{};

  /// Tracks which extensions the user has explicitly set.
  ///
  /// This prevents auto-fetched values from overriding user choices.
  final Set<String> _userOverrides = <String>{};

  // Internal state for smart defaults
  int? _specVersion;
  int? _transactionVersion;
  Uint8List? _genesisHash;
  Uint8List? _blockHash;
  int? _blockNumber;
  int? _nonce;
  BigInt _tip = BigInt.zero;
  int _eraPeriod = 64; // Default to mortal with 64 blocks
  dynamic _assetId;
  int _metadataHashMode = 0; // 0 = disabled, 1 = enabled
  Uint8List? _metadataHash;

  /// Creates a new ExtensionBuilder for the given chain.
  ///
  /// Parameters:
  /// - [chainInfo]: Chain metadata containing signed extension definitions
  ExtensionBuilder(this.chainInfo);

  /// Sets values that were automatically fetched from the chain.
  ///
  /// This method respects user overrides - if a user has explicitly set a value,
  /// it won't be overwritten by auto-fetched data.
  ///
  /// Parameters:
  /// - [userOverrides]: Set of extension categories the user has explicitly configured
  /// - [specVersion]: Runtime specification version
  /// - [transactionVersion]: Transaction version
  /// - [genesisHash]: Genesis block hash
  /// - [blockHash]: Current block hash
  /// - [blockNumber]: Current block number
  /// - [nonce]: Account nonce
  void setAutoFetchedValues({
    required Set<String> userOverrides,
    int? specVersion,
    int? transactionVersion,
    Uint8List? genesisHash,
    Uint8List? blockHash,
    int? blockNumber,
    int? nonce,
  }) {
    // Only set if user hasn't overridden
    if (!userOverrides.contains('runtime')) {
      _specVersion = specVersion;
      _transactionVersion = transactionVersion;
    }

    if (!userOverrides.contains('genesis')) {
      _genesisHash = genesisHash;
    }

    if (!userOverrides.contains('block')) {
      _blockHash = blockHash;
      _blockNumber = blockNumber;
    }

    if (!userOverrides.contains('nonce') && nonce != null) {
      _nonce = nonce;
    }

    // Apply to actual extensions
    _applyStoredValues();
  }

  /// Sets all standard extension values at once.
  ///
  /// This is the recommended method for configuring extensions when you have all
  /// the required chain data available (e.g., from [ChainDataFetcher]).
  ///
  /// Parameters:
  /// - [specVersion]: Runtime specification version
  /// - [transactionVersion]: Transaction version
  /// - [genesisHash]: Genesis block hash (32 bytes)
  /// - [blockHash]: Current block hash (32 bytes)
  /// - [blockNumber]: Current block number
  /// - [nonce]: Account nonce
  /// - [tip]: Optional tip for transaction prioritization (default: 0)
  /// - [eraPeriod]: Era period in blocks (default: 64, 0 for immortal)
  /// - [assetId]: Optional asset ID for chains with asset-based fees
  /// - [enableMetadataHash]: Whether to enable metadata hash checking (default: false)
  /// - [metadataHash]: Metadata hash if enabled
  ///
  /// Example:
  /// ```dart
  /// builder.setStandardExtensions(
  ///   specVersion: 1000,
  ///   transactionVersion: 1,
  ///   genesisHash: genesisHash,
  ///   blockHash: currentBlockHash,
  ///   blockNumber: currentBlockNumber,
  ///   nonce: 5,
  ///   tip: BigInt.from(1000),
  ///   eraPeriod: 64,
  /// );
  /// ```
  void setStandardExtensions({
    required int specVersion,
    required int transactionVersion,
    required Uint8List genesisHash,
    required Uint8List blockHash,
    required int blockNumber,
    required int nonce,
    BigInt? tip,
    int eraPeriod = 64,
    dynamic assetId,
    bool enableMetadataHash = false,
    Uint8List? metadataHash,
  }) {
    _specVersion = specVersion;
    _transactionVersion = transactionVersion;
    _genesisHash = genesisHash;
    _blockHash = blockHash;
    _blockNumber = blockNumber;
    _nonce = nonce;
    _tip = tip ?? BigInt.zero;
    _eraPeriod = eraPeriod;
    _assetId = assetId;
    _metadataHashMode = enableMetadataHash ? 1 : 0;
    _metadataHash = metadataHash;

    _applyStoredValues();
  }

  /// Apply stored values to the actual extension maps
  void _applyStoredValues() {
    // Clear existing to avoid stale values
    extensions.clear();
    additionalSigned.clear();

    // Go through each extension in metadata (unified across V14/V15/V16)
    for (final UnifiedExtensionMetadata ext in _getUnifiedExtensions(chainInfo)) {
      final String identifier = ext.identifier;

      // Check if we should skip this extension entirely
      if (_shouldSkipExtension(ext)) continue;

      switch (identifier) {
        case 'CheckNonZeroSender':
          // Zero-sized, no value or additional needed
          break;

        case 'CheckSpecVersion':
          // Only additional signed
          if (_specVersion != null) {
            additionalSigned[identifier] = _specVersion;
          }
          break;

        case 'CheckTxVersion':
          // Only additional signed
          if (_transactionVersion != null) {
            additionalSigned[identifier] = _transactionVersion;
          }
          break;

        case 'CheckGenesis':
          // Only additional signed
          if (_genesisHash != null) {
            additionalSigned[identifier] = _genesisHash;
          }
          break;

        case 'CheckEra':
        case 'CheckMortality':
          // Both value and additional signed
          // Note: Era is a special type that uses custom encoding, not standard SCALE enum
          // We store the pre-encoded bytes here, and the extrinsic encoder will write them directly
          if (_eraPeriod == 0) {
            // Immortal era - single 0x00 byte
            extensions[identifier] = Era.codec.encodeToBytes(0, 0);
            if (_genesisHash != null) {
              additionalSigned[identifier] = _genesisHash;
            }
          } else if (_blockNumber != null && _blockHash != null) {
            // Mortal era - 2 bytes using Era's special encoding
            extensions[identifier] = Era.codec.encodeMortal(_blockNumber!, _eraPeriod);
            additionalSigned[identifier] = _blockHash;
          }
          break;

        case 'CheckNonce':
          // Simple value
          if (_nonce != null) {
            extensions[identifier] = _nonce;
          }
          break;

        case 'CheckWeight':
          // Usually not included for signed transactions
          // Would need specific weight values if required
          break;

        case 'ChargeTransactionPayment':
          // Simple tip value
          extensions[identifier] = _tip;
          break;

        case 'ChargeAssetTxPayment':
          // Complex structure with tip and optional asset
          extensions[identifier] = <String, dynamic>{'tip': _tip, 'asset_id': _assetId};
          break;

        case 'CheckMetadataHash':
          // Mode-based structure
          if (_metadataHashMode == 0) {
            // Disabled
            extensions[identifier] = <String, dynamic>{'mode': MapEntry('Disabled', 0)};
            additionalSigned[identifier] = null; /* MapEntry('None', 0); */
          } else if (_metadataHashMode == 1 && _metadataHash != null) {
            // Enabled with hash
            extensions[identifier] = <String, dynamic>{'mode': MapEntry('Enabled', 1)};
            // Additional signed uses Option encoding
            additionalSigned[identifier] = _metadataHash;
            //MapEntry('Some', [0x01, ..._metadataHash!]);
          }
          break;

        default:
        // Unknown extension - log warning but continue
      }
    }
  }

  // ===== Manual setter methods =====

  /// Sets the account nonce value.
  ///
  /// The nonce prevents replay attacks by ensuring each transaction from an
  /// account is unique and ordered.
  ///
  /// Parameters:
  /// - [nonce]: The account nonce (incrementing counter)
  ///
  /// Returns:
  /// This builder instance for method chaining.
  ExtensionBuilder nonce(int nonce) {
    _userOverrides.add('nonce');
    _nonce = nonce;

    // Apply immediately if extension exists
    if (_hasExtension('CheckNonce')) {
      extensions['CheckNonce'] = nonce;
    }

    return this;
  }

  /// Sets the transaction tip for prioritization.
  ///
  /// A higher tip incentivizes block producers to include the transaction sooner.
  ///
  /// Parameters:
  /// - [tip]: The tip amount in smallest units
  ///
  /// Returns:
  /// This builder instance for method chaining.
  ExtensionBuilder tip(BigInt tip) {
    _userOverrides.add('tip');
    _tip = tip;

    // Update the relevant payment extension
    if (_hasExtension('ChargeAssetTxPayment')) {
      extensions['ChargeAssetTxPayment'] = <String, dynamic>{'tip': tip, 'asset_id': _assetId};
    } else if (_hasExtension('ChargeTransactionPayment')) {
      extensions['ChargeTransactionPayment'] = tip;
    }

    return this;
  }

  /// Configures a mortal era for the transaction.
  ///
  /// Mortal transactions are only valid for a specific number of blocks,
  /// preventing replay attacks across chain forks.
  ///
  /// Parameters:
  /// - [period]: Number of blocks the transaction is valid for
  /// - [blockNumber]: Optional block number (uses stored value if not provided)
  /// - [blockHash]: Optional block hash (uses stored value if not provided)
  ///
  /// Returns:
  /// This builder instance for method chaining.
  ExtensionBuilder era({
    required final int period,
    final int? blockNumber,
    final Uint8List? blockHash,
  }) {
    _userOverrides.add('era');
    _eraPeriod = period;

    if (blockNumber != null) {
      _blockNumber = blockNumber;
    }
    if (blockHash != null) {
      _blockHash = blockHash;
    }

    _applyEra();
    return this;
  }

  /// Makes the transaction immortal (valid indefinitely).
  ///
  /// Immortal transactions remain valid across all future blocks and forks.
  /// Use with caution as this can enable replay attacks.
  ///
  /// Returns:
  /// This builder instance for method chaining.
  ExtensionBuilder immortal() {
    _userOverrides.add('era');
    _eraPeriod = 0;

    _applyEra();
    return this;
  }

  /// Set runtime spec version
  ExtensionBuilder specVersion(int version) {
    _userOverrides.add('runtime');
    _specVersion = version;

    if (_hasExtension('CheckSpecVersion')) {
      additionalSigned['CheckSpecVersion'] = version;
    }

    return this;
  }

  /// Set transaction version
  ExtensionBuilder transactionVersion(int version) {
    _userOverrides.add('runtime');
    _transactionVersion = version;

    if (_hasExtension('CheckTxVersion')) {
      additionalSigned['CheckTxVersion'] = version;
    }

    return this;
  }

  /// Set genesis hash
  ExtensionBuilder genesisHash(Uint8List hash) {
    _userOverrides.add('genesis');
    _genesisHash = hash;

    if (_hasExtension('CheckGenesis')) {
      additionalSigned['CheckGenesis'] = hash;
    }

    // Update immortal era if applicable
    if (_eraPeriod == 0) {
      _applyEra();
    }

    return this;
  }

  /// Set current block hash
  ExtensionBuilder blockHash(Uint8List hash) {
    _userOverrides.add('block');
    _blockHash = hash;

    // Update mortal era if applicable
    if (_eraPeriod > 0) {
      _applyEra();
    }

    return this;
  }

  /// Set asset for payment (for chains with asset payment)
  ExtensionBuilder assetId(dynamic assetId) {
    _userOverrides.add('asset');
    _assetId = assetId;

    if (_hasExtension('ChargeAssetTxPayment')) {
      extensions['ChargeAssetTxPayment'] = <String, dynamic>{'tip': _tip, 'asset_id': assetId};
    }

    return this;
  }

  /// Enable or disable metadata hash
  ExtensionBuilder metadataHash({bool enabled = true, Uint8List? hash}) {
    _userOverrides.add('metadataHash');
    _metadataHashMode = enabled ? 1 : 0;
    _metadataHash = hash;

    if (_hasExtension('CheckMetadataHash')) {
      if (enabled && hash != null) {
        extensions['CheckMetadataHash'] = <String, dynamic>{'mode': MapEntry('Enabled', 1)};
        additionalSigned['CheckMetadataHash'] = [...hash];
      } else {
        extensions['CheckMetadataHash'] = <String, dynamic>{'mode': MapEntry('Disabled', 0)};
        additionalSigned['CheckMetadataHash'] = null;
      }
    }

    return this;
  }

  /// Set a custom extension value
  ExtensionBuilder customExtension(String identifier, dynamic value, {dynamic additional}) {
    _userOverrides.add('custom_$identifier');

    if (value != null) {
      extensions[identifier] = value;
    }
    if (additional != null) {
      additionalSigned[identifier] = additional;
    }

    return this;
  }

  // ===== Helper methods =====

  /// Applies current era settings to the extensions map.
  ///
  /// This internal method encodes the era (immortal or mortal) and updates
  /// both the extension value and additional signed data appropriately.
  void _applyEra() {
    String? extName;
    if (_hasExtension('CheckMortality')) {
      extName = 'CheckMortality';
    } else if (_hasExtension('CheckEra')) {
      extName = 'CheckEra';
    }

    if (extName == null) return;

    // Era is a special type that uses custom encoding, not standard SCALE enum
    if (_eraPeriod == 0) {
      // Immortal - single 0x00 byte
      extensions[extName] = Era.codec.encodeToBytes(0, 0);
      if (_genesisHash != null) {
        additionalSigned[extName] = _genesisHash;
      }
    } else if (_blockNumber != null && _blockHash != null) {
      // Mortal - 2 bytes using Era's special encoding
      extensions[extName] = Era.codec.encodeMortal(_blockNumber!, _eraPeriod);
      additionalSigned[extName] = _blockHash;
    }
  }

  /// Determines if an extension should be skipped entirely.
  ///
  /// Extensions are skipped if both their value and additional signed components
  /// are zero-sized (have no data to encode).
  ///
  /// Parameters:
  /// - [ext]: The unified extension metadata to check
  ///
  /// Returns:
  /// `true` if the extension should be skipped, `false` otherwise.
  bool _shouldSkipExtension(UnifiedExtensionMetadata ext) {
    final valueCodec = chainInfo.registry.codecFor(ext.type);
    final additionalCodec = chainInfo.registry.codecFor(ext.additionalSigned);

    // Skip if both value and additional are zero-sized
    return (valueCodec is NullCodec || valueCodec.isSizeZero()) &&
        (additionalCodec is NullCodec || additionalCodec.isSizeZero());
  }

  /// Checks if the chain supports a specific extension.
  ///
  /// Works with both V14/V15 signed extensions and V16 transaction extensions.
  ///
  /// Parameters:
  /// - [identifier]: The extension identifier (e.g., 'CheckNonce')
  ///
  /// Returns:
  /// `true` if the extension is defined in the chain metadata, `false` otherwise.
  bool _hasExtension(String identifier) {
    return _getUnifiedExtensions(chainInfo).any((ext) => ext.identifier == identifier);
  }

  /// Validates that all required extension values are set.
  ///
  /// This method checks that every non-zero-sized extension has both its value
  /// and additional signed components properly configured.
  ///
  /// Throws:
  /// - [ExtensionValidationError] if any required extension values are missing
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   builder.validate();
  /// } catch (e) {
  ///   print('Missing extensions: $e');
  /// }
  /// ```
  void validate() {
    final missing = <String>[];

    for (final ext in _getUnifiedExtensions(chainInfo)) {
      final valueCodec = chainInfo.registry.codecFor(ext.type);
      final additionalCodec = chainInfo.registry.codecFor(ext.additionalSigned);

      // Skip completely zero-sized extensions
      if (_shouldSkipExtension(ext)) {
        continue;
      }

      // Check extension value
      if (!(valueCodec is NullCodec || valueCodec.isSizeZero())) {
        if (!extensions.containsKey(ext.identifier)) {
          missing.add('${ext.identifier} (value)');
        }
      }

      // Check additional signed
      if (!(additionalCodec is NullCodec || additionalCodec.isSizeZero())) {
        if (!additionalSigned.containsKey(ext.identifier)) {
          missing.add('${ext.identifier} (additional)');
        }
      }
    }

    if (missing.isNotEmpty) {
      throw ExtensionValidationError(
        'Missing required extensions: ${missing.join(', ')}\n'
        'Tip: Use ExtrinsicBuilder.auto() for automatic fetching, '
        'or provide missing values manually.',
      );
    }
  }

  /// Returns a summary of the configured extensions for debugging.
  ///
  /// Returns:
  /// A [Map] containing:
  /// - `extensions`: List of configured extension identifiers
  /// - `additionalSigned`: List of additional signed data identifiers
  /// - `userOverrides`: List of user-overridden extension categories
  /// - `era`: Description of the era configuration
  /// - `nonce`: The current nonce value
  /// - `tip`: The current tip amount
  ///
  /// Example:
  /// ```dart
  /// final summary = builder.summary();
  /// print('Configured extensions: ${summary['extensions']}');
  /// print('Era: ${summary['era']}');
  /// ```
  Map<String, dynamic> summary() {
    return {
      'extensions': extensions.keys.toList(),
      'additionalSigned': additionalSigned.keys.toList(),
      'userOverrides': _userOverrides.toList(),
      'era': _eraPeriod == 0 ? 'immortal' : 'mortal($_eraPeriod blocks)',
      'nonce': _nonce,
      'tip': _tip.toString(),
    };
  }
}

/// Exception thrown when extension validation fails.
///
/// This error indicates that required signed extension values are missing
/// and the extrinsic cannot be properly constructed.
///
/// Example:
/// ```dart
/// try {
///   builder.validate();
/// } catch (e) {
///   if (e is ExtensionValidationError) {
///     print('Validation failed: ${e.message}');
///     // Handle missing extensions...
///   }
/// }
/// ```
class ExtensionValidationError implements Exception {
  /// The error message describing which extensions are missing.
  final String message;

  /// Creates a new ExtensionValidationError.
  ///
  /// Parameters:
  /// - [message]: Description of the validation failure
  ExtensionValidationError(this.message);

  @override
  String toString() => 'ExtensionValidationError: $message';
}
