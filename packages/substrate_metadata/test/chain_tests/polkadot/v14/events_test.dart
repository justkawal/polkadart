@Tags(['chain'])
@Timeout(Duration(minutes: 10))
library;

import 'package:polkadart_scale_codec/polkadart_scale_codec.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

/// Paths resolved relative to monorepo chain directory
final _eventsFile = chainPath('polkadot/v14/events.jsonl');
final _runtimeUpgradesFile = chainPath('polkadot/v14/runtime_upgrades_v14.json');
final _metadataDir = chainPath('polkadot/v14');

// Load data at top level so we can generate individual tests
final _events = loadEvents(_eventsFile);
final _runtimeUpgrades = loadRuntimeUpgrades(_runtimeUpgradesFile);
final _upgradeBlockNumbers = _runtimeUpgrades.map((u) => u.blockNumber).toSet();

/// Regex for validating any hex string (0x + hex chars)
final _hexRegex = RegExp(r'^0x[a-fA-F0-9]*$');

void main() {
  group('Polkadot V14 Events - Input Validation', () {
    for (final eventRecord in _events) {
      final blockNumber = eventRecord['blockNumber'] as int;
      final eventsHex = eventRecord['events'] as String;

      test('block $blockNumber', () {
        // Validate input hex format
        expect(eventsHex, isA<String>(), reason: 'events should be string');
        expect(eventsHex.startsWith('0x'), isTrue, reason: 'events should start with 0x');
        expect(
          eventsHex.length % 2,
          equals(0),
          reason: 'events should have even length (valid hex)',
        );
        expect(eventsHex, matches(_hexRegex), reason: 'events should be valid hex');
      });
    }
  });

  group('Polkadot V14 Events - Decode', () {
    for (final eventRecord in _events) {
      final blockNumber = eventRecord['blockNumber'] as int;
      final eventsHex = eventRecord['events'] as String;

      // Skip exact upgrade boundary blocks (known edge case)
      if (_upgradeBlockNumbers.contains(blockNumber)) continue;

      test('block $blockNumber', () {
        final specVersion = findSpecVersionForBlock(blockNumber, _runtimeUpgrades);
        final metadataInfo = getOrLoadMetadata(specVersion, _metadataDir, 'polkadot');

        final decoded = metadataInfo.eventsCodec.decode(Input.fromHex(eventsHex));

        // Basic structure validation
        expect(decoded, isNotNull, reason: 'decoded events should not be null');
        expect(decoded, isA<List>(), reason: 'decoded events should be a list');

        // Validate each event record is not null
        final eventsList = decoded as List;
        for (var i = 0; i < eventsList.length; i++) {
          final event = eventsList[i];
          expect(event, isNotNull, reason: 'event[$i] should not be null');
        }
      });
    }
  });

  group('Polkadot V14 Events - Round-trip', () {
    // Test all blocks for round-trip
    for (var i = 0; i < _events.length; i++) {
      final eventRecord = _events[i];
      final blockNumber = eventRecord['blockNumber'] as int;
      final eventsHex = eventRecord['events'] as String;

      // Skip exact upgrade boundary blocks (known edge case)
      if (_upgradeBlockNumbers.contains(blockNumber)) continue;

      test('block $blockNumber', () {
        final specVersion = findSpecVersionForBlock(blockNumber, _runtimeUpgrades);
        final metadataInfo = getOrLoadMetadata(specVersion, _metadataDir, 'polkadot');

        // Decode
        final decoded = metadataInfo.eventsCodec.decode(Input.fromHex(eventsHex));

        // Re-encode
        final output = HexOutput();
        metadataInfo.eventsCodec.encodeTo(decoded, output);
        final reencoded = output.toString();

        expect(reencoded, equals(eventsHex), reason: 'round-trip encoding should match original');
      });
    }
  });
}
