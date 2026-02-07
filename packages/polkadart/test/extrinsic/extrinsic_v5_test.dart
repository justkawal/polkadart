import 'dart:convert' show jsonDecode;
import 'dart:io' show Directory, File;
import 'dart:typed_data' show Uint8List;

import 'package:polkadart/extrinsic_builder/extrinsic_builder_base.dart'
    show ExtrinsicEncoder, ExtensionBuilder, SigningBuilder, SignedData, EncodingError;
import 'package:polkadart_scale_codec/polkadart_scale_codec.dart' show ByteInput, CompactCodec;
import 'package:substrate_metadata/chain/chain_info.dart' show ChainInfo;
import 'package:substrate_metadata/metadata/metadata.dart'
    show ExtrinsicMetadataV16, RuntimeMetadataPrefixed;
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Find the monorepo root by walking up looking for the 'chain' directory.
/// Mirrors the pattern from substrate_metadata/test/chain_tests/test_helpers.dart
String _findMonorepoRoot() {
  var current = Directory.current;
  while (current.path != current.parent.path) {
    final chainDir = Directory('${current.path}/chain');
    if (chainDir.existsSync()) {
      return current.path;
    }
    current = current.parent;
  }
  throw StateError(
    'Could not find monorepo root (directory containing "chain" folder). '
    'Current directory: ${Directory.current.path}',
  );
}

String? _cachedMonorepoRoot;
String get _chainBasePath {
  _cachedMonorepoRoot ??= _findMonorepoRoot();
  return '$_cachedMonorepoRoot/chain';
}

String chainPath(String relativePath) => '$_chainBasePath/$relativePath';

/// Load a ChainInfo from a chain metadata JSON file
ChainInfo loadChainInfo(String path) {
  final file = File(path);
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final metadataHex = json['metadata'] as String;
  final prefixed = RuntimeMetadataPrefixed.fromHex(metadataHex);
  return ChainInfo.fromRuntimeMetadataPrefixed(prefixed);
}

/// Calculate the compact prefix length from the first byte
int _compactPrefixLength(int firstByte) {
  final mode = firstByte & 0x03;
  if (mode == 0x00) return 1;
  if (mode == 0x01) return 2;
  if (mode == 0x02) return 4;
  return (firstByte >> 2) + 5;
}

/// Convert bytes to hex string
String _toHex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late ChainInfo v16ChainInfo;
  late ChainInfo v15ChainInfo;
  late bool v16Available;
  late bool v15Available;

  setUpAll(() {
    v16Available = false;
    v15Available = false;

    try {
      v16ChainInfo = loadChainInfo(chainPath('polkadot/v16/metadata_spec2000001.json'));
      v16Available = true;
    } catch (_) {
      // V16 metadata not available
    }

    try {
      v15ChainInfo = loadChainInfo(chainPath('polkadot/v15/metadata_spec1003003.json'));
      v15Available = true;
    } catch (_) {
      // V15 metadata not available
    }
  });

  // =========================================================================
  // Gap 6: Metadata fixtures availability assertion
  // =========================================================================
  group('Metadata Fixtures', () {
    test('V16 and V15 metadata fixtures are available', () {
      expect(
        v16Available,
        isTrue,
        reason:
            'V16 metadata required for V5 tests. '
            'Ensure git-lfs has pulled chain/polkadot/v16/',
      );
      expect(
        v15Available,
        isTrue,
        reason:
            'V15 metadata required for V4 fallback tests. '
            'Ensure git-lfs has pulled chain/polkadot/v15/',
      );
    });
  });

  // =========================================================================
  // Existing: Version Detection
  // =========================================================================
  group('ExtrinsicEncoder Version Detection', () {
    test('V15 metadata -> extrinsic version 4', () {
      if (!v15Available) return;
      final encoder = ExtrinsicEncoder(v15ChainInfo);
      expect(encoder.extrinsicVersion, equals(4));
    });

    test('V16 metadata -> detects correct extrinsic version', () {
      if (!v16Available) return;
      final encoder = ExtrinsicEncoder(v16ChainInfo);
      final extrinsic = v16ChainInfo.registry.extrinsic;
      expect(extrinsic, isA<ExtrinsicMetadataV16>());
      final v16 = extrinsic as ExtrinsicMetadataV16;
      if (v16.versions.contains(5)) {
        expect(encoder.extrinsicVersion, equals(5));
      } else {
        expect(encoder.extrinsicVersion, equals(4));
      }
    });
  });

  // =========================================================================
  // Existing: UnifiedExtensionMetadata
  // =========================================================================
  group('UnifiedExtensionMetadata', () {
    test('V15 metadata returns non-empty unified extensions', () {
      if (!v15Available) return;
      final builder = ExtensionBuilder(v15ChainInfo);
      expect(builder.summary()['extensions'], isNotNull);
    });

    test('V16 metadata returns non-empty unified extensions', () {
      if (!v16Available) return;
      final builder = ExtensionBuilder(v16ChainInfo);
      expect(builder.summary()['extensions'], isNotNull);
    });
  });

  // =========================================================================
  // Existing: V5 Signed Encoding
  // =========================================================================
  group('V5 Signed Encoding', () {
    test('V5 signed extrinsic has version byte 0x85', () {
      if (!v16Available) return;
      final encoder = ExtrinsicEncoder(v16ChainInfo);
      if (encoder.extrinsicVersion != 5) return;

      final extensionBuilder = ExtensionBuilder(v16ChainInfo);
      extensionBuilder.setStandardExtensions(
        specVersion: 1000,
        transactionVersion: 1,
        genesisHash: Uint8List(32),
        blockHash: Uint8List(32),
        blockNumber: 100,
        nonce: 0,
        eraPeriod: 64,
      );

      final signedData = SignedData(
        signer: Uint8List(32),
        signature: Uint8List(64),
        extensions: Map<String, dynamic>.from(extensionBuilder.extensions),
        additionalSigned: Map<String, dynamic>.from(extensionBuilder.additionalSigned),
        callData: Uint8List.fromList([0x00, 0x00]),
        signingPayload: Uint8List(32),
      );

      final encoded = encoder.encodeWithoutPrefix(signedData);
      expect(encoded[0], equals(0x85));
    });
  });

  // =========================================================================
  // Existing: V5 Bare Encoding
  // =========================================================================
  group('V5 Bare Encoding', () {
    test('V5 bare extrinsic has version byte 0x05', () {
      if (!v16Available) return;
      final encoder = ExtrinsicEncoder(v16ChainInfo);
      if (encoder.extrinsicVersion != 5) return;

      final callData = Uint8List.fromList([0x00, 0x01, 0x02]);
      final encoded = encoder.encodeUnsigned(callData);
      final int prefixLen5 = _compactPrefixLength(encoded[0]);
      expect(encoded[prefixLen5], equals(0x05));
    });

    test('V4 bare extrinsic has version byte 0x04', () {
      if (!v15Available) return;
      final encoder = ExtrinsicEncoder(v15ChainInfo);
      expect(encoder.extrinsicVersion, equals(4));

      final callData = Uint8List.fromList([0x00, 0x01, 0x02]);
      final encoded = encoder.encodeUnsigned(callData);
      final int prefixLen4 = _compactPrefixLength(encoded[0]);
      expect(encoded[prefixLen4], equals(0x04));
    });
  });

  // =========================================================================
  // Existing: V5 General Encoding
  // =========================================================================
  group('V5 General Encoding', () {
    test('encodeGeneral produces version byte 0x45', () {
      if (!v16Available) return;
      final encoder = ExtrinsicEncoder(v16ChainInfo);
      if (encoder.extrinsicVersion != 5) return;

      final extensionBuilder = ExtensionBuilder(v16ChainInfo);
      extensionBuilder.setStandardExtensions(
        specVersion: 1000,
        transactionVersion: 1,
        genesisHash: Uint8List(32),
        blockHash: Uint8List(32),
        blockNumber: 100,
        nonce: 0,
        eraPeriod: 64,
      );

      final callData = Uint8List.fromList([0x00, 0x01]);
      final encoded = encoder.encodeGeneral(
        callData: callData,
        extensions: extensionBuilder.extensions,
        extensionVersion: 0,
      );

      final int prefixLen = _compactPrefixLength(encoded[0]);
      expect(encoded[prefixLen], equals(0x45));
      expect(encoded[prefixLen + 1], equals(0));
    });

    test('encodeGeneral throws on V4', () {
      if (!v15Available) return;
      final encoder = ExtrinsicEncoder(v15ChainInfo);
      expect(encoder.extrinsicVersion, equals(4));

      expect(
        () => encoder.encodeGeneral(callData: Uint8List.fromList([0x00]), extensions: {}),
        throwsA(isA<EncodingError>()),
      );
    });

    test('encodeGeneral error message mentions V5', () {
      if (!v15Available) return;
      final encoder = ExtrinsicEncoder(v15ChainInfo);

      try {
        encoder.encodeGeneral(callData: Uint8List.fromList([0x00]), extensions: {});
        fail('Should have thrown');
      } on EncodingError catch (e) {
        expect(e.message, contains('V5'));
        expect(e.message, contains('version'));
      }
    });
  });

  // =========================================================================
  // Existing: V4 Fallback
  // =========================================================================
  group('V4 Fallback', () {
    test('V15 metadata produces V4 signed extrinsic (0x84)', () {
      if (!v15Available) return;
      final encoder = ExtrinsicEncoder(v15ChainInfo);

      final extensionBuilder = ExtensionBuilder(v15ChainInfo);
      extensionBuilder.setStandardExtensions(
        specVersion: 1000,
        transactionVersion: 1,
        genesisHash: Uint8List(32),
        blockHash: Uint8List(32),
        blockNumber: 100,
        nonce: 0,
        eraPeriod: 64,
      );

      final signedData = SignedData(
        signer: Uint8List(32),
        signature: Uint8List(64),
        extensions: Map<String, dynamic>.from(extensionBuilder.extensions),
        additionalSigned: Map<String, dynamic>.from(extensionBuilder.additionalSigned),
        callData: Uint8List.fromList([0x00, 0x00]),
        signingPayload: Uint8List(32),
      );

      final encoded = encoder.encodeWithoutPrefix(signedData);
      expect(encoded[0], equals(0x84));
    });
  });

  // =========================================================================
  // Existing: ExtensionBuilder with V16
  // =========================================================================
  group('ExtensionBuilder with V16', () {
    test('V16 extension builder configures all standard extensions', () {
      if (!v16Available) return;
      final builder = ExtensionBuilder(v16ChainInfo);
      builder.setStandardExtensions(
        specVersion: 2000001,
        transactionVersion: 1,
        genesisHash: Uint8List(32),
        blockHash: Uint8List(32),
        blockNumber: 100,
        nonce: 42,
        eraPeriod: 64,
        tip: BigInt.from(1000),
      );

      expect(builder.extensions, isNotEmpty);
      expect(builder.extensions['CheckNonce'], equals(42));
    });

    test('V16 extension builder validates without errors', () {
      if (!v16Available) return;
      final builder = ExtensionBuilder(v16ChainInfo);
      builder.setStandardExtensions(
        specVersion: 2000001,
        transactionVersion: 1,
        genesisHash: Uint8List(32),
        blockHash: Uint8List(32),
        blockNumber: 100,
        nonce: 42,
        eraPeriod: 64,
      );

      expect(() => builder.validate(), returnsNormally);
    });
  });

  // =========================================================================
  // Existing: SigningBuilder with V16
  // =========================================================================
  group('SigningBuilder with V16', () {
    test('V16 signing builder creates signing payload', () {
      if (!v16Available) return;
      final extensionBuilder = ExtensionBuilder(v16ChainInfo);
      extensionBuilder.setStandardExtensions(
        specVersion: 2000001,
        transactionVersion: 1,
        genesisHash: Uint8List(32),
        blockHash: Uint8List(32),
        blockNumber: 100,
        nonce: 0,
        eraPeriod: 64,
      );

      final signingBuilder = SigningBuilder(
        chainInfo: v16ChainInfo,
        extensionBuilder: extensionBuilder,
      );

      final callData = Uint8List.fromList([0x00, 0x00]);
      final payload = signingBuilder.createPayloadToSign(callData);

      expect(payload, isNotEmpty);
      expect(payload.length, greaterThan(0));
    });
  });

  // =========================================================================
  // Gap 4: Hardcoded Hex Test Vectors
  // =========================================================================
  group('Hardcoded Hex Test Vectors', () {
    // --- Bare extrinsic hex vectors ---

    test('V5 bare extrinsic with known call matches exact hex', () {
      if (!v16Available) return;
      final encoder = ExtrinsicEncoder(v16ChainInfo);
      if (encoder.extrinsicVersion != 5) return;

      // Bare extrinsic with call [0x00, 0x01]
      // Expected: compact(3) + version(0x05) + call(0x00 0x01)
      // compact(3) = 0x0c (3 << 2 = 12 = 0x0c in single-byte mode)
      final callData = Uint8List.fromList([0x00, 0x01]);
      final encoded = encoder.encodeUnsigned(callData);
      expect(_toHex(encoded), equals('0c050001'));
    });

    test('V4 bare extrinsic with known call matches exact hex', () {
      if (!v15Available) return;
      final encoder = ExtrinsicEncoder(v15ChainInfo);
      expect(encoder.extrinsicVersion, equals(4));

      // Bare extrinsic with call [0x00, 0x01]
      // Expected: compact(3) + version(0x04) + call(0x00 0x01)
      final callData = Uint8List.fromList([0x00, 0x01]);
      final encoded = encoder.encodeUnsigned(callData);
      expect(_toHex(encoded), equals('0c040001'));
    });

    test('V5 bare extrinsic with single-byte call matches exact hex', () {
      if (!v16Available) return;
      final encoder = ExtrinsicEncoder(v16ChainInfo);
      if (encoder.extrinsicVersion != 5) return;

      // Bare with call [0xff]
      // Expected: compact(2) + version(0x05) + call(0xff)
      // compact(2) = 0x08
      final callData = Uint8List.fromList([0xff]);
      final encoded = encoder.encodeUnsigned(callData);
      expect(_toHex(encoded), equals('0805ff'));
    });

    test('V4 bare extrinsic with empty call matches exact hex', () {
      if (!v15Available) return;
      final encoder = ExtrinsicEncoder(v15ChainInfo);

      // Bare with empty call
      // Expected: compact(1) + version(0x04)
      // compact(1) = 0x04
      final callData = Uint8List.fromList([]);
      final encoded = encoder.encodeUnsigned(callData);
      expect(_toHex(encoded), equals('0404'));
    });

    // --- MultiAddress encoding vectors ---

    test('MultiAddress: 32-byte AccountId has prefix 0x00', () {
      if (!v16Available) return;
      final encoder = ExtrinsicEncoder(v16ChainInfo);
      if (encoder.extrinsicVersion != 5) return;

      final extensionBuilder = ExtensionBuilder(v16ChainInfo);
      extensionBuilder.setStandardExtensions(
        specVersion: 1000,
        transactionVersion: 1,
        genesisHash: Uint8List(32),
        blockHash: Uint8List(32),
        blockNumber: 100,
        nonce: 0,
        eraPeriod: 64,
      );

      // 32-byte signer maps to MultiAddress::Id (prefix 0x00)
      final signer = Uint8List.fromList(List.generate(32, (i) => i));

      final signedData = SignedData(
        signer: signer,
        signature: Uint8List(64),
        extensions: Map<String, dynamic>.from(extensionBuilder.extensions),
        additionalSigned: Map<String, dynamic>.from(extensionBuilder.additionalSigned),
        callData: Uint8List.fromList([0x00, 0x00]),
        signingPayload: Uint8List(32),
      );

      final encoded = encoder.encodeWithoutPrefix(signedData);
      // Version byte 0x85, then MultiAddress::Id prefix 0x00, then 32 bytes
      expect(encoded[0], equals(0x85));
      expect(encoded[1], equals(0x00)); // MultiAddress::Id
      expect(encoded.sublist(2, 34), equals(signer));
    });

    test('MultiAddress: 20-byte address has prefix 0x04', () {
      if (!v16Available) return;
      final encoder = ExtrinsicEncoder(v16ChainInfo);
      if (encoder.extrinsicVersion != 5) return;

      final extensionBuilder = ExtensionBuilder(v16ChainInfo);
      extensionBuilder.setStandardExtensions(
        specVersion: 1000,
        transactionVersion: 1,
        genesisHash: Uint8List(32),
        blockHash: Uint8List(32),
        blockNumber: 100,
        nonce: 0,
        eraPeriod: 64,
      );

      // 20-byte signer maps to MultiAddress::Address20 (prefix 0x04)
      final signer = Uint8List.fromList(List.generate(20, (_) => 0xaa));

      final signedData = SignedData(
        signer: signer,
        signature: Uint8List(64),
        extensions: Map<String, dynamic>.from(extensionBuilder.extensions),
        additionalSigned: Map<String, dynamic>.from(extensionBuilder.additionalSigned),
        callData: Uint8List.fromList([0x00, 0x00]),
        signingPayload: Uint8List(32),
      );

      final encoded = encoder.encodeWithoutPrefix(signedData);
      expect(encoded[0], equals(0x85));
      expect(encoded[1], equals(0x04)); // MultiAddress::Address20
      expect(encoded.sublist(2, 22), equals(Uint8List.fromList(List.filled(20, 0xaa))));
    });

    // --- MultiSignature encoding vectors ---

    test('MultiSignature: Ed25519 (64 bytes, last byte bit7=0) has prefix 0x00', () {
      if (!v16Available) return;
      final encoder = ExtrinsicEncoder(v16ChainInfo);
      if (encoder.extrinsicVersion != 5) return;

      final extensionBuilder = ExtensionBuilder(v16ChainInfo);
      extensionBuilder.setStandardExtensions(
        specVersion: 1000,
        transactionVersion: 1,
        genesisHash: Uint8List(32),
        blockHash: Uint8List(32),
        blockNumber: 100,
        nonce: 0,
        eraPeriod: 64,
      );

      // Ed25519: 64 bytes with last byte bit 7 = 0
      final signature = Uint8List(64);
      signature[63] = 0x7f; // bit 7 is 0, so Ed25519

      final signedData = SignedData(
        signer: Uint8List(32),
        signature: signature,
        extensions: Map<String, dynamic>.from(extensionBuilder.extensions),
        additionalSigned: Map<String, dynamic>.from(extensionBuilder.additionalSigned),
        callData: Uint8List.fromList([0x00, 0x00]),
        signingPayload: Uint8List(32),
      );

      final encoded = encoder.encodeWithoutPrefix(signedData);
      // After version byte (0x85) and MultiAddress (0x00 + 32 bytes = 33 bytes),
      // the signature prefix is at index 34
      expect(encoded[34], equals(0x00)); // Ed25519 prefix
    });

    test('MultiSignature: Sr25519 (64 bytes, last byte bit7=1) has prefix 0x01', () {
      if (!v16Available) return;
      final encoder = ExtrinsicEncoder(v16ChainInfo);
      if (encoder.extrinsicVersion != 5) return;

      final extensionBuilder = ExtensionBuilder(v16ChainInfo);
      extensionBuilder.setStandardExtensions(
        specVersion: 1000,
        transactionVersion: 1,
        genesisHash: Uint8List(32),
        blockHash: Uint8List(32),
        blockNumber: 100,
        nonce: 0,
        eraPeriod: 64,
      );

      // Sr25519: 64 bytes with last byte bit 7 = 1
      final signature = Uint8List(64);
      signature[63] = 0x80; // bit 7 is 1, so Sr25519

      final signedData = SignedData(
        signer: Uint8List(32),
        signature: signature,
        extensions: Map<String, dynamic>.from(extensionBuilder.extensions),
        additionalSigned: Map<String, dynamic>.from(extensionBuilder.additionalSigned),
        callData: Uint8List.fromList([0x00, 0x00]),
        signingPayload: Uint8List(32),
      );

      final encoded = encoder.encodeWithoutPrefix(signedData);
      expect(encoded[34], equals(0x01)); // Sr25519 prefix
    });

    test('MultiSignature: Ecdsa (65 bytes) has prefix 0x02', () {
      if (!v16Available) return;
      final encoder = ExtrinsicEncoder(v16ChainInfo);
      if (encoder.extrinsicVersion != 5) return;

      final extensionBuilder = ExtensionBuilder(v16ChainInfo);
      extensionBuilder.setStandardExtensions(
        specVersion: 1000,
        transactionVersion: 1,
        genesisHash: Uint8List(32),
        blockHash: Uint8List(32),
        blockNumber: 100,
        nonce: 0,
        eraPeriod: 64,
      );

      // Ecdsa: 65 bytes
      final signedData = SignedData(
        signer: Uint8List(32),
        signature: Uint8List(65),
        extensions: Map<String, dynamic>.from(extensionBuilder.extensions),
        additionalSigned: Map<String, dynamic>.from(extensionBuilder.additionalSigned),
        callData: Uint8List.fromList([0x00, 0x00]),
        signingPayload: Uint8List(32),
      );

      final encoded = encoder.encodeWithoutPrefix(signedData);
      expect(encoded[34], equals(0x02)); // Ecdsa prefix
    });
  });

  // =========================================================================
  // Gap 3: Round-Trip Encode/Decode Tests
  // =========================================================================
  group('Round-Trip Encode/Decode', () {
    // Note: Full UncheckedExtrinsicCodec decode requires valid RuntimeCall data,
    // which requires knowing the exact pallet/call indices. Instead, we verify
    // the structural properties by parsing the version byte from encoded output,
    // and re-encoding from decode result using real chain extrinsics where possible.

    test('V5 bare: version byte and call data preserved', () {
      if (!v16Available) return;
      final encoder = ExtrinsicEncoder(v16ChainInfo);
      if (encoder.extrinsicVersion != 5) return;

      final callData = Uint8List.fromList([0x00, 0x01, 0x02]);
      final encoded = encoder.encodeUnsigned(callData);

      // Strip compact length prefix
      final input = ByteInput(encoded);
      final length = CompactCodec.codec.decode(input);
      final innerBytes = input.readBytes(length);

      // Verify version byte
      expect(innerBytes[0] & 0x3F, equals(5)); // version = 5
      expect(innerBytes[0] & 0x80, equals(0)); // not signed
      expect(innerBytes[0] & 0x40, equals(0)); // not general

      // Verify call data follows the version byte directly (bare)
      expect(innerBytes.sublist(1), equals(callData));
    });

    test('V5 signed: version byte, address, and signature structure preserved', () {
      if (!v16Available) return;
      final encoder = ExtrinsicEncoder(v16ChainInfo);
      if (encoder.extrinsicVersion != 5) return;

      final extensionBuilder = ExtensionBuilder(v16ChainInfo);
      extensionBuilder.setStandardExtensions(
        specVersion: 2000001,
        transactionVersion: 1,
        genesisHash: Uint8List(32),
        blockHash: Uint8List(32),
        blockNumber: 100,
        nonce: 42,
        eraPeriod: 64,
      );

      final signer = Uint8List.fromList(List.generate(32, (i) => i));
      final callData = Uint8List.fromList([0x00, 0x00]);
      final signedData = SignedData(
        signer: signer,
        signature: Uint8List(64),
        extensions: Map<String, dynamic>.from(extensionBuilder.extensions),
        additionalSigned: Map<String, dynamic>.from(extensionBuilder.additionalSigned),
        callData: callData,
        signingPayload: Uint8List(32),
      );

      final encoded = encoder.encode(signedData);

      // Strip compact prefix
      final input = ByteInput(encoded);
      final length = CompactCodec.codec.decode(input);
      final innerBytes = input.readBytes(length);

      // Verify version byte = 0x85 (signed V5)
      expect(innerBytes[0], equals(0x85));

      // Verify MultiAddress::Id prefix and signer
      expect(innerBytes[1], equals(0x00)); // Id variant
      expect(innerBytes.sublist(2, 34), equals(signer));

      // Verify signature follows: prefix byte + 64 bytes
      // Zeroed 64-byte sig with last byte bit7=0 means Ed25519 (prefix 0x00)
      expect(innerBytes[34], equals(0x00)); // Ed25519 prefix
      expect(innerBytes.sublist(35, 99), equals(Uint8List(64)));

      // Verify total length is consistent (compact prefix accounted for)
      expect(length, equals(innerBytes.length));

      // Verify call data appears at the end
      expect(innerBytes[innerBytes.length - 2], equals(0x00));
      expect(innerBytes[innerBytes.length - 1], equals(0x00));
    });

    test('V5 general: version byte and extension version preserved', () {
      if (!v16Available) return;
      final encoder = ExtrinsicEncoder(v16ChainInfo);
      if (encoder.extrinsicVersion != 5) return;

      final extensionBuilder = ExtensionBuilder(v16ChainInfo);
      extensionBuilder.setStandardExtensions(
        specVersion: 2000001,
        transactionVersion: 1,
        genesisHash: Uint8List(32),
        blockHash: Uint8List(32),
        blockNumber: 100,
        nonce: 42,
        eraPeriod: 64,
      );

      final callData = Uint8List.fromList([0x00, 0x01]);
      final encoded = encoder.encodeGeneral(
        callData: callData,
        extensions: extensionBuilder.extensions,
        extensionVersion: 7,
      );

      // Strip compact prefix
      final input = ByteInput(encoded);
      final length = CompactCodec.codec.decode(input);
      final innerBytes = input.readBytes(length);

      // Verify version byte = 0x45 (general V5)
      expect(innerBytes[0], equals(0x45));
      expect(innerBytes[0] & 0x3F, equals(5)); // version = 5
      expect(innerBytes[0] & 0x40, equals(0x40)); // general bit set
      expect(innerBytes[0] & 0x80, equals(0)); // not signed

      // Verify extension version byte
      expect(innerBytes[1], equals(7));

      // Verify call data appears at the end
      expect(innerBytes[innerBytes.length - 2], equals(0x00));
      expect(innerBytes[innerBytes.length - 1], equals(0x01));
    });

    test('V4 signed: version byte and address structure preserved', () {
      if (!v15Available) return;
      final encoder = ExtrinsicEncoder(v15ChainInfo);
      expect(encoder.extrinsicVersion, equals(4));

      final extensionBuilder = ExtensionBuilder(v15ChainInfo);
      extensionBuilder.setStandardExtensions(
        specVersion: 1003003,
        transactionVersion: 1,
        genesisHash: Uint8List(32),
        blockHash: Uint8List(32),
        blockNumber: 100,
        nonce: 0,
        eraPeriod: 64,
      );

      final signer = Uint8List.fromList(List.generate(32, (i) => 0xff - i));
      final signedData = SignedData(
        signer: signer,
        signature: Uint8List(64),
        extensions: Map<String, dynamic>.from(extensionBuilder.extensions),
        additionalSigned: Map<String, dynamic>.from(extensionBuilder.additionalSigned),
        callData: Uint8List.fromList([0x00, 0x00]),
        signingPayload: Uint8List(32),
      );

      final encoded = encoder.encode(signedData);

      // Strip compact prefix
      final input = ByteInput(encoded);
      final length = CompactCodec.codec.decode(input);
      final innerBytes = input.readBytes(length);

      // Verify version byte = 0x84 (signed V4)
      expect(innerBytes[0], equals(0x84));
      expect(innerBytes[0] & 0x3F, equals(4)); // version = 4

      // Verify MultiAddress::Id prefix and signer
      expect(innerBytes[1], equals(0x00)); // Id variant
      expect(innerBytes.sublist(2, 34), equals(signer));

      // Verify call data at end
      expect(innerBytes[innerBytes.length - 2], equals(0x00));
      expect(innerBytes[innerBytes.length - 1], equals(0x00));
    });

    test('Encoding stability: re-encoding produces identical bytes', () {
      if (!v16Available) return;
      final encoder = ExtrinsicEncoder(v16ChainInfo);
      if (encoder.extrinsicVersion != 5) return;

      // Encode unsigned twice with same input, expect same output
      final callData = Uint8List.fromList([0xde, 0xad, 0xbe, 0xef]);
      final encoded1 = encoder.encodeUnsigned(callData);
      final encoded2 = encoder.encodeUnsigned(callData);
      expect(encoded1, equals(encoded2));

      // Encode signed twice with same input, expect same output
      final extensionBuilder = ExtensionBuilder(v16ChainInfo);
      extensionBuilder.setStandardExtensions(
        specVersion: 2000001,
        transactionVersion: 1,
        genesisHash: Uint8List(32),
        blockHash: Uint8List(32),
        blockNumber: 100,
        nonce: 42,
        eraPeriod: 64,
      );

      final signedData = SignedData(
        signer: Uint8List(32),
        signature: Uint8List(64),
        extensions: Map<String, dynamic>.from(extensionBuilder.extensions),
        additionalSigned: Map<String, dynamic>.from(extensionBuilder.additionalSigned),
        callData: callData,
        signingPayload: Uint8List(32),
      );

      final signed1 = encoder.encode(signedData);
      final signed2 = encoder.encode(signedData);
      expect(signed1, equals(signed2));
    });
  });

  // =========================================================================
  // Gap 5: Edge Case & Error Handling Tests
  // =========================================================================
  group('Edge Cases & Error Handling', () {
    test('Signing payload >256 bytes gets hashed to 32 bytes', () {
      if (!v16Available) return;
      final extensionBuilder = ExtensionBuilder(v16ChainInfo);
      extensionBuilder.setStandardExtensions(
        specVersion: 2000001,
        transactionVersion: 1,
        genesisHash: Uint8List(32),
        blockHash: Uint8List(32),
        blockNumber: 100,
        nonce: 0,
        eraPeriod: 64,
      );

      final signingBuilder = SigningBuilder(
        chainInfo: v16ChainInfo,
        extensionBuilder: extensionBuilder,
      );

      // Large call data to push payload over 256 bytes
      final largeCallData = Uint8List.fromList(List.generate(300, (i) => i % 256));

      final payload = signingBuilder.createPayloadToSign(largeCallData);
      // Payload should be hashed to exactly 32 bytes (Blake2b-256)
      expect(payload.length, equals(32));
    });

    test('Signing payload <=256 bytes is returned raw (not hashed)', () {
      if (!v16Available) return;
      final extensionBuilder = ExtensionBuilder(v16ChainInfo);
      extensionBuilder.setStandardExtensions(
        specVersion: 2000001,
        transactionVersion: 1,
        genesisHash: Uint8List(32),
        blockHash: Uint8List(32),
        blockNumber: 100,
        nonce: 0,
        eraPeriod: 64,
      );

      final signingBuilder = SigningBuilder(
        chainInfo: v16ChainInfo,
        extensionBuilder: extensionBuilder,
      );

      // Small call data that keeps total payload <= 256 bytes
      final smallCallData = Uint8List.fromList([0x00, 0x00]);
      final payload = signingBuilder.createPayloadToSign(smallCallData);
      // Payload should be raw bytes (larger than 32 since it includes extensions)
      expect(payload.length, greaterThan(2));
      // If raw, it should NOT be exactly 32 (unless coincidental, but very unlikely)
      // The raw payload includes call data + extensions + additional signed
      // which totals significantly more than 2 bytes but less than 256
      expect(payload.length, lessThanOrEqualTo(256));
    });

    test('Missing extension value throws EncodingError', () {
      if (!v16Available) return;
      final encoder = ExtrinsicEncoder(v16ChainInfo);
      if (encoder.extrinsicVersion != 5) return;

      // Provide empty extensions - encoding should fail
      final signedData = SignedData(
        signer: Uint8List(32),
        signature: Uint8List(64),
        extensions: <String, dynamic>{}, // deliberately empty
        additionalSigned: <String, dynamic>{},
        callData: Uint8List.fromList([0x00, 0x00]),
        signingPayload: Uint8List(32),
      );

      expect(() => encoder.encodeWithoutPrefix(signedData), throwsA(isA<EncodingError>()));
    });
  });
}
