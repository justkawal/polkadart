import 'dart:io';
import 'package:test/test.dart';
import 'package:smoldot/smoldot.dart';

void main() {
  group('JSON-RPC Tests', () {
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

    test('should make system_chain request', () async {
      final response = await chain.request('system_chain', []);
      expect(response, isNotNull);
      expect(response.isSuccess, isTrue);
      expect(response.result, equals('Westend'));
    });

    test('should make system_version request', () async {
      final response = await chain.request('system_version', []);
      expect(response, isNotNull);
      expect(response.isSuccess, isTrue);
      expect(response.result, isNotEmpty);
    });

    test('should make system_name request', () async {
      final response = await chain.request('system_name', []);
      expect(response, isNotNull);
      expect(response.isSuccess, isTrue);
      expect(response.result, isNotEmpty);
    });

    test('should make system_properties request', () async {
      final response = await chain.request('system_properties', []);
      expect(response, isNotNull);
      expect(response.isSuccess, isTrue);
      expect(response.result, isA<Map<String, dynamic>>());
    });

    test('should make chain_getFinalizedHead request', () async {
      final response = await chain.request('chain_getFinalizedHead', []);
      expect(response, isNotNull);
      expect(response.isSuccess, isTrue);
      expect(response.result, isA<String>());
      expect((response.result as String).startsWith('0x'), isTrue);
    });

    test('should handle multiple concurrent requests', () async {
      // Test concurrent requests with tokio::sync::Mutex fix
      final futures = [
        chain.request('system_chain', []),
        chain.request('system_version', []),
        chain.request('system_name', []),
        chain.request('system_properties', []),
      ];

      final responses = await Future.wait(futures);

      expect(responses.length, equals(4));
      expect(responses[0].result, equals('Westend'));
      expect(responses[1].isSuccess, isTrue);
      expect(responses[2].isSuccess, isTrue);
      expect(responses[3].isSuccess, isTrue);
    });

    test('should handle request with parameters', () async {
      // Get block hash at height 0 (genesis)
      final response = await chain.request('chain_getBlockHash', [0]);
      expect(response, isNotNull);
      expect(response.isSuccess, isTrue);
      expect(response.result, isA<String>());
      expect((response.result as String).startsWith('0x'), isTrue);
    });
  });
}
