import 'dart:io';
import 'package:test/test.dart';
import 'package:smoldot/smoldot.dart';

void main() {
  group('SmoldotClient Basic Tests', () {
    late SmoldotClient client;

    setUp(() {
      client = SmoldotClient(config: SmoldotConfig(maxLogLevel: 3));
    });

    tearDown(() async {
      if (client.isInitialized) {
        await client.dispose();
      }
    });

    test('should initialize client', () async {
      await client.initialize();
      expect(client.isInitialized, isTrue);
    });

    test('should fail to initialize twice', () async {
      await client.initialize();
      expect(() => client.initialize(), throwsA(isA<SmoldotException>()));
    });

    test('should create and add chain with Westend spec', () async {
      await client.initialize();

      // Load real Westend chain spec from fixtures
      final westendSpecFile = File('test/fixtures/westend.json');
      expect(
        westendSpecFile.existsSync(),
        isTrue,
        reason:
            'Westend chain spec not found. Run: curl -o test/fixtures/westend.json https://raw.githubusercontent.com/smol-dot/smoldot/main/demo-chain-specs/westend.json',
      );

      final westendSpec = await westendSpecFile.readAsString();

      // This should work with the callback-based FFI and real chain spec
      final chain = await client.addChain(
        AddChainConfig(chainSpec: westendSpec),
      );

      expect(chain, isNotNull);
      expect(chain.chainId, greaterThan(0));
      print('✓ Chain created with ID: ${chain.chainId}');
      print('✓ Successfully loaded Westend chain spec');
    });
  });
}
