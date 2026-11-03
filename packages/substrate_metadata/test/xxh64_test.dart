import 'dart:typed_data' show Uint8List;

import 'package:polkadart_scale_codec/utils/utils.dart';
import 'package:substrate_metadata/substrate_hashers/substrate_hashers.dart';
import 'package:test/test.dart';

/// Reference values computed with the official xxHash implementation
/// (python-xxhash `xxh64_intdigest`), as `(seed, length, hash)` where the
/// input is the first `length` bytes of [_data].
///
/// The lengths cover every branch of the algorithm: inputs shorter than one
/// 32-byte stripe, exact multiples of 32 bytes, and 8-, 4- and 1-byte tails.
const _vectors = <(int, int, String)>[
  (0x0, 0, 'ef46db3751d8e999'),
  (0x0, 1, '1f25c8d0bc1f4bb6'),
  (0x0, 3, '31d2363f52e564c9'),
  (0x0, 4, '9bb64b7d66ee9fda'),
  (0x0, 5, 'c7608efddb7051fe'),
  (0x0, 7, '9a7b149959ce60d8'),
  (0x0, 8, 'dab99d95c6f90092'),
  (0x0, 9, '170bb6bf975b4c02'),
  (0x0, 12, 'd52e407833af5133'),
  (0x0, 15, '1b47cb8243cc8e32'),
  (0x0, 16, '434850232b787be2'),
  (0x0, 31, 'a2aa5f33cc4a6119'),
  (0x0, 32, '23c3c17ef790fd97'),
  (0x0, 33, '50a7cfc7ba588784'),
  (0x0, 36, 'c0b52b0dcc5e3f7f'),
  (0x0, 40, 'b620306b253d76b6'),
  (0x0, 63, '5e3e54b431c7493c'),
  (0x0, 64, '0eb64b3ef6eeb01f'),
  (0x0, 65, 'a383b724b2bd12f1'),
  (0x0, 100, 'a61f8d4c170fe531'),
  (0x0, 255, '39ae55a29989206f'),
  (0x0, 300, '240004dbee0ba6dc'),
  (0x1, 0, 'd5afba1336a3be4b'),
  (0x1, 1, '610f93f8c89889fe'),
  (0x1, 3, '2d80e074130d0176'),
  (0x1, 4, '5ec9fdd10fcbcb0e'),
  (0x1, 5, '89c1d7fbeb0222bf'),
  (0x1, 7, 'd8b4a941715fee31'),
  (0x1, 8, 'f119f5b26c0020ab'),
  (0x1, 9, 'c35609e49aadbb91'),
  (0x1, 12, '37851f0d89d23966'),
  (0x1, 15, '7a94ee016f09b732'),
  (0x1, 16, 'c9681422ce33496d'),
  (0x1, 31, 'aaca4e41ffcae21c'),
  (0x1, 32, '7421b79a02b42132'),
  (0x1, 33, '17b3df313de9a40e'),
  (0x1, 36, '2e6895034c467c0b'),
  (0x1, 40, '8c15d7af4fd7bc9f'),
  (0x1, 63, 'b1abb4a5ad0e2943'),
  (0x1, 64, '2d0457940c5a93f4'),
  (0x1, 65, '6153dc23fc8bebd8'),
  (0x1, 100, '8d8957e68f02c7ce'),
  (0x1, 255, 'c4b1acca1d37e7e4'),
  (0x1, 300, '8197c668a97c7639'),
  (0x2, 0, '5a68f3b1643c966f'),
  (0x2, 1, 'dfadc131df9c7dda'),
  (0x2, 3, '05bcdc3a2bd4e218'),
  (0x2, 4, '2c7478d0389e71ea'),
  (0x2, 5, 'd1305e693082a911'),
  (0x2, 7, '5a01e684c4d658fe'),
  (0x2, 8, 'b6d87bfd70f2a868'),
  (0x2, 9, 'eeba9522922c8bb2'),
  (0x2, 12, '9cf67fae571f4e09'),
  (0x2, 15, '116848d3d0911219'),
  (0x2, 16, '4188a65227eed627'),
  (0x2, 31, '891e3add65d5e177'),
  (0x2, 32, '812f39c7e786b3b3'),
  (0x2, 33, 'd96d3fa8a2150b54'),
  (0x2, 36, '734a45c89f1b6ca5'),
  (0x2, 40, '80ae84a21dbadfb0'),
  (0x2, 63, '3f67b6316a840564'),
  (0x2, 64, '421242992da96299'),
  (0x2, 65, 'cb14e906d25fdb47'),
  (0x2, 100, '5315f0bd70965874'),
  (0x2, 255, '7499c4184dc7ae7d'),
  (0x2, 300, 'd0f31c45a412e553'),
  (0x7fffffff, 0, '2655611cbf9cdb34'),
  (0x7fffffff, 1, '2cb995c336b6eca7'),
  (0x7fffffff, 3, '8a51744b6680438b'),
  (0x7fffffff, 4, 'efeb349c978c8ad1'),
  (0x7fffffff, 5, 'bac93ca4ac682c5d'),
  (0x7fffffff, 7, '98aa04162a65394f'),
  (0x7fffffff, 8, '6fb0c33ed2ab8a23'),
  (0x7fffffff, 9, '425e09caded76caf'),
  (0x7fffffff, 12, 'a5397469941dc0ab'),
  (0x7fffffff, 15, '41f116ca5402030e'),
  (0x7fffffff, 16, 'e4588840c632c925'),
  (0x7fffffff, 31, 'a79cff90da8f09f7'),
  (0x7fffffff, 32, 'b9618111ce893b4e'),
  (0x7fffffff, 33, '49252c4e6935c4e0'),
  (0x7fffffff, 36, '959867ac2470a297'),
  (0x7fffffff, 40, '373c5da4d4af4e29'),
  (0x7fffffff, 63, '8a26b66679329f2e'),
  (0x7fffffff, 64, 'ef30d47043c128dc'),
  (0x7fffffff, 65, 'a7982a73aeccc230'),
  (0x7fffffff, 100, 'a60c59e54828d2a8'),
  (0x7fffffff, 255, 'fae0c4140037f741'),
  (0x7fffffff, 300, '0eaf9ec102f41c27'),
  (0x123456789abc, 0, '1640230f7e3ea661'),
  (0x123456789abc, 1, 'fbc4967ae36a1189'),
  (0x123456789abc, 3, '7f2c00dba306d0bf'),
  (0x123456789abc, 4, 'd2a24464657b4297'),
  (0x123456789abc, 5, 'bb83fa55d8f70d13'),
  (0x123456789abc, 7, 'c2ab78555787902b'),
  (0x123456789abc, 8, '38c672c1e64ede02'),
  (0x123456789abc, 9, 'aecb3fbfdfeae8b1'),
  (0x123456789abc, 12, 'c3b8240bafcb5a37'),
  (0x123456789abc, 15, 'b0fb77be2251f958'),
  (0x123456789abc, 16, '45d353221b2ad098'),
  (0x123456789abc, 31, 'b218b61d706d047c'),
  (0x123456789abc, 32, 'a9c6b828ed705234'),
  (0x123456789abc, 33, 'e80cb8e7152f23ec'),
  (0x123456789abc, 36, '2d90228371344c5e'),
  (0x123456789abc, 40, 'c036a95c4484671e'),
  (0x123456789abc, 63, 'fc1858ea3eb795f3'),
  (0x123456789abc, 64, '80c5b20e12208324'),
  (0x123456789abc, 65, '0da8cd6ab7c59134'),
  (0x123456789abc, 100, '804967b9dd07650d'),
  (0x123456789abc, 255, 'ada0b9770a012cce'),
  (0x123456789abc, 300, '601bffdd12618588'),
];

final _data = Uint8List.fromList(List.generate(300, (i) => (i * 7 + 3) & 0xff));

String _hex(Uint8List digest) => encodeHex(digest);

void main() {
  group('XXHash64', () {
    test('uses the portable implementation only when compiled to JavaScript', () {
      final isJS = identical(1, 1.0);
      expect(
        XXHash64(0).createSink(),
        isJS ? isA<XXHash64PortableSink>() : isA<XXHash64NativeSink>(),
      );
    });

    test('matches the reference implementation', () {
      for (final (seed, length, expected) in _vectors) {
        final digest = XXHash64(seed).convert(_data.sublist(0, length)).bytes;
        expect(_hex(digest), expected, reason: 'seed=$seed length=$length');
      }
    });

    test('portable implementation matches the reference implementation', () {
      for (final (seed, length, expected) in _vectors) {
        final sink = XXHash64PortableSink(seed)..add(_data.sublist(0, length));
        expect(_hex(sink.digest().bytes), expected, reason: 'seed=$seed length=$length');
      }
    });

    test('native implementation matches the reference implementation', () {
      for (final (seed, length, expected) in _vectors) {
        final sink = XXHash64NativeSink(seed)..add(_data.sublist(0, length));
        expect(_hex(sink.digest().bytes), expected, reason: 'seed=$seed length=$length');
      }
    }, testOn: '!js');

    test('gives the same result when the input arrives in chunks', () {
      for (final (seed, length, expected) in _vectors) {
        for (final chunkSize in [1, 5, 31, 32, 33]) {
          final sink = XXHash64(seed).createSink();
          for (var i = 0; i < length; i += chunkSize) {
            sink.add(_data.sublist(i, i + chunkSize > length ? length : i + chunkSize));
          }
          expect(
            _hex(sink.digest().bytes),
            expected,
            reason: 'seed=$seed length=$length chunkSize=$chunkSize',
          );
        }
      }
    });

    // Twox64Concat keys of AccountId32 are 32 bytes long, exactly one stripe.
    test('Twox64 of a 32-byte AccountId', () {
      final accountId = decodeHex(
        'c1763ec7974010d7d4d3810f266921bcc759d5f65e5cedd67e926ddcf2230e6b',
      );
      expect(encodeHex(TwoxxHasher(1).hash(accountId)), 'a8107b48dc0a9baa');
    });
  });
}
