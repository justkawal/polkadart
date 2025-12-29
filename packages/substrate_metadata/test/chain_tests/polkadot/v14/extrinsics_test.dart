@Tags(['chain'])
@Timeout(Duration(minutes: 10))
library;

import 'package:polkadart_scale_codec/polkadart_scale_codec.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

/// Paths resolved relative to monorepo chain directory
final _blocksFile = chainPath('polkadot/v14/blocks.jsonl');
final _runtimeUpgradesFile = chainPath('polkadot/v14/runtime_upgrades_v14.json');
final _metadataDir = chainPath('polkadot/v14');

// Load data at top level so we can generate individual tests
final _blocks = loadBlocks(_blocksFile);
final _runtimeUpgrades = loadRuntimeUpgrades(_runtimeUpgradesFile);
final _upgradeBlockNumbers = _runtimeUpgrades.map((u) => u.blockNumber).toSet();

/// Regex for validating any hex string (0x + hex chars)
final _hexRegex = RegExp(r'^0x[a-fA-F0-9]*$');

void main() {
  group('Polkadot V14 Extrinsics - Input Validation', () {
    for (final block in _blocks) {
      final blockNumber = block['blockNumber'] as int;
      final extrinsics = block['extrinsics'] as List<dynamic>;

      if (extrinsics.isEmpty) continue;

      test('block $blockNumber', () {
        for (var i = 0; i < extrinsics.length; i++) {
          final ext = extrinsics[i];
          expect(ext, isA<String>(), reason: 'extrinsic[$i] should be string');
          expect(
            (ext as String).startsWith('0x'),
            isTrue,
            reason: 'extrinsic[$i] should start with 0x',
          );
          expect(
            ext.length % 2,
            equals(0),
            reason: 'extrinsic[$i] should have even length (valid hex)',
          );
          expect(ext, matches(_hexRegex), reason: 'extrinsic[$i] should be valid hex');
          // Minimum length for an extrinsic: 0x + at least 2 chars (length prefix + content)
          expect(
            ext.length,
            greaterThanOrEqualTo(4),
            reason: 'extrinsic[$i] should have minimum length',
          );
        }
      });
    }
  });

  group('Polkadot V14 Extrinsics - Decode', () {
    for (final block in _blocks) {
      final blockNumber = block['blockNumber'] as int;
      final extrinsics = block['extrinsics'] as List<dynamic>;

      if (extrinsics.isEmpty) continue;

      // Skip exact upgrade boundary blocks (known edge case)
      if (_upgradeBlockNumbers.contains(blockNumber)) continue;

      final extrinsicsHexList = extrinsics.map((e) => e as String).toList();

      // TODO: Remove this skip once extrinsic v5 is supported
      // See: unchecked_extrinsic_codec.dart - needs to support version 5
      if (hasExtrinsicVersion5(extrinsicsHexList)) continue;

      test('block $blockNumber', () {
        final specVersion = findSpecVersionForBlock(blockNumber, _runtimeUpgrades);
        final metadataInfo = getOrLoadMetadata(specVersion, _metadataDir, 'polkadot');

        final vecExtrinsicsHex = encodeExtrinsicsAsVec(extrinsicsHexList);

        final decoded = metadataInfo.extrinsicsCodec.decode(Input.fromHex(vecExtrinsicsHex));

        // Basic structure validation
        expect(decoded, isNotNull, reason: 'decoded extrinsics should not be null');
        expect(decoded, isA<List>(), reason: 'decoded extrinsics should be a list');
        expect(
          decoded.length,
          equals(extrinsicsHexList.length),
          reason: 'decoded count should match input count',
        );

        // Validate each extrinsic is not null
        final extrinsicsList = decoded as List;
        for (var i = 0; i < extrinsicsList.length; i++) {
          final ext = extrinsicsList[i];
          expect(ext, isNotNull, reason: 'extrinsic[$i] should not be null');
        }
      });
    }
  });

  group('Polkadot V14 Extrinsics - Round-trip', () {
    // Test every 10th block for round-trip
    for (var i = 0; i < _blocks.length; i += 10) {
      final block = _blocks[i];
      final blockNumber = block['blockNumber'] as int;
      final extrinsics = block['extrinsics'] as List<dynamic>;

      if (extrinsics.isEmpty) continue;

      // Skip exact upgrade boundary blocks (known edge case)
      if (_upgradeBlockNumbers.contains(blockNumber)) continue;

      final extrinsicsHexList = extrinsics.map((e) => e as String).toList();

      // TODO: Remove this skip once extrinsic v5 is supported
      // See: unchecked_extrinsic_codec.dart - needs to support version 5
      if (hasExtrinsicVersion5(extrinsicsHexList)) continue;

      test('block $blockNumber', () {
        final specVersion = findSpecVersionForBlock(blockNumber, _runtimeUpgrades);
        final metadataInfo = getOrLoadMetadata(specVersion, _metadataDir, 'polkadot');

        final vecExtrinsicsHex = encodeExtrinsicsAsVec(extrinsicsHexList);

        // Decode
        final decoded = metadataInfo.extrinsicsCodec.decode(Input.fromHex(vecExtrinsicsHex));

        // Re-encode
        final output = HexOutput();
        metadataInfo.extrinsicsCodec.encodeTo(decoded, output);
        final reencoded = output.toString();

        expect(
          reencoded,
          equals(vecExtrinsicsHex),
          reason: 'round-trip encoding should match original',
        );
      });
    }
  });
}
