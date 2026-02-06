import 'package:polkadart/polkadart.dart' show ChainSpecApi;
import 'package:test/test.dart';
import './mock_provider.dart' show MockProvider;

void main() {
  group('ChainSpecApi', () {
    test('genesisHash', () {
      final provider = MockProvider(null);
      final api = ChainSpecApi(provider);
      provider.setMethodCallback(
        'chainSpec_v1_genesisHash',
        (params, state) => '0x91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3',
      );
      expect(
        api.genesisHash(),
        completion('0x91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3'),
      );
    });

    test('chainName', () {
      final provider = MockProvider(null);
      final api = ChainSpecApi(provider);
      provider.setMethodCallback('chainSpec_v1_chainName', (params, state) => 'Polkadot');
      expect(api.chainName(), completion('Polkadot'));
    });

    test('properties', () {
      final provider = MockProvider(null);
      final api = ChainSpecApi(provider);
      provider.setMethodCallback(
        'chainSpec_v1_properties',
        (params, state) => {'ss58Format': 0, 'tokenDecimals': 10, 'tokenSymbol': 'DOT'},
      );
      expect(
        api.properties(),
        completion({'ss58Format': 0, 'tokenDecimals': 10, 'tokenSymbol': 'DOT'}),
      );
    });

    test('properties with multiple tokens', () {
      final provider = MockProvider(null);
      final api = ChainSpecApi(provider);
      provider.setMethodCallback(
        'chainSpec_v1_properties',
        (params, state) => {
          'ss58Format': 2,
          'tokenDecimals': [12, 12],
          'tokenSymbol': ['KSM', 'DOT'],
        },
      );
      expect(
        api.properties(),
        completion({
          'ss58Format': 2,
          'tokenDecimals': [12, 12],
          'tokenSymbol': ['KSM', 'DOT'],
        }),
      );
    });
  });
}
