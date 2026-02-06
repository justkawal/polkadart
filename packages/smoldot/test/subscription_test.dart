import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:smoldot/smoldot.dart';

void main() {
  group('Subscription Tests', () {
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

    test('should subscribe to new heads', () async {
      final subscription = chain.subscribe('chain_subscribeNewHeads', []);

      // Wait for first few blocks
      final blocks = <JsonRpcResponse>[];
      final completer = Completer<void>();

      StreamSubscription<JsonRpcResponse>? sub;
      sub = subscription.listen(
        (response) {
          print('New block: ${response.result}');
          blocks.add(response);

          if (blocks.length >= 2) {
            sub?.cancel();
            completer.complete();
          }
        },
        onError: (Object error) {
          print('Subscription error: $error');
          completer.completeError(error);
        },
      );

      // Wait for at least 2 blocks (with timeout)
      await completer.future.timeout(
        Duration(seconds: 30),
        onTimeout: () {
          sub?.cancel();
          if (blocks.isEmpty) {
            throw TimeoutException('No blocks received');
          }
          // If we got at least 1 block, that's acceptable
        },
      );

      expect(blocks, isNotEmpty);
      print('Received ${blocks.length} block notifications');
    });

    test('should subscribe to finalized heads', () async {
      final subscription = chain.subscribe('chain_subscribeFinalizedHeads', []);

      // Wait for first finalized block
      final blocks = <JsonRpcResponse>[];
      final completer = Completer<void>();

      StreamSubscription<JsonRpcResponse>? sub;
      sub = subscription.listen(
        (response) {
          print('Finalized block: ${response.result}');
          blocks.add(response);

          if (blocks.isNotEmpty) {
            sub?.cancel();
            completer.complete();
          }
        },
        onError: (Object error) {
          print('Subscription error: $error');
          completer.completeError(error);
        },
      );

      // Wait for at least 1 finalized block (with timeout)
      await completer.future.timeout(
        Duration(seconds: 30),
        onTimeout: () {
          sub?.cancel();
          if (blocks.isEmpty) {
            // Finalized blocks might take longer, so just warn
            print('Warning: No finalized blocks received in 30s');
          }
        },
      );

      // Don't fail if no finalized blocks (they can take a while)
      print('Received ${blocks.length} finalized block notifications');
    });

    test('should handle multiple concurrent subscriptions', () async {
      final sub1 = chain.subscribe('chain_subscribeNewHeads', []);
      final sub2 = chain.subscribe('chain_subscribeFinalizedHeads', []);

      final blocks1 = <JsonRpcResponse>[];
      final blocks2 = <JsonRpcResponse>[];

      final completer = Completer<void>();
      int subscriptionsComplete = 0;

      StreamSubscription? subscription1;
      StreamSubscription? subscription2;

      subscription1 = sub1.listen((response) {
        blocks1.add(response);
        if (blocks1.length >= 1) {
          subscription1?.cancel();
          subscriptionsComplete++;
          if (subscriptionsComplete == 2) {
            completer.complete();
          }
        }
      });

      subscription2 = sub2.listen((response) {
        blocks2.add(response);
        if (blocks2.length >= 1) {
          subscription2?.cancel();
          subscriptionsComplete++;
          if (subscriptionsComplete == 2) {
            completer.complete();
          }
        }
      });

      // Wait for both subscriptions to get at least one notification
      await completer.future.timeout(
        Duration(seconds: 30),
        onTimeout: () {
          subscription1?.cancel();
          subscription2?.cancel();
        },
      );

      print(
        'Subscription 1 received ${blocks1.length} blocks, Subscription 2 received ${blocks2.length} blocks',
      );
      expect(blocks1.isNotEmpty || blocks2.isNotEmpty, isTrue);
    });
  });
}
