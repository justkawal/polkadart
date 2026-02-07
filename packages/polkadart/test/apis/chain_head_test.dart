import 'dart:async' show StreamController;

import 'package:polkadart/polkadart.dart'
    show
        ChainHeadApi,
        ChainHeadEvent,
        ChainHeadInitialized,
        ChainHeadNewBlock,
        ChainHeadBestBlockChanged,
        ChainHeadFinalized,
        ChainHeadStop,
        ChainHeadEventType,
        ChainHeadOperationBodyDone,
        ChainHeadOperationCallDone,
        ChainHeadOperationStorageItems,
        ChainHeadOperationStorageDone,
        ChainHeadOperationError,
        ChainHeadOperationInaccessible,
        ChainHeadOperationResult,
        StorageQueryItem;
import 'package:test/test.dart';
import './mock_provider.dart' show MockProvider;

void main() {
  group('ChainHeadEvent parsing', () {
    test('parse initialized event', () {
      final event = ChainHeadEvent.fromJson({
        'event': 'initialized',
        'finalizedBlockHashes': [
          '0x91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3',
        ],
        'finalizedBlockRuntime': {
          'type': 'valid',
          'spec': {'specName': 'polkadot', 'specVersion': 1000000},
        },
      });

      expect(event, isA<ChainHeadInitialized>());
      expect(event.type, equals(ChainHeadEventType.initialized));
      final initialized = event as ChainHeadInitialized;
      expect(
        initialized.finalizedBlockHash,
        equals('0x91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3'),
      );
      expect(initialized.finalizedBlockRuntime, isNotNull);
      expect(initialized.finalizedBlockRuntime!['type'], equals('valid'));
    });

    test('parse initialized event with single finalizedBlockHash', () {
      final event = ChainHeadEvent.fromJson({
        'event': 'initialized',
        'finalizedBlockHash': '0xabc123',
      });

      expect(event, isA<ChainHeadInitialized>());
      final initialized = event as ChainHeadInitialized;
      expect(initialized.finalizedBlockHash, equals('0xabc123'));
    });

    test('parse newBlock event', () {
      final event = ChainHeadEvent.fromJson({
        'event': 'newBlock',
        'blockHash': '0xblock123',
        'parentBlockHash': '0xparent456',
        'newRuntime': null,
      });

      expect(event, isA<ChainHeadNewBlock>());
      expect(event.type, equals(ChainHeadEventType.newBlock));
      final newBlock = event as ChainHeadNewBlock;
      expect(newBlock.blockHash, equals('0xblock123'));
      expect(newBlock.parentBlockHash, equals('0xparent456'));
      expect(newBlock.newRuntime, isNull);
    });

    test('parse newBlock event with runtime', () {
      final event = ChainHeadEvent.fromJson({
        'event': 'newBlock',
        'blockHash': '0xblock123',
        'parentBlockHash': '0xparent456',
        'newRuntime': {
          'type': 'valid',
          'spec': {'specVersion': 1000001},
        },
      });

      final newBlock = event as ChainHeadNewBlock;
      expect(newBlock.newRuntime, isNotNull);
      expect(newBlock.newRuntime!['type'], equals('valid'));
    });

    test('parse bestBlockChanged event', () {
      final event = ChainHeadEvent.fromJson({
        'event': 'bestBlockChanged',
        'bestBlockHash': '0xbest789',
      });

      expect(event, isA<ChainHeadBestBlockChanged>());
      expect(event.type, equals(ChainHeadEventType.bestBlockChanged));
      final best = event as ChainHeadBestBlockChanged;
      expect(best.bestBlockHash, equals('0xbest789'));
    });

    test('parse finalized event', () {
      final event = ChainHeadEvent.fromJson({
        'event': 'finalized',
        'finalizedBlockHashes': ['0xfin1', '0xfin2', '0xfin3'],
        'prunedBlockHashes': ['0xpruned1'],
      });

      expect(event, isA<ChainHeadFinalized>());
      expect(event.type, equals(ChainHeadEventType.finalized));
      final finalized = event as ChainHeadFinalized;
      expect(finalized.finalizedBlockHashes, hasLength(3));
      expect(finalized.finalizedBlockHashes[0], equals('0xfin1'));
      expect(finalized.prunedBlockHashes, hasLength(1));
      expect(finalized.prunedBlockHashes[0], equals('0xpruned1'));
    });

    test('parse stop event', () {
      final event = ChainHeadEvent.fromJson({'event': 'stop'});

      expect(event, isA<ChainHeadStop>());
      expect(event.type, equals(ChainHeadEventType.stop));
    });

    test('parse operationBodyDone event', () {
      final event = ChainHeadEvent.fromJson({
        'event': 'operationBodyDone',
        'operationId': 'op-1',
        'value': ['0xaabbccdd', '0x11223344'],
      });

      expect(event, isA<ChainHeadOperationBodyDone>());
      expect(event.type, equals(ChainHeadEventType.operationBodyDone));
      final bodyDone = event as ChainHeadOperationBodyDone;
      expect(bodyDone.operationId, equals('op-1'));
      expect(bodyDone.value, hasLength(2));
      expect(bodyDone.value[0], equals('0xaabbccdd'));
      expect(bodyDone.value[1], equals('0x11223344'));
    });

    test('parse operationBodyDone with empty body', () {
      final event = ChainHeadEvent.fromJson({
        'event': 'operationBodyDone',
        'operationId': 'op-2',
        'value': <String>[],
      });

      final bodyDone = event as ChainHeadOperationBodyDone;
      expect(bodyDone.value, isEmpty);
    });

    test('parse operationCallDone event', () {
      final event = ChainHeadEvent.fromJson({
        'event': 'operationCallDone',
        'operationId': 'op-3',
        'output': '0xdeadbeef',
      });

      expect(event, isA<ChainHeadOperationCallDone>());
      expect(event.type, equals(ChainHeadEventType.operationCallDone));
      final callDone = event as ChainHeadOperationCallDone;
      expect(callDone.operationId, equals('op-3'));
      expect(callDone.output, equals('0xdeadbeef'));
    });

    test('parse operationStorageItems event', () {
      final event = ChainHeadEvent.fromJson({
        'event': 'operationStorageItems',
        'operationId': 'op-4',
        'items': [
          {'key': '0xkey1', 'value': '0xvalue1'},
          {'key': '0xkey2', 'hash': '0xhash2'},
          {'key': '0xkey3', 'value': '0xvalue3', 'hash': '0xhash3'},
          {'key': '0xkey4'},
        ],
      });

      expect(event, isA<ChainHeadOperationStorageItems>());
      expect(event.type, equals(ChainHeadEventType.operationStorageItems));
      final storageItems = event as ChainHeadOperationStorageItems;
      expect(storageItems.operationId, equals('op-4'));
      expect(storageItems.items, hasLength(4));

      expect(storageItems.items[0].key, equals('0xkey1'));
      expect(storageItems.items[0].value, equals('0xvalue1'));
      expect(storageItems.items[0].hash, isNull);

      expect(storageItems.items[1].key, equals('0xkey2'));
      expect(storageItems.items[1].value, isNull);
      expect(storageItems.items[1].hash, equals('0xhash2'));

      expect(storageItems.items[2].key, equals('0xkey3'));
      expect(storageItems.items[2].value, equals('0xvalue3'));
      expect(storageItems.items[2].hash, equals('0xhash3'));

      expect(storageItems.items[3].key, equals('0xkey4'));
      expect(storageItems.items[3].value, isNull);
      expect(storageItems.items[3].hash, isNull);
    });

    test('parse operationStorageDone event', () {
      final event = ChainHeadEvent.fromJson({
        'event': 'operationStorageDone',
        'operationId': 'op-5',
      });

      expect(event, isA<ChainHeadOperationStorageDone>());
      expect(event.type, equals(ChainHeadEventType.operationStorageDone));
      final storageDone = event as ChainHeadOperationStorageDone;
      expect(storageDone.operationId, equals('op-5'));
    });

    test('parse operationError event', () {
      final event = ChainHeadEvent.fromJson({
        'event': 'operationError',
        'operationId': 'op-6',
        'error': 'block pruned before operation could complete',
      });

      expect(event, isA<ChainHeadOperationError>());
      expect(event.type, equals(ChainHeadEventType.operationError));
      final opError = event as ChainHeadOperationError;
      expect(opError.operationId, equals('op-6'));
      expect(opError.error, equals('block pruned before operation could complete'));
    });

    test('parse operationInaccessible event', () {
      final event = ChainHeadEvent.fromJson({
        'event': 'operationInaccessible',
        'operationId': 'op-7',
      });

      expect(event, isA<ChainHeadOperationInaccessible>());
      expect(event.type, equals(ChainHeadEventType.operationInaccessible));
      final inaccessible = event as ChainHeadOperationInaccessible;
      expect(inaccessible.operationId, equals('op-7'));
    });

    test('unknown event throws', () {
      expect(() => ChainHeadEvent.fromJson({'event': 'unknown'}), throwsA(isA<Exception>()));
    });
  });

  group('ChainHeadOperationResult', () {
    test('parse started result', () {
      final result = ChainHeadOperationResult.fromJson({
        'result': 'started',
        'operationId': 'op-42',
      });

      expect(result.isStarted, isTrue);
      expect(result.isLimitReached, isFalse);
      expect(result.operationId, equals('op-42'));
    });

    test('parse limitReached result', () {
      final result = ChainHeadOperationResult.fromJson({'result': 'limitReached'});

      expect(result.isStarted, isFalse);
      expect(result.isLimitReached, isTrue);
      expect(result.operationId, isNull);
    });
  });

  group('StorageQueryItem', () {
    test('toJson serializes correctly', () {
      final item = StorageQueryItem(key: '0xstorage_key', queryType: 'value');

      final json = item.toJson();
      expect(json['key'], equals('0xstorage_key'));
      expect(json['type'], equals('value'));
    });

    test('different query types', () {
      expect(StorageQueryItem(key: '0x01', queryType: 'hash').toJson()['type'], equals('hash'));
      expect(
        StorageQueryItem(key: '0x01', queryType: 'closestDescendantMerkleValue').toJson()['type'],
        equals('closestDescendantMerkleValue'),
      );
      expect(
        StorageQueryItem(key: '0x01', queryType: 'descendantsValues').toJson()['type'],
        equals('descendantsValues'),
      );
    });
  });

  // =========================================================================
  // Gap 7: ChainHead Subscription Flow Tests
  // =========================================================================
  group('ChainHead subscription flow', () {
    test('follow emits initialized event on stream', () async {
      final provider = MockProvider(null);
      final api = ChainHeadApi(provider);

      final eventController = StreamController<Map<String, dynamic>>();

      provider.setSubscriptionCallback('chainHead_v1_follow', (params, state) {
        // Verify withRuntime param is forwarded
        expect(params, equals([true]));
        return ('sub-1', eventController.stream);
      });

      // Need unfollow mock for the onCancel callback
      provider.setMethodCallback('chainHead_v1_unfollow', (params, state) {
        return null;
      });

      final session = await api.follow(withRuntime: true);
      expect(session.followSubscriptionId, equals('sub-1'));
      expect(session.isActive, isTrue);

      // Emit an initialized event
      eventController.add({'event': 'initialized', 'finalizedBlockHash': '0xabc123'});

      final event = await session.stream.first;
      expect(event, isA<ChainHeadInitialized>());
      expect((event as ChainHeadInitialized).finalizedBlockHash, equals('0xabc123'));

      await eventController.close();
      await provider.closeAllSubscriptions();
    });

    test('follow streams full event sequence', () async {
      final provider = MockProvider(null);
      final api = ChainHeadApi(provider);

      final eventController = StreamController<Map<String, dynamic>>();

      provider.setSubscriptionCallback(
        'chainHead_v1_follow',
        (params, state) => ('sub-2', eventController.stream),
      );

      provider.setMethodCallback('chainHead_v1_unfollow', (params, state) {
        return null;
      });

      final session = await api.follow(withRuntime: false);

      // Collect events
      final events = <ChainHeadEvent>[];
      final sub = session.stream.listen((e) => events.add(e));

      // Emit a realistic event sequence
      eventController.add({'event': 'initialized', 'finalizedBlockHash': '0xblock0'});
      eventController.add({
        'event': 'newBlock',
        'blockHash': '0xblock1',
        'parentBlockHash': '0xblock0',
        'newRuntime': null,
      });
      eventController.add({'event': 'bestBlockChanged', 'bestBlockHash': '0xblock1'});
      eventController.add({
        'event': 'finalized',
        'finalizedBlockHashes': ['0xblock1'],
        'prunedBlockHashes': [],
      });

      // Give stream time to process
      await Future.delayed(Duration(milliseconds: 50));

      expect(events, hasLength(4));
      expect(events[0], isA<ChainHeadInitialized>());
      expect(events[1], isA<ChainHeadNewBlock>());
      expect(events[2], isA<ChainHeadBestBlockChanged>());
      expect(events[3], isA<ChainHeadFinalized>());

      await sub.cancel();
      await eventController.close();
      await provider.closeAllSubscriptions();
    });

    test('header sends correct RPC method with followSubscriptionId', () async {
      final provider = MockProvider(null);
      final api = ChainHeadApi(provider);

      final eventController = StreamController<Map<String, dynamic>>();

      provider.setSubscriptionCallback(
        'chainHead_v1_follow',
        (params, state) => ('sub-3', eventController.stream),
      );

      provider.setMethodCallback('chainHead_v1_unfollow', (params, state) {
        return null;
      });

      provider.setMethodCallback('chainHead_v1_header', (params, state) {
        expect(params[0], equals('sub-3'));
        expect(params[1], equals('0xblock123'));
        return '0xscale_encoded_header';
      });

      final session = await api.follow();
      final header = await session.header('0xblock123');
      expect(header, equals('0xscale_encoded_header'));

      await eventController.close();
      await provider.closeAllSubscriptions();
    });

    test('body sends correct RPC method with followSubscriptionId', () async {
      final provider = MockProvider(null);
      final api = ChainHeadApi(provider);

      final eventController = StreamController<Map<String, dynamic>>();

      provider.setSubscriptionCallback(
        'chainHead_v1_follow',
        (params, state) => ('sub-4', eventController.stream),
      );

      provider.setMethodCallback('chainHead_v1_unfollow', (params, state) {
        return null;
      });

      provider.setMethodCallback('chainHead_v1_body', (params, state) {
        expect(params[0], equals('sub-4'));
        expect(params[1], equals('0xblock456'));
        return {'result': 'started', 'operationId': 'op-body-1'};
      });

      final session = await api.follow();
      final result = await session.body('0xblock456');
      expect(result.isStarted, isTrue);
      expect(result.operationId, equals('op-body-1'));

      await eventController.close();
      await provider.closeAllSubscriptions();
    });

    test('storage sends correct params including items', () async {
      final provider = MockProvider(null);
      final api = ChainHeadApi(provider);

      final eventController = StreamController<Map<String, dynamic>>();

      provider.setSubscriptionCallback(
        'chainHead_v1_follow',
        (params, state) => ('sub-5', eventController.stream),
      );

      provider.setMethodCallback('chainHead_v1_unfollow', (params, state) {
        return null;
      });

      provider.setMethodCallback('chainHead_v1_storage', (params, state) {
        expect(params[0], equals('sub-5'));
        expect(params[1], equals('0xblock789'));
        // Items should be serialized
        expect(params[2], isList);
        expect((params[2] as List).length, equals(1));
        expect((params[2] as List)[0]['key'], equals('0xkey1'));
        expect((params[2] as List)[0]['type'], equals('value'));
        return {'result': 'started', 'operationId': 'op-storage-1'};
      });

      final session = await api.follow();
      final result = await session.storage('0xblock789', [
        StorageQueryItem(key: '0xkey1', queryType: 'value'),
      ]);
      expect(result.isStarted, isTrue);
      expect(result.operationId, equals('op-storage-1'));

      await eventController.close();
      await provider.closeAllSubscriptions();
    });

    test('call sends correct params', () async {
      final provider = MockProvider(null);
      final api = ChainHeadApi(provider);

      final eventController = StreamController<Map<String, dynamic>>();

      provider.setSubscriptionCallback(
        'chainHead_v1_follow',
        (params, state) => ('sub-6', eventController.stream),
      );

      provider.setMethodCallback('chainHead_v1_unfollow', (params, state) {
        return null;
      });

      provider.setMethodCallback('chainHead_v1_call', (params, state) {
        expect(params[0], equals('sub-6'));
        expect(params[1], equals('0xblock_abc'));
        expect(params[2], equals('Metadata_metadata'));
        expect(params[3], equals('0x'));
        return {'result': 'started', 'operationId': 'op-call-1'};
      });

      final session = await api.follow();
      final result = await session.call('0xblock_abc', 'Metadata_metadata', '0x');
      expect(result.isStarted, isTrue);
      expect(result.operationId, equals('op-call-1'));

      await eventController.close();
      await provider.closeAllSubscriptions();
    });

    test('unfollow makes session inactive', () async {
      final provider = MockProvider(null);
      final api = ChainHeadApi(provider);

      final eventController = StreamController<Map<String, dynamic>>();
      bool unfollowCalled = false;

      provider.setSubscriptionCallback(
        'chainHead_v1_follow',
        (params, state) => ('sub-7', eventController.stream),
      );

      provider.setMethodCallback('chainHead_v1_unfollow', (params, state) {
        unfollowCalled = true;
        expect(params[0], equals('sub-7'));
        return null;
      });

      final session = await api.follow();
      expect(session.isActive, isTrue);

      await session.unfollow();
      expect(session.isActive, isFalse);
      expect(unfollowCalled, isTrue);

      await eventController.close();
      await provider.closeAllSubscriptions();
    });

    test('double unfollow is a no-op', () async {
      final provider = MockProvider(null);
      final api = ChainHeadApi(provider);

      final eventController = StreamController<Map<String, dynamic>>();
      int unfollowCount = 0;

      provider.setSubscriptionCallback(
        'chainHead_v1_follow',
        (params, state) => ('sub-8', eventController.stream),
      );

      provider.setMethodCallback('chainHead_v1_unfollow', (params, state) {
        unfollowCount++;
        return null;
      });

      final session = await api.follow();
      await session.unfollow();
      await session.unfollow(); // second call should be no-op
      expect(unfollowCount, equals(1));

      await eventController.close();
      await provider.closeAllSubscriptions();
    });

    test('operation on unfollowed session throws StateError', () async {
      final provider = MockProvider(null);
      final api = ChainHeadApi(provider);

      final eventController = StreamController<Map<String, dynamic>>();

      provider.setSubscriptionCallback(
        'chainHead_v1_follow',
        (params, state) => ('sub-9', eventController.stream),
      );

      provider.setMethodCallback('chainHead_v1_unfollow', (params, state) {
        return null;
      });

      final session = await api.follow();
      await session.unfollow();

      expect(() => session.header('0xblock'), throwsA(isA<StateError>()));
      expect(() => session.body('0xblock'), throwsA(isA<StateError>()));
      expect(() => session.storage('0xblock', []), throwsA(isA<StateError>()));
      expect(() => session.call('0xblock', 'fn', '0x'), throwsA(isA<StateError>()));
      expect(() => session.unpin(['0xblock']), throwsA(isA<StateError>()));

      await eventController.close();
      await provider.closeAllSubscriptions();
    });
  });
}
