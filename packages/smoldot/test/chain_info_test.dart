import 'dart:io';
import 'package:test/test.dart';
import 'package:smoldot/smoldot.dart';

void main() {
  group('Chain Info Tests', () {
    late SmoldotClient client;
    late Chain chain;

    setUpAll(() async {
      client = SmoldotClient(config: SmoldotConfig(maxLogLevel: 3));
      await client.initialize();

      // Load Westend chain spec
      final westendSpecFile = File('test/fixtures/westend.json');
      expect(
        westendSpecFile.existsSync(),
        isTrue,
        reason:
            'Westend chain spec not found. Run: curl -o test/fixtures/westend.json https://raw.githubusercontent.com/smol-dot/smoldot/main/demo-chain-specs/westend.json',
      );

      final westendSpec = await westendSpecFile.readAsString();
      chain = await client.addChain(AddChainConfig(chainSpec: westendSpec));
    });

    tearDownAll(() async {
      if (client.isInitialized) {
        await client.dispose();
      }
    });

    test('should get chain info', () async {
      final info = await chain.getInfo();

      expect(info, isNotNull);
      expect(info.chainId, equals(chain.chainId));
      expect(info.name, equals('Westend'));
      expect(info.status, isA<ChainStatus>());
      expect(info.peerCount, greaterThanOrEqualTo(0));
      expect(info.bestBlockNumber, isNotNull);
      expect(info.bestBlockHash, isNotNull);

      print('Chain Info:');
      print('  Name: ${info.name}');
      print('  Status: ${info.status}');
      print('  Peers: ${info.peerCount}');
      print('  Block: ${info.bestBlockNumber}');
      print('  Hash: ${info.bestBlockHash}');
    });

    test('should get best block number', () async {
      final blockNumber = await chain.getBestBlockNumber();

      expect(blockNumber, isNotNull);
      expect(blockNumber!, greaterThan(0));
      print('Best block number: $blockNumber');
    });

    test('should get best block hash', () async {
      final blockHash = await chain.getBestBlockHash();

      expect(blockHash, isNotNull);
      expect(blockHash!, startsWith('0x'));
      expect(blockHash.length, equals(66)); // 0x + 64 hex characters
      print('Best block hash: $blockHash');
    });

    test('should get peer count', () async {
      final peerCount = await chain.getPeerCount();

      expect(peerCount, greaterThanOrEqualTo(0));
      print('Peer count: $peerCount');
    });

    test('should get chain status', () async {
      final status = await chain.getStatus();

      expect(status, isA<ChainStatus>());
      print('Chain status: $status');
    });

    test('should handle multiple concurrent chain info requests', () async {
      final futures = [
        chain.getBestBlockNumber(),
        chain.getBestBlockHash(),
        chain.getPeerCount(),
        chain.getStatus(),
      ];

      final results = await Future.wait(futures);

      expect(results[0], isNotNull); // block number
      expect(results[1], isNotNull); // block hash
      expect(results[2], greaterThanOrEqualTo(0)); // peer count
      expect(results[3], isA<ChainStatus>()); // status

      print('Concurrent requests completed successfully');
    });
  });
}
