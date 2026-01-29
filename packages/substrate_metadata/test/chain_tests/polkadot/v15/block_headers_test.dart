@Tags(['chain'])
@Timeout(Duration(minutes: 5))
library;

import 'package:test/test.dart';

import '../../test_helpers.dart';

/// Path resolved relative to monorepo chain directory
final _blocksFile = chainPath('polkadot/v15/blocks.jsonl');

// Load data at top level so we can generate individual tests
final _blocks = loadBlocks(_blocksFile);

/// Regex for validating 32-byte hex hash (0x + 64 hex chars)
final _hash32ByteRegex = RegExp(r'^0x[a-fA-F0-9]{64}$');

/// Regex for validating any hex string (0x + even number of hex chars)
final _hexRegex = RegExp(r'^0x[a-fA-F0-9]*$');

void main() {
  group('Polkadot V15 Block Headers - Required Fields', () {
    for (final block in _blocks) {
      final blockNumber = block['blockNumber'] as int;

      test('block $blockNumber', () {
        // Validate block structure
        expect(block.containsKey('blockNumber'), isTrue, reason: 'missing blockNumber');
        expect(block.containsKey('extrinsics'), isTrue, reason: 'missing extrinsics');
        expect(block.containsKey('header'), isTrue, reason: 'missing header');
        expect(block['blockNumber'], isA<int>(), reason: 'blockNumber should be int');
        expect(block['extrinsics'], isA<List>(), reason: 'extrinsics should be a list');

        final header = block['header'] as Map<String, dynamic>;

        // Validate header field presence
        expect(header.containsKey('parentHash'), isTrue, reason: 'missing parentHash');
        expect(header.containsKey('number'), isTrue, reason: 'missing number');
        expect(header.containsKey('stateRoot'), isTrue, reason: 'missing stateRoot');
        expect(header.containsKey('extrinsicsRoot'), isTrue, reason: 'missing extrinsicsRoot');
        expect(header.containsKey('digest'), isTrue, reason: 'missing digest');

        // Validate hash fields are proper 32-byte hex strings
        final parentHash = header['parentHash'] as String;
        expect(parentHash, isA<String>(), reason: 'parentHash should be string');
        expect(
          parentHash.length,
          equals(66),
          reason: 'parentHash should be 66 chars (0x + 64 hex)',
        );
        expect(
          parentHash,
          matches(_hash32ByteRegex),
          reason: 'parentHash should be valid 32-byte hex',
        );

        final stateRoot = header['stateRoot'] as String;
        expect(stateRoot, isA<String>(), reason: 'stateRoot should be string');
        expect(stateRoot.length, equals(66), reason: 'stateRoot should be 66 chars (0x + 64 hex)');
        expect(
          stateRoot,
          matches(_hash32ByteRegex),
          reason: 'stateRoot should be valid 32-byte hex',
        );

        final extrinsicsRoot = header['extrinsicsRoot'] as String;
        expect(extrinsicsRoot, isA<String>(), reason: 'extrinsicsRoot should be string');
        expect(
          extrinsicsRoot.length,
          equals(66),
          reason: 'extrinsicsRoot should be 66 chars (0x + 64 hex)',
        );
        expect(
          extrinsicsRoot,
          matches(_hash32ByteRegex),
          reason: 'extrinsicsRoot should be valid 32-byte hex',
        );

        // Validate number field is valid hex and matches blockNumber
        final numberHex = header['number'] as String;
        expect(numberHex, isA<String>(), reason: 'number should be string');
        expect(numberHex, matches(_hexRegex), reason: 'number should be valid hex');
        final headerNumber = int.parse(numberHex.substring(2), radix: 16);
        expect(headerNumber, equals(blockNumber), reason: 'header number mismatch');

        // Validate digest structure
        final digest = header['digest'] as Map<String, dynamic>;
        expect(digest.containsKey('logs'), isTrue, reason: 'digest missing logs');
        expect(digest['logs'], isA<List>(), reason: 'digest logs should be a list');
      });
    }
  });

  group('Polkadot V15 Block Headers - Digest Logs', () {
    for (final block in _blocks) {
      final blockNumber = block['blockNumber'] as int;

      test('block $blockNumber', () {
        final header = block['header'] as Map<String, dynamic>;
        final digest = header['digest'] as Map<String, dynamic>;
        final logs = digest['logs'] as List<dynamic>;

        for (var i = 0; i < logs.length; i++) {
          final log = logs[i];
          expect(log, isA<String>(), reason: 'log[$i] is not a string');
          expect((log as String).startsWith('0x'), isTrue, reason: 'log[$i] should start with 0x');
          expect(log.length % 2, equals(0), reason: 'log[$i] should have even length (valid hex)');
          expect(log, matches(_hexRegex), reason: 'log[$i] should be valid hex');
        }
      });
    }
  });

  group('Polkadot V15 Block Headers - Extrinsics Format', () {
    for (final block in _blocks) {
      final blockNumber = block['blockNumber'] as int;
      final extrinsics = block['extrinsics'] as List<dynamic>;

      // Skip empty blocks
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
        }
      });
    }
  });

  test('block numbers are in ascending order', () {
    int lastBlockNumber = -1;

    for (final block in _blocks) {
      final blockNumber = block['blockNumber'] as int;
      expect(
        blockNumber,
        greaterThan(lastBlockNumber),
        reason: 'Block numbers not in ascending order at $blockNumber',
      );
      lastBlockNumber = blockNumber;
    }
  });
}
