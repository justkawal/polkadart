import 'dart:convert';
import 'dart:io';

import 'package:polkadart_scale_codec/polkadart_scale_codec.dart';
import 'package:substrate_metadata/substrate_metadata.dart';

/// Finds the monorepo root directory by looking for the 'chain' directory.
/// This allows tests to work both when run from:
/// - The monorepo root (via `melos test:chain` or `dart test packages/...`)
/// - The package directory (via `dart test` from packages/substrate_metadata)
String _findMonorepoRoot() {
  var current = Directory.current;

  // Walk up the directory tree looking for the 'chain' directory
  while (current.path != current.parent.path) {
    final chainDir = Directory('${current.path}/chain');
    if (chainDir.existsSync()) {
      return current.path;
    }
    current = current.parent;
  }

  throw StateError(
    'Could not find monorepo root (directory containing "chain" folder). '
    'Current directory: ${Directory.current.path}',
  );
}

/// Cached monorepo root path
String? _cachedMonorepoRoot;

/// Returns the path to the chain directory, works from any location in the monorepo.
String get chainBasePath {
  _cachedMonorepoRoot ??= _findMonorepoRoot();
  return '$_cachedMonorepoRoot/chain';
}

/// Resolves a chain-relative path to an absolute path.
/// Example: chainPath('polkadot/v14/events.jsonl') -> '/path/to/monorepo/chain/polkadot/v14/events.jsonl'
String chainPath(String relativePath) {
  return '$chainBasePath/$relativePath';
}

/// Helper class to cache metadata and codecs
class MetadataInfo {
  final RuntimeMetadataPrefixed prefixedMetadata;
  final MetadataTypeRegistry registry;
  final ExtrinsicsCodec extrinsicsCodec;
  final EventsRecordCodec eventsCodec;
  final int specVersion;

  MetadataInfo({
    required this.prefixedMetadata,
    required this.registry,
    required this.extrinsicsCodec,
    required this.eventsCodec,
    required this.specVersion,
  });
}

/// Represents a runtime upgrade point
class RuntimeUpgrade {
  final int specVersion;
  final int blockNumber;
  final String blockHash;
  final int metadataVersion;

  RuntimeUpgrade({
    required this.specVersion,
    required this.blockNumber,
    required this.blockHash,
    required this.metadataVersion,
  });

  factory RuntimeUpgrade.fromJson(Map<String, dynamic> json) {
    return RuntimeUpgrade(
      specVersion: json['spec_version'] as int,
      blockNumber: json['block_number'] as int,
      blockHash: json['block_hash'] as String,
      metadataVersion: json['metadata_version'] as int,
    );
  }
}

/// Load blocks from JSONL file
List<Map<String, dynamic>> loadBlocks(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) {
    throw Exception('Blocks file not found: $filePath');
  }
  final lines = file.readAsLinesSync();
  return lines.map((line) => jsonDecode(line) as Map<String, dynamic>).toList();
}

/// Load events from JSONL file
List<Map<String, dynamic>> loadEvents(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) {
    throw Exception('Events file not found: $filePath');
  }
  final lines = file.readAsLinesSync();
  return lines.map((line) => jsonDecode(line) as Map<String, dynamic>).toList();
}

/// Load runtime upgrades from JSON file
List<RuntimeUpgrade> loadRuntimeUpgrades(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) {
    throw Exception('Runtime upgrades file not found: $filePath');
  }
  final content = file.readAsStringSync();
  final list = jsonDecode(content) as List<dynamic>;
  return list.map((item) => RuntimeUpgrade.fromJson(item as Map<String, dynamic>)).toList();
}

/// Find the spec version for a given block number
int findSpecVersionForBlock(int blockNumber, List<RuntimeUpgrade> runtimeUpgrades) {
  int specVersion = runtimeUpgrades.first.specVersion;

  for (final upgrade in runtimeUpgrades) {
    if (upgrade.blockNumber <= blockNumber) {
      specVersion = upgrade.specVersion;
    } else {
      break;
    }
  }

  return specVersion;
}

/// Metadata cache to avoid reloading
final Map<String, Map<int, MetadataInfo>> _metadataCache = {};

/// Get or load metadata from cache
MetadataInfo getOrLoadMetadata(int specVersion, String metadataDir, String cacheKey) {
  _metadataCache[cacheKey] ??= {};
  final cache = _metadataCache[cacheKey]!;

  if (cache.containsKey(specVersion)) {
    return cache[specVersion]!;
  }

  // Load metadata file
  final metadataFile = File('$metadataDir/metadata_spec$specVersion.json');
  if (!metadataFile.existsSync()) {
    throw Exception('Metadata file not found for spec version $specVersion: ${metadataFile.path}');
  }

  final metadataJson = jsonDecode(metadataFile.readAsStringSync());
  final metadataHex = metadataJson['metadata'] as String;

  // Parse metadata
  final inputBytes = decodeHex(metadataHex);
  final prefixedMetadata = RuntimeMetadataPrefixed.fromBytes(inputBytes);
  final registry = MetadataTypeRegistry(prefixedMetadata);

  // Create codecs
  final extrinsicsCodec = ExtrinsicsCodec(registry);
  final eventsCodec = EventsRecordCodec(registry);

  final metadataInfo = MetadataInfo(
    prefixedMetadata: prefixedMetadata,
    registry: registry,
    extrinsicsCodec: extrinsicsCodec,
    eventsCodec: eventsCodec,
    specVersion: specVersion,
  );

  cache[specVersion] = metadataInfo;

  return metadataInfo;
}

/// Check if any extrinsic in the list has version 5
/// TODO: Remove this once extrinsic v5 is supported in the codebase
/// See: unchecked_extrinsic_codec.dart - needs to support version 5
bool hasExtrinsicVersion5(List<String> extrinsicsHexList) {
  for (final extHex in extrinsicsHexList) {
    // Remove 0x prefix
    final hex = extHex.startsWith('0x') ? extHex.substring(2) : extHex;
    if (hex.isEmpty) continue;

    // First bytes are compact-encoded length, then version byte
    // Compact encoding: if first byte & 0x03 == 0, length is byte >> 2
    // We need to skip the length prefix to get to the version byte
    final firstByte = int.parse(hex.substring(0, 2), radix: 16);
    final mode = firstByte & 0x03;

    int versionByteOffset;
    if (mode == 0) {
      // Single byte mode
      versionByteOffset = 2; // 1 byte = 2 hex chars
    } else if (mode == 1) {
      // Two byte mode
      versionByteOffset = 4; // 2 bytes = 4 hex chars
    } else if (mode == 2) {
      // Four byte mode
      versionByteOffset = 8; // 4 bytes = 8 hex chars
    } else {
      // Big integer mode - skip for now
      continue;
    }

    if (hex.length < versionByteOffset + 2) continue;

    final versionByte = int.parse(
      hex.substring(versionByteOffset, versionByteOffset + 2),
      radix: 16,
    );
    final version = versionByte & 0x7F; // Mask out the signed bit

    if (version == 5) {
      return true;
    }
  }
  return false;
}

/// Encode extrinsics list as SCALE Vec<Extrinsic>
String encodeExtrinsicsAsVec(List<String> extrinsicsHexList) {
  final buffer = StringBuffer();

  // Encode the count as compact
  final count = extrinsicsHexList.length;
  if (count < 64) {
    buffer.write('0x${(count << 2).toRadixString(16).padLeft(2, '0')}');
  } else if (count < 16384) {
    final encoded = ((count << 2) | 0x01).toRadixString(16).padLeft(4, '0');
    buffer.write('0x${encoded.substring(2, 4)}${encoded.substring(0, 2)}');
  } else {
    throw Exception('Too many extrinsics to encode: $count');
  }

  // Append each extrinsic (removing the 0x prefix)
  for (final extHex in extrinsicsHexList) {
    buffer.write(extHex.substring(2));
  }

  return buffer.toString();
}
