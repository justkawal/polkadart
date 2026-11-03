// Runs on every platform; CI also runs it with `-p chrome` (dart2js) and
// `-p chrome -c dart2wasm` to catch code that only works with 64-bit ints.
import 'package:polkadart/polkadart.dart';
import 'package:test/test.dart';

final _alice = decodeHex('d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d');

void main() {
  group('Web compatibility', () {
    test('System.Account storage key (Blake2_128Concat)', () {
      const account = StorageMap<List<int>, List<int>>(
        prefix: 'System',
        storage: 'Account',
        hasher: StorageHasher.blake2b128Concat(U8ArrayCodec(32)),
        valueCodec: U8SequenceCodec.codec,
      );
      expect(
        encodeHex(account.hashedKeyFor(_alice)),
        '26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da9'
        'de1e86a9a8c739864cf3cc5ec2bea59fd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d',
      );
    });

    // Twox64Concat over a 32-byte AccountId hashes exactly one xxHash stripe.
    test('Session.NextKeys storage key (Twox64Concat)', () {
      const nextKeys = StorageMap<List<int>, List<int>>(
        prefix: 'Session',
        storage: 'NextKeys',
        hasher: StorageHasher.twoxx64Concat(U8ArrayCodec(32)),
        valueCodec: U8SequenceCodec.codec,
      );
      expect(
        encodeHex(nextKeys.hashedKeyFor(_alice)),
        'cec5070d609dd3497f72bde07fc96ba04c014e6bf8b8c2c011e7290b85696bb3'
        '518366b5b1bc7c99d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d',
      );
    });

    test('u64 values above 2^53 round-trip', () {
      final max = BigInt.parse('ffffffffffffffff', radix: 16);
      final encoded = U64Codec.codec.encode(max);
      expect(encodeHex(encoded), 'ffffffffffffffff');
      expect(U64Codec.codec.decode(ByteInput(encoded)), max);

      final list = [BigInt.zero, BigInt.two.pow(53) + BigInt.one, max];
      expect(U64SequenceCodec.codec.decode(ByteInput(U64SequenceCodec.codec.encode(list))), list);
    });

    test('Compact values above 2^31 round-trip', () {
      final cases = {
        0x80000000: '0300000080',
        0xFFFFFFFF: '03ffffffff',
        0x100000000: '070000000001',
        0x10000000000: '0b000000000001',
        9007199254740991: '0fffffffffffff1f', // 2^53 - 1
      };
      for (final MapEntry(key: value, value: hex) in cases.entries) {
        expect(encodeHex(CompactCodec.codec.encode(value)), hex, reason: '$value');
        expect(CompactCodec.codec.decode(ByteInput(decodeHex(hex))), value, reason: hex);
        expect(CompactCodec.codec.sizeHint(value), hex.length ~/ 2, reason: '$value');
      }
    });
  });
}
