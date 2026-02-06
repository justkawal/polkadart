import 'package:smoldot/smoldot.dart';
import 'package:test/test.dart';

void main() {
  group('SmoldotConfig', () {
    test('creates default config', () {
      const config = SmoldotConfig();
      expect(config.maxLogLevel, equals(3));
      expect(config.maxChains, equals(8));
      expect(config.cpuRateLimit, equals(1.0));
      expect(config.wasmCpuMetering, equals(false));
    });

    test('creates custom config', () {
      const config = SmoldotConfig(
        maxLogLevel: 5,
        maxChains: 16,
        cpuRateLimit: 0.5,
        wasmCpuMetering: true,
      );
      expect(config.maxLogLevel, equals(5));
      expect(config.maxChains, equals(16));
      expect(config.cpuRateLimit, equals(0.5));
      expect(config.wasmCpuMetering, equals(true));
    });

    test('converts to JSON', () {
      const config = SmoldotConfig(maxLogLevel: 4, maxChains: 10);
      final json = config.toJson();
      expect(json['maxLogLevel'], equals(4));
      expect(json['maxChains'], equals(10));
      expect(json['cpuRateLimit'], equals(1.0));
      expect(json['wasmCpuMetering'], equals(false));
    });
  });

  group('AddChainConfig', () {
    test('creates config with required fields', () {
      const config = AddChainConfig(chainSpec: 'test-spec');
      expect(config.chainSpec, equals('test-spec'));
      expect(config.databaseContent, isNull);
      expect(config.potentialRelayChains, isNull);
      expect(config.disableJsonRpc, equals(false));
    });

    test('creates config with all fields', () {
      const config = AddChainConfig(
        chainSpec: 'test-spec',
        databaseContent: 'db-content',
        potentialRelayChains: [1, 2],
        disableJsonRpc: true,
      );
      expect(config.chainSpec, equals('test-spec'));
      expect(config.databaseContent, equals('db-content'));
      expect(config.potentialRelayChains, equals([1, 2]));
      expect(config.disableJsonRpc, equals(true));
    });

    test('converts to JSON', () {
      const config = AddChainConfig(
        chainSpec: 'spec',
        potentialRelayChains: [1],
      );
      final json = config.toJson();
      expect(json['chainSpec'], equals('spec'));
      expect(json['potentialRelayChains'], equals([1]));
      expect(json['disableJsonRpc'], equals(false));
    });
  });

  group('JsonRpcResponse', () {
    test('creates successful response', () {
      const response = JsonRpcResponse(id: '1', result: {'key': 'value'});
      expect(response.id, equals('1'));
      expect(response.result, equals({'key': 'value'}));
      expect(response.error, isNull);
      expect(response.isSuccess, isTrue);
      expect(response.isError, isFalse);
    });

    test('creates error response', () {
      const error = JsonRpcError(code: 123, message: 'test error');
      const response = JsonRpcResponse(id: '1', error: error);
      expect(response.id, equals('1'));
      expect(response.result, isNull);
      expect(response.error, equals(error));
      expect(response.isSuccess, isFalse);
      expect(response.isError, isTrue);
    });

    test('parses from JSON', () {
      final json = {'id': '1', 'result': 'test-result'};
      final response = JsonRpcResponse.fromJson(json);
      expect(response.id, equals('1'));
      expect(response.result, equals('test-result'));
      expect(response.error, isNull);
    });

    test('parses error from JSON', () {
      final json = {
        'id': '1',
        'error': {'code': 123, 'message': 'test error'},
      };
      final response = JsonRpcResponse.fromJson(json);
      expect(response.id, equals('1'));
      expect(response.error, isNotNull);
      expect(response.error!.code, equals(123));
      expect(response.error!.message, equals('test error'));
    });
  });

  group('JsonRpcError', () {
    test('creates error', () {
      const error = JsonRpcError(
        code: 123,
        message: 'test error',
        data: {'detail': 'more info'},
      );
      expect(error.code, equals(123));
      expect(error.message, equals('test error'));
      expect(error.data, equals({'detail': 'more info'}));
    });

    test('converts to JSON', () {
      const error = JsonRpcError(code: 123, message: 'test');
      final json = error.toJson();
      expect(json['code'], equals(123));
      expect(json['message'], equals('test'));
    });

    test('formats toString', () {
      const error = JsonRpcError(code: 123, message: 'test error');
      expect(
        error.toString(),
        equals('JsonRpcError(code: 123, message: test error)'),
      );
    });
  });

  group('ChainInfo', () {
    test('creates chain info', () {
      const info = ChainInfo(
        chainId: 1,
        name: 'Test Chain',
        status: ChainStatus.synced,
        peerCount: 10,
        bestBlockNumber: 1000,
        bestBlockHash: '0x123',
      );
      expect(info.chainId, equals(1));
      expect(info.name, equals('Test Chain'));
      expect(info.status, equals(ChainStatus.synced));
      expect(info.peerCount, equals(10));
      expect(info.bestBlockNumber, equals(1000));
      expect(info.bestBlockHash, equals('0x123'));
    });

    test('converts to JSON', () {
      const info = ChainInfo(
        chainId: 1,
        name: 'Test',
        status: ChainStatus.syncing,
      );
      final json = info.toJson();
      expect(json['chainId'], equals(1));
      expect(json['name'], equals('Test'));
      expect(json['status'], equals('syncing'));
      expect(json['peerCount'], equals(0));
    });
  });

  group('LogLevel', () {
    test('has correct values', () {
      expect(LogLevel.off.value, equals(0));
      expect(LogLevel.error.value, equals(1));
      expect(LogLevel.warn.value, equals(2));
      expect(LogLevel.info.value, equals(3));
      expect(LogLevel.debug.value, equals(4));
      expect(LogLevel.trace.value, equals(5));
    });
  });

  group('LogMessage', () {
    test('parses from JSON', () {
      final json = {
        'level': 3,
        'message': 'test message',
        'target': 'test-target',
        'timestamp': '2024-01-01T00:00:00.000Z',
      };
      final log = LogMessage.fromJson(json);
      expect(log.level, equals(LogLevel.info));
      expect(log.message, equals('test message'));
      expect(log.target, equals('test-target'));
    });

    test('formats toString', () {
      final log = LogMessage(
        level: LogLevel.info,
        message: 'test',
        target: 'target',
        timestamp: DateTime(2024),
      );
      expect(log.toString(), equals('[LogLevel.info] target: test'));
    });
  });

  group('Exceptions', () {
    test('SmoldotException formats message', () {
      final exception = SmoldotException('test error', details: 'more details');
      expect(exception.toString(), contains('test error'));
      expect(exception.toString(), contains('more details'));
    });

    test('ChainException includes chain ID', () {
      final exception = ChainException(1, 'test error');
      expect(exception.toString(), contains('1'));
      expect(exception.toString(), contains('test error'));
    });

    test('JsonRpcException includes error', () {
      const error = JsonRpcError(code: 123, message: 'RPC error');
      final exception = JsonRpcException('test', error: error);
      expect(exception.toString(), contains('123'));
      expect(exception.toString(), contains('RPC error'));
    });
  });

  group('SmoldotPlatform', () {
    test('platform is supported', () {
      expect(SmoldotPlatform.isSupported, isTrue);
    });

    test('has valid library extension', () {
      final ext = SmoldotPlatform.libraryExtension;
      expect(ext, isIn(['.so', '.dylib', '.dll']));
    });

    test('has valid full library name', () {
      final name = SmoldotPlatform.fullLibraryName;
      expect(name, contains('smoldot'));
    });
  });

  // Note: Tests for SmoldotClient, Chain, and actual FFI operations
  // will be added once the Rust FFI bridge is implemented
  group('SmoldotClient', () {
    test('cannot call operations before initialization', () {
      final client = SmoldotClient();
      expect(
        () => client.addChain(const AddChainConfig(chainSpec: 'test')),
        throwsA(isA<SmoldotException>()),
      );
    });
  });
}
