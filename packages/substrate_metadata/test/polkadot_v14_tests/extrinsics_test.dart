import 'dart:convert' show jsonDecode;
import 'dart:io' show File;

import 'package:polkadart_scale_codec/io/io.dart' show Input, HexOutput;
import 'package:polkadart_scale_codec/utils/utils.dart' show decodeHex;
import 'package:substrate_metadata/derived_codecs/derived_codecs.dart' show ExtrinsicsCodec;
import 'package:substrate_metadata/metadata/metadata.dart' show RuntimeMetadataPrefixed;
import 'package:substrate_metadata/models/models.dart'
    show UncheckedExtrinsic, ExtrinsicType, RuntimeCall;
import 'package:substrate_metadata/registry/metadata_type_registry.dart' show MetadataTypeRegistry;
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  final metadataFile = File('../../chain/metadata/metadata_v14.json');
  final metatadaJson = jsonDecode(metadataFile.readAsStringSync());
  final metadataV14 = metatadaJson['v14'];
  group('Extrinsics Decode/Encode: ', () {
    test('Decode Test', () {
      final inputBytes = decodeHex(metadataV14);
      final RuntimeMetadataPrefixed prefixedMetadata = RuntimeMetadataPrefixed.fromBytes(
        inputBytes,
      );
      final MetadataTypeRegistry registry = MetadataTypeRegistry(prefixedMetadata);

      final ExtrinsicsCodec extrinsicsCodec = ExtrinsicsCodec(registry);
      final decodedExtrinsic = extrinsicsCodec.decode(Input.fromHex(_encodedExtrinsicHex));

      final expectedJson = _decodedExtrinsicMap().map((e) => e.toJson()).toList();
      final actualJson = decodedExtrinsic.map((e) => e.toJson()).toList();

      expect(expectedJson, actualJson);
    });

    test('Encode Test', () {
      final inputBytes = decodeHex(metadataV14);
      final RuntimeMetadataPrefixed prefixedMetadata = RuntimeMetadataPrefixed.fromBytes(
        inputBytes,
      );
      final MetadataTypeRegistry registry = MetadataTypeRegistry(prefixedMetadata);
      final ExtrinsicsCodec extrinsicsCodec = ExtrinsicsCodec(registry);

      final output = HexOutput();
      extrinsicsCodec.encodeTo(_decodedExtrinsicMap(), output);
      final encodedHex = output.toString();

      expect(encodedHex, _encodedExtrinsicHex);
    });

    test('Round-Trip Test (Decode First)', () {
      final inputBytes = decodeHex(metadataV14);
      final RuntimeMetadataPrefixed prefixedMetadata = RuntimeMetadataPrefixed.fromBytes(
        inputBytes,
      );
      final MetadataTypeRegistry registry = MetadataTypeRegistry(prefixedMetadata);

      final ExtrinsicsCodec extrinsicsCodec = ExtrinsicsCodec(registry);
      // Decode first
      final decodedExtrinsics = extrinsicsCodec.decode(Input.fromHex(_encodedExtrinsicHex));

      final ExtrinsicsCodec extrinsicsCodec2 = ExtrinsicsCodec(registry);
      // Then encode
      final output = HexOutput();
      extrinsicsCodec2.encodeTo(decodedExtrinsics, output);
      final roundTripEncodedHex = output.toString();

      expect(roundTripEncodedHex, _encodedExtrinsicHex);
    });

    test('Round-Trip Test (Encode First)', () {
      final inputBytes = decodeHex(metadataV14);
      final RuntimeMetadataPrefixed prefixedMetadata = RuntimeMetadataPrefixed.fromBytes(
        inputBytes,
      );
      final MetadataTypeRegistry registry = MetadataTypeRegistry(prefixedMetadata);

      final ExtrinsicsCodec extrinsicsCodec = ExtrinsicsCodec(registry);

      // Encode first
      final output = HexOutput();
      extrinsicsCodec.encodeTo(_decodedExtrinsicMap(), output);
      final encodedHex = output.toString();

      // Then decode
      final decodedExtrinsics = extrinsicsCodec.decode(Input.fromHex(encodedHex));

      final expectedJson = _decodedExtrinsicMap().map((e) => e.toJson()).toList();
      final actualJson = decodedExtrinsics.map((e) => e.toJson()).toList();

      expect(actualJson, expectedJson);
    });
  });
}

const _encodedExtrinsicHex =
    '0x0499040436000000004f0fd348d45083cfc987db027a6c093b7f2b5d04eea4a9f0c752922cd90ea5ed1a3bb901b7b922bf8f589915c3042968995ec5f4845a0e47d92d3017df4520a90be65a0687ff11c060f52d2b0e15e7c01c86a5c004e89a239426cd50ac5fc6dd9822e470080642414245b501030a000000139f3b10000000009c7d5389e591bad6f06e4bbeedc05c32adb5fe2f98534c0e4e9cf83e222a180be8d102c101f4b7fa5383cdc9373359466b6be3be59bad84c96179a470ae8c60c4058b13b1370451d1027487e92556d696e7b817e3dbd1682e2d6ee56bace9105054241424501015a09b657fab77668b5d370b1e4ca57ded589a7afaba583e8a7118b073f694a3cb5b606611f2d4fce4cfc38a3ccb972db3684f3e53f23e747827f52dca2f9e184';

List<UncheckedExtrinsic> _decodedExtrinsicMap() {
  return [
    UncheckedExtrinsic(
      version: 4,
      type: ExtrinsicType.bare,
      call: RuntimeCall(
        palletName: 'ParaInherent',
        palletIndex: 54,
        callName: 'enter',
        callIndex: 0,
        args: {
          'data': {
            'bitfields': [],
            'backed_candidates': [],
            'disputes': [],
            'parent_header': {
              'parent_hash': [
                79,
                15,
                211,
                72,
                212,
                80,
                131,
                207,
                201,
                135,
                219,
                2,
                122,
                108,
                9,
                59,
                127,
                43,
                93,
                4,
                238,
                164,
                169,
                240,
                199,
                82,
                146,
                44,
                217,
                14,
                165,
                237,
              ],
              'number': 7229126,
              'state_root': [
                183,
                185,
                34,
                191,
                143,
                88,
                153,
                21,
                195,
                4,
                41,
                104,
                153,
                94,
                197,
                244,
                132,
                90,
                14,
                71,
                217,
                45,
                48,
                23,
                223,
                69,
                32,
                169,
                11,
                230,
                90,
                6,
              ],
              'extrinsics_root': [
                135,
                255,
                17,
                192,
                96,
                245,
                45,
                43,
                14,
                21,
                231,
                192,
                28,
                134,
                165,
                192,
                4,
                232,
                154,
                35,
                148,
                38,
                205,
                80,
                172,
                95,
                198,
                221,
                152,
                34,
                228,
                112,
              ],
              'digest': {
                'logs': [
                  MapEntry('PreRuntime', {
                    'field0': [66, 65, 66, 69],
                    'field1': [
                      3,
                      10,
                      0,
                      0,
                      0,
                      19,
                      159,
                      59,
                      16,
                      0,
                      0,
                      0,
                      0,
                      156,
                      125,
                      83,
                      137,
                      229,
                      145,
                      186,
                      214,
                      240,
                      110,
                      75,
                      190,
                      237,
                      192,
                      92,
                      50,
                      173,
                      181,
                      254,
                      47,
                      152,
                      83,
                      76,
                      14,
                      78,
                      156,
                      248,
                      62,
                      34,
                      42,
                      24,
                      11,
                      232,
                      209,
                      2,
                      193,
                      1,
                      244,
                      183,
                      250,
                      83,
                      131,
                      205,
                      201,
                      55,
                      51,
                      89,
                      70,
                      107,
                      107,
                      227,
                      190,
                      89,
                      186,
                      216,
                      76,
                      150,
                      23,
                      154,
                      71,
                      10,
                      232,
                      198,
                      12,
                      64,
                      88,
                      177,
                      59,
                      19,
                      112,
                      69,
                      29,
                      16,
                      39,
                      72,
                      126,
                      146,
                      85,
                      109,
                      105,
                      110,
                      123,
                      129,
                      126,
                      61,
                      189,
                      22,
                      130,
                      226,
                      214,
                      238,
                      86,
                      186,
                      206,
                      145,
                      5,
                    ],
                  }),
                  MapEntry('Seal', {
                    'field0': [66, 65, 66, 69],
                    'field1': [
                      90,
                      9,
                      182,
                      87,
                      250,
                      183,
                      118,
                      104,
                      181,
                      211,
                      112,
                      177,
                      228,
                      202,
                      87,
                      222,
                      213,
                      137,
                      167,
                      175,
                      171,
                      165,
                      131,
                      232,
                      167,
                      17,
                      139,
                      7,
                      63,
                      105,
                      74,
                      60,
                      181,
                      182,
                      6,
                      97,
                      31,
                      45,
                      79,
                      206,
                      76,
                      252,
                      56,
                      163,
                      204,
                      185,
                      114,
                      219,
                      54,
                      132,
                      243,
                      229,
                      63,
                      35,
                      231,
                      71,
                      130,
                      127,
                      82,
                      220,
                      162,
                      249,
                      225,
                      132,
                    ],
                  }),
                ],
              },
            },
          },
        },
      ),
    ),
  ];
}
