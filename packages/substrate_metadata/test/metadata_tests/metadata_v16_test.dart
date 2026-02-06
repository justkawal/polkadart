import 'dart:convert';
import 'dart:io';
import 'package:polkadart_scale_codec/polkadart_scale_codec.dart';
import 'package:substrate_metadata/substrate_metadata.dart';
import 'package:test/test.dart';

void main() {
  group('Metadata V16 Tests', () {
    late Map<String, dynamic> metadataJson;
    late RuntimeMetadataPrefixed prefixedMetadata;
    late RuntimeMetadataV16 metadata;

    setUpAll(() {
      // Load the downloaded V16 metadata
      final metadataFile = File('./test/metadata_tests/v16/westend_v16_metadata.json');
      if (!metadataFile.existsSync()) {
        throw Exception('V16 metadata file not found.');
      }

      metadataJson = jsonDecode(metadataFile.readAsStringSync());
      final metadataHex = metadataJson['metadata'] as String;

      // Decode the metadata
      final inputBytes = decodeHex(metadataHex);
      prefixedMetadata = RuntimeMetadataPrefixed.fromBytes(inputBytes);

      // Verify it's V16
      expect(prefixedMetadata.metadata, isA<RuntimeMetadataV16>());
      metadata = prefixedMetadata.metadata as RuntimeMetadataV16;
    });

    group('Basic Decoding Tests', () {
      test('Magic number is valid', () {
        expect(prefixedMetadata.isValidMagicNumber, isTrue);
        expect(prefixedMetadata.magicNumber, metaReserved);
      });

      test('Metadata version is 16', () {
        expect(metadata.version, 16);
        expect(metadataJson['metadata_version'], 16);
      });

      test('Types are populated', () {
        expect(metadata.types, isNotEmpty);
      });

      test('Pallets are populated', () {
        expect(metadata.pallets, isNotEmpty);
      });

      test('Runtime APIs are populated', () {
        expect(metadata.apis, isNotEmpty);
      });

      test('Outer enums are populated', () {
        expect(metadata.outerEnums, isNotNull);
        expect(metadata.outerEnums.callType, isNonNegative);
        expect(metadata.outerEnums.eventType, isNonNegative);
        expect(metadata.outerEnums.errorType, isNonNegative);
      });
    });

    group('V16-Specific Feature Tests', () {
      test('Extrinsic metadata uses transaction extensions (not signed extensions)', () {
        final extrinsic = metadata.extrinsic;
        expect(extrinsic, isA<ExtrinsicMetadataV16>());
        expect(extrinsic.transactionExtensions, isNotEmpty);
      });

      test('Pallets have deprecation info field', () {
        // All V16 pallets should have the deprecationInfo field (even if null)
        for (final pallet in metadata.pallets) {
          // Just accessing the field should not throw
          pallet.deprecationInfo;
        }
        expect(metadata.pallets, isNotEmpty);
      });

      test('Pallets can have associated types', () {
        var totalAssociatedTypes = 0;
        for (final pallet in metadata.pallets) {
          totalAssociatedTypes += pallet.associatedTypes.length;
        }
        // At least some pallets should have associated types
        expect(totalAssociatedTypes, greaterThan(0));
      });

      test('Pallets can have view functions', () {
        var totalViewFunctions = 0;
        for (final pallet in metadata.pallets) {
          totalViewFunctions += pallet.viewFunctions.length;
        }
        // View functions may or may not exist depending on the runtime
        expect(totalViewFunctions, greaterThanOrEqualTo(0));
      });
    });

    group('System Pallet Tests', () {
      late PalletMetadataV16 systemPallet;

      setUp(() {
        systemPallet = metadata.pallets.firstWhere((p) => p.name == 'System');
      });

      test('System pallet exists', () {
        expect(systemPallet, isNotNull);
        expect(systemPallet.name, 'System');
      });

      test('System pallet has constants', () {
        expect(systemPallet.constants, isNotEmpty);

        final constantNames = systemPallet.constants.map((c) => c.name).toList();

        // Common system constants
        expect(constantNames, contains('BlockWeights'));
        expect(constantNames, contains('BlockLength'));
        expect(constantNames, contains('BlockHashCount'));
        expect(constantNames, contains('Version'));
        expect(constantNames, contains('SS58Prefix'));
      });

      test('System pallet has storage', () {
        expect(systemPallet.storageV16, isNotNull);
        final storage = systemPallet.storageV16!;
        expect(storage.entries, isNotEmpty);
      });

      test('System pallet has calls', () {
        expect(systemPallet.calls, isNotNull);
        expect(systemPallet.calls!.type, isNonNegative);
      });

      test('System pallet has events', () {
        expect(systemPallet.eventV16, isNotNull);
        expect(systemPallet.eventV16!.type, isNonNegative);
      });

      test('System pallet has errors', () {
        expect(systemPallet.errorV16, isNotNull);
        expect(systemPallet.errorV16!.type, isNonNegative);
      });
    });

    group('Balances Pallet Tests', () {
      late PalletMetadataV16 balancesPallet;

      setUp(() {
        balancesPallet = metadata.pallets.firstWhere((p) => p.name == 'Balances');
      });

      test('Balances pallet exists and has constants', () {
        expect(balancesPallet, isNotNull);
        expect(balancesPallet.constants, isNotEmpty);

        final constantNames = balancesPallet.constants.map((c) => c.name).toList();
        expect(constantNames, contains('ExistentialDeposit'));
      });
    });

    group('Type Resolution Tests', () {
      test('Can resolve types by ID', () {
        final type0 = metadata.typeById(0);
        expect(type0, isNotNull);

        final type1 = metadata.typeById(1);
        expect(type1, isNotNull);
      });

      test('Can look up call type', () {
        final callType = metadata.typeById(metadata.outerEnums.callType);
        expect(callType, isNotNull);
        expect(callType.type.path, isNotEmpty);
      });

      test('Can look up event type', () {
        final eventType = metadata.typeById(metadata.outerEnums.eventType);
        expect(eventType, isNotNull);
        expect(eventType.type.path, isNotEmpty);
      });
    });

    group('MetadataTypeRegistry Tests', () {
      late MetadataTypeRegistry registry;

      setUp(() {
        registry = MetadataTypeRegistry(prefixedMetadata);
      });

      test('Registry builds successfully from V16 metadata', () {
        expect(registry, isNotNull);
        expect(registry.prefixed, prefixedMetadata);
      });

      test('Registry has type definitions', () {
        expect(registry.types.types, isNotEmpty);
      });
    });

    group('Merkleization Tests', () {
      test('Can create MetadataMerkleizer from V16 metadata', () {
        final merkleizer = MetadataMerkleizer.fromMetadata(
          metadata,
          decimals: 12,
          tokenSymbol: 'WND',
        );

        expect(merkleizer, isNotNull);
      });

      test('Can compute metadata digest', () {
        final merkleizer = MetadataMerkleizer.fromMetadata(
          metadata,
          decimals: 12,
          tokenSymbol: 'WND',
        );

        final digest = merkleizer.digest();

        expect(digest, isNotNull);
        expect(digest.length, 32); // Blake3 hash is 32 bytes
      });

      test('Digest is deterministic', () {
        final merkleizer1 = MetadataMerkleizer.fromMetadata(
          metadata,
          decimals: 12,
          tokenSymbol: 'WND',
        );

        final merkleizer2 = MetadataMerkleizer.fromMetadata(
          metadata,
          decimals: 12,
          tokenSymbol: 'WND',
        );

        final digest1 = merkleizer1.digest();
        final digest2 = merkleizer2.digest();

        expect(digest1, digest2);
      });

      test('Lookup entries are generated', () {
        final merkleizer = MetadataMerkleizer.fromMetadata(
          metadata,
          decimals: 12,
          tokenSymbol: 'WND',
        );

        expect(merkleizer.lookup, isNotEmpty);
      });

      test('Extrinsic info is correct for V16', () {
        final merkleizer = MetadataMerkleizer.fromMetadata(
          metadata,
          decimals: 12,
          tokenSymbol: 'WND',
        );

        expect(merkleizer.extrinsicMeta, isNotNull);
        expect(merkleizer.extrinsicMeta.version, greaterThan(0));
        expect(merkleizer.extrinsicMeta.signedExtensions, isNotEmpty);
      });

      test('Extra info contains correct chain data', () {
        final merkleizer = MetadataMerkleizer.fromMetadata(
          metadata,
          decimals: 12,
          tokenSymbol: 'WND',
        );

        expect(merkleizer.extraInfo, isNotNull);
        expect(merkleizer.extraInfo.decimals, 12);
        expect(merkleizer.extraInfo.tokenSymbol, 'WND');
        expect(merkleizer.extraInfo.specVersion, greaterThan(0));
        expect(merkleizer.extraInfo.specName, isNotEmpty);
        expect(merkleizer.extraInfo.base58Prefix, greaterThanOrEqualTo(0));
      });
    });

    group('JSON Serialization Tests', () {
      test('Metadata can be serialized to JSON', () {
        final json = prefixedMetadata.toJson();

        expect(json, isNotNull);
        expect(json['magicNumber'], isNotNull);
        expect(json['metadata'], isNotNull);
        expect(json['metadata']['V16'], isNotNull);
      });

      test('V16 metadata JSON has expected structure', () {
        final json = metadata.toJson();

        expect(json['types'], isNotNull);
        expect(json['pallets'], isNotNull);
        expect(json['extrinsic'], isNotNull);
        expect(json['apis'], isNotNull);
        expect(json['outerEnums'], isNotNull);
        expect(json['customMetadata'], isNotNull);
      });
    });

    group('Round-trip Encoding Tests', () {
      test('Metadata can be re-encoded and decoded', () {
        // Encode the metadata back to bytes
        final output = ByteOutput();
        RuntimeMetadataPrefixed.codec.encodeTo(prefixedMetadata, output);
        final encodedBytes = output.toBytes();

        // Decode it again
        final reDecoded = RuntimeMetadataPrefixed.fromBytes(encodedBytes);

        // Verify basic properties match
        expect(reDecoded.magicNumber, prefixedMetadata.magicNumber);
        expect(reDecoded.metadata.version, 16);

        final reDecodedV16 = reDecoded.metadata as RuntimeMetadataV16;
        expect(reDecodedV16.types.length, metadata.types.length);
        expect(reDecodedV16.pallets.length, metadata.pallets.length);
        expect(reDecodedV16.apis.length, metadata.apis.length);
      });
    });

    group('Multiple Chain V16 Tests', () {
      final chains = ['westend', 'paseo', 'polkadot', 'kusama'];

      for (final chain in chains) {
        test('Can decode $chain V16 metadata', () {
          final file = File('./test/metadata_tests/v16/${chain}_v16_metadata.json');
          if (!file.existsSync()) {
            return; // Skip if file not found
          }

          final json = jsonDecode(file.readAsStringSync());
          final hex = json['metadata'] as String;
          final bytes = decodeHex(hex);

          final prefixed = RuntimeMetadataPrefixed.fromBytes(bytes);
          expect(prefixed.metadata.version, 16);

          final v16 = prefixed.metadata as RuntimeMetadataV16;
          expect(v16.pallets, isNotEmpty);
          expect(v16.types, isNotEmpty);
        });
      }
    });
  });
}
