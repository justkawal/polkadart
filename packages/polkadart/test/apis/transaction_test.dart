import 'dart:async' show StreamController;
import 'dart:typed_data' show Uint8List;

import 'package:polkadart/polkadart.dart' show TransactionApi;
import 'package:test/test.dart';
import './mock_provider.dart' show MockProvider;

void main() {
  group('TransactionApi', () {
    test('stop sends correct RPC method', () {
      final provider = MockProvider(null);
      final api = TransactionApi(provider);

      provider.setMethodCallback('transaction_v1_stop', (params, state) {
        expect(params.length, equals(1));
        expect(params[0], equals('op-123'));
        return null;
      });

      expect(api.stop('op-123'), completes);
    });

    test('stop handles errors', () {
      final provider = MockProvider(null);
      final api = TransactionApi(provider);

      provider.setMethodCallback('transaction_v1_stop', (params, state) {
        return null;
      });

      expect(api.stop('nonexistent-op'), completes);
    });
  });

  // =========================================================================
  // Gap 7: Transaction Subscription Flow Tests
  // =========================================================================
  group('TransactionApi subscription flow', () {
    test('broadcast returns operationId and event stream', () async {
      final provider = MockProvider(null);
      final api = TransactionApi(provider);

      final eventController = StreamController<dynamic>();

      provider.setSubscriptionCallback('transaction_v1_broadcast', (params, state) {
        // Verify the extrinsic hex is passed
        expect(params, hasLength(1));
        expect(params[0], startsWith('0x'));
        return ('tx-sub-1', eventController.stream);
      });

      // Need stop mock for the onCancel callback
      provider.setMethodCallback('transaction_v1_stop', (params, state) {
        return null;
      });

      final extrinsic = Uint8List.fromList([0x04, 0x00, 0x01]);
      final broadcast = await api.broadcast(extrinsic);

      expect(broadcast.operationId, equals('tx-sub-1'));

      await eventController.close();
      await provider.closeAllSubscriptions();
    });

    test('broadcast stream yields events', () async {
      final provider = MockProvider(null);
      final api = TransactionApi(provider);

      final eventController = StreamController<dynamic>();

      provider.setSubscriptionCallback(
        'transaction_v1_broadcast',
        (params, state) => ('tx-sub-2', eventController.stream),
      );

      provider.setMethodCallback('transaction_v1_stop', (params, state) {
        return null;
      });

      final extrinsic = Uint8List.fromList([0x04, 0x00, 0x01]);
      final broadcast = await api.broadcast(extrinsic);

      final events = <dynamic>[];
      final sub = broadcast.stream.listen((e) => events.add(e));

      eventController.add({'event': 'broadcasted'});
      eventController.add({'event': 'bestChainBlockIncluded', 'block': null});

      await Future.delayed(Duration(milliseconds: 50));

      expect(events, hasLength(2));
      expect((events[0] as Map)['event'], equals('broadcasted'));
      expect((events[1] as Map)['event'], equals('bestChainBlockIncluded'));

      await sub.cancel();
      await eventController.close();
      await provider.closeAllSubscriptions();
    });

    test('broadcast passes hex-encoded extrinsic', () async {
      final provider = MockProvider(null);
      final api = TransactionApi(provider);

      final eventController = StreamController<dynamic>();
      String? capturedHex;

      provider.setSubscriptionCallback('transaction_v1_broadcast', (params, state) {
        capturedHex = params[0] as String;
        return ('tx-sub-3', eventController.stream);
      });

      provider.setMethodCallback('transaction_v1_stop', (params, state) {
        return null;
      });

      final extrinsic = Uint8List.fromList([0xde, 0xad, 0xbe, 0xef]);
      await api.broadcast(extrinsic);

      expect(capturedHex, equals('0xdeadbeef'));

      await eventController.close();
      await provider.closeAllSubscriptions();
    });

    test('broadcast onCancel calls transaction_v1_stop', () async {
      final provider = MockProvider(null);
      final api = TransactionApi(provider);

      final eventController = StreamController<dynamic>();
      String? stoppedId;

      provider.setSubscriptionCallback(
        'transaction_v1_broadcast',
        (params, state) => ('tx-sub-4', eventController.stream),
      );

      provider.setMethodCallback('transaction_v1_stop', (params, state) {
        stoppedId = params[0] as String;
        return null;
      });

      final extrinsic = Uint8List.fromList([0x04, 0x00]);
      final broadcast = await api.broadcast(extrinsic);

      // Listen and then cancel to trigger onCancel
      final sub = broadcast.stream.listen((_) {});
      await sub.cancel();

      // Give time for the async onCancel callback
      await Future.delayed(Duration(milliseconds: 50));

      expect(stoppedId, equals('tx-sub-4'));

      await eventController.close();
      await provider.closeAllSubscriptions();
    });
  });
}
