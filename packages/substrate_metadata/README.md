# substrate_metadata

A powerful Dart/Flutter library for encoding and decoding Substrate blockchain metadata, extrinsics, events, and constants.

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  substrate_metadata: any
```

Then run:

```bash
dart pub get
```

## Quick Start

```dart
import 'package:substrate_metadata/substrate_metadata.dart';

// 1. Decode metadata from hex bytes
final metadataBytes = decodeHex('0x6d657461...'); // Your chain's metadata
final prefixed = RuntimeMetadataPrefixed.fromBytes(metadataBytes);

// 2. Create ChainInfo - your one-stop shop for chain operations
final chainInfo = prefixed.buildChainInfo();

// 3. Decode events from storage
final eventsHex = '0x08000000...'; // Events from System.Events storage
final events = chainInfo.eventsCodec.decode(Input.fromHex(eventsHex));

for (final record in events) {
  print('${record.event.palletName}.${record.event.eventName}');
  print('Data: ${record.event.data}');
}

// 4. Access runtime constants
final existentialDeposit = chainInfo.constantsCodec.getConstant(
  'Balances',
  'ExistentialDeposit'
);
print('Existential Deposit: $existentialDeposit');
```

## Common Use Cases

### Decoding Events

```dart
final eventsCodec = EventsRecordCodec(registry);

// Decode events from System.Events storage
final events = eventsCodec.decode(Input.fromHex(eventsHex));

for (final record in events) {
  // Phase: when the event occurred
  switch (record.phase.type) {
    case PhaseType.applyExtrinsic:
      print('During extrinsic ${record.phase.extrinsicIndex}');
    case PhaseType.finalization:
      print('During finalization');
    case PhaseType.initialization:
      print('During initialization');
  }

  // Event details
  final event = record.event;
  print('Pallet: ${event.palletName} (index: ${event.palletIndex})');
  print('Event: ${event.eventName} (index: ${event.eventIndex})');
  print('Data: ${event.data}');

  // Topics for filtering
  print('Topics: ${record.topics}');
}

// Encode events back to bytes
final output = HexOutput();
eventsCodec.encodeTo(events, output);
final encodedHex = output.toString();

// Query event metadata
final transferInfo = eventsCodec.getEventInfo('Balances', 'Transfer');
print('Fields: ${transferInfo?.fields.map((f) => f.name)}');
```

### Decoding Extrinsics

```dart
final extrinsicsCodec = ExtrinsicsCodec(registry);

// Decode extrinsics from a block
final extrinsics = extrinsicsCodec.decode(Input.fromHex(blockExtrinsicsHex));

for (final ext in extrinsics) {
  print('Version: ${ext.version}');
  print('Signed: ${ext.isSigned}');

  // The call being made
  final call = ext.call;
  print('Call: ${call.palletName}.${call.callName}');
  print('Args: ${call.args}');

  // Signature (if signed)
  if (ext.signature != null) {
    final sig = ext.signature!;
    print('Signer: ${sig.address}');
    print('Nonce: ${sig.extra['CheckNonce']}');
    print('Tip: ${sig.extra['ChargeTransactionPayment']}');
  }
}

// Encode a runtime call
final callCodec = RuntimeCallCodec(registry);
final encodedCall = callCodec.encode(RuntimeCall(
  palletName: 'Balances',
  palletIndex: 5,
  callName: 'transfer_allow_death',
  callIndex: 0,
  args: {
    'dest': {'Id': recipientBytes},
    'value': BigInt.from(1000000000000),
  },
));
```

### Working with Constants

```dart
// Standard codec - loads all constants eagerly
final constantsCodec = ConstantsCodec(registry);

// Get a single constant
final blockHashCount = constantsCodec.getConstant('System', 'BlockHashCount');

// Get all constants for a pallet
final balancesConstants = constantsCodec.getPalletConstants('Balances');
print('ExistentialDeposit: ${balancesConstants['ExistentialDeposit']}');

// Get all constants across runtime
final allConstants = constantsCodec.getAllConstants();

// Get constant metadata
final info = constantsCodec.getConstantInfo('Balances', 'ExistentialDeposit');
print('Type: ${info?.typeString}');
print('Docs: ${info?.documentation}');

// Lazy codec - loads constants on demand (memory efficient)
final lazyCodec = LazyConstantsCodec(registry);

// Preload frequently used constants
lazyCodec.preloadConstants([
  ('Balances', 'ExistentialDeposit'),
  ('TransactionPayment', 'TransactionByteFee'),
]);

// Check loading status
final stats = lazyCodec.getLoadingStats();
print('Loaded: ${stats['loadedConstants']}/${stats['totalConstants']}');
```

### ChainInfo & MetadataTypeRegistry

```dart
// ChainInfo - convenient facade for all chain operations
final chainInfo = ChainInfo.fromMetadata(metadataBytes);

// Or from prefixed metadata
final prefixed = RuntimeMetadataPrefixed.fromBytes(bytes);
final chainInfo = prefixed.buildChainInfo();

// Access components
final registry = chainInfo.registry;           // Type registry
final eventsCodec = chainInfo.eventsCodec;     // Events codec
final extrinsicsCodec = chainInfo.extrinsicsCodec;  // Extrinsics codec
final constantsCodec = chainInfo.constantsCodec;    // Constants codec
final callsCodec = chainInfo.callsCodec;       // Runtime calls codec

// MetadataTypeRegistry - the heart of the type system
final registry = MetadataTypeRegistry(prefixedMetadata);

// Get codec for any type ID
final codec = registry.codecFor(typeId);
final decoded = codec.decode(input);

// Look up types
final type = registry.typeById(42);
final typeByPath = registry.typeByPath('sp_runtime::DispatchError');

// Access pallet metadata
final balances = registry.palletByName('Balances');
final system = registry.palletByIndex(0);

// Get storage metadata
final accountStorage = registry.getStorageMetadata('System', 'Account');

// V15: Access runtime APIs
final apiCodec = registry.getRuntimeApiOutputCodec('Core', 'version');
```

## Features

- **Metadata V14, V15 & V16 Support** - Full support for all modern Substrate metadata formats
- **V16 Deprecation Tracking** - Query deprecation status of pallets, calls, events, errors, constants, and runtime APIs
- **V16 Associated Types** - Access pallet Config trait associated types (names, type IDs, documentation)
- **V16 View Functions** - Read-only query functions with 32-byte identifiers
- **V16 Transaction Extensions** - New extension model replacing signed extensions, with version-aware selection
- **Extrinsic V4 & V5 Decoding** - Decode signed (0x84/0x85), bare (0x04/0x05), and general (0x45) extrinsics
- **Complete Type System** - Portable type registry with all Substrate type definitions
- **Event Decoding/Encoding** - Decode and encode runtime events with full type safety
- **Extrinsic Handling** - Parse and construct signed/unsigned extrinsics
- **Constants Access** - Easy access to runtime constants with lazy loading support
- **Metadata Merkleization** - Blake3-based digest computation and proof generation for V14/V15/V16
- **Storage Hashers** - Blake2b, Blake3, and XXHash implementations for storage key generation
- **Cross-Platform** - Works on Flutter, Dart VM, and Web (WASM compatible)
- **Zero Configuration** - Automatically adapts to any Substrate-based chain via metadata

## Storage Hashers

Generate storage keys for querying chain state:

```dart
// Available hashers
final blake2b128 = Hasher.blake2b128;  // Cryptographic, 16 bytes
final blake2b256 = Hasher.blake2b256;  // Cryptographic, 32 bytes
final twox128 = Hasher.twoxx128;       // Fast (non-crypto), 16 bytes
final twox64 = Hasher.twoxx64;         // Fast (non-crypto), 8 bytes

// Hash a string
final hash = Hasher.twoxx128.hashString('System');

// Storage value (no key)
final storageValue = StorageValue(
  prefix: 'System',
  storage: 'Number',
  valueCodec: U32Codec.codec,
);
final key = storageValue.hashedKey();  // 32 bytes

// Storage map (single key)
final storageMap = StorageMap(
  prefix: 'System',
  storage: 'Account',
  hasher: StorageHasher.blake2b128Concat(accountIdCodec),
  valueCodec: accountInfoCodec,
);
final accountKey = storageMap.hashedKeyFor(accountId);

// Storage double map (two keys)
final doubleMap = StorageDoubleMap(
  prefix: 'Staking',
  storage: 'ErasStakers',
  hasher1: StorageHasher.twoxx64Concat(U32Codec.codec),
  hasher2: StorageHasher.twoxx64Concat(accountIdCodec),
  valueCodec: exposureCodec,
);
final stakersKey = doubleMap.hashedKeyFor(eraIndex, validatorId);

// N-map for variable number of keys
final nMap = StorageNMap(
  prefix: 'Assets',
  storage: 'Account',
  hashers: [
    StorageHasher.blake2b128Concat(U32Codec.codec),
    StorageHasher.blake2b128Concat(accountIdCodec),
  ],
  valueCodec: assetAccountCodec,
);
final assetKey = nMap.hashedKeyFor([assetId, accountId]);
```

### Hasher Selection Guide

| Hasher | Security | Speed | Use Case |
|--------|----------|-------|----------|
| `blake2b128Concat` | Secure | Moderate | User-controlled keys (recommended) |
| `blake2b256` | Secure | Moderate | High-security hashing |
| `twox64Concat` | Not secure | Fast | Trusted keys only |
| `twox128` | Not secure | Fast | Internal/system keys |
| `identity` | N/A | Fastest | When key is already unique |

**Note**: "Concat" variants append the original key, enabling storage enumeration.

## Data Models

### RuntimeEvent

```dart
class RuntimeEvent {
  final String palletName;    // e.g., "Balances"
  final int palletIndex;      // e.g., 5
  final String eventName;     // e.g., "Transfer"
  final int eventIndex;       // e.g., 2
  final Map<String, dynamic> data;  // Event fields

  String get identifier => '$palletName.$eventName';
}
```

### UncheckedExtrinsic

```dart
class UncheckedExtrinsic {
  final int version;                    // Extrinsic version (4 or 5)
  final ExtrinsicSignature? signature;  // null for unsigned/bare
  final RuntimeCall call;               // The actual call

  bool get isSigned => signature != null;
}

// V5 introduces the ExtrinsicType enum:
enum ExtrinsicType { signed, bare, general }

// Version byte mapping:
// V4: 0x04 (bare), 0x84 (signed)
// V5: 0x05 (bare), 0x85 (signed), 0x45 (general)
```

### RuntimeCall

```dart
class RuntimeCall {
  final String palletName;
  final int palletIndex;
  final String callName;
  final int callIndex;
  final Map<String, dynamic> args;
}
```

### EventRecord

```dart
class EventRecord {
  final Phase phase;           // When during block execution
  final RuntimeEvent event;    // The actual event
  final List<String> topics;   // For indexed filtering
}
```

### Phase

```dart
enum PhaseType { applyExtrinsic, finalization, initialization }

class Phase {
  final PhaseType type;
  final int? extrinsicIndex;  // Only for applyExtrinsic
}
```

## Core Concepts

### The Metadata-Driven Approach

Unlike traditional SDKs that require compile-time type definitions, `substrate_metadata` dynamically builds codecs from runtime metadata. This means:

1. **Any Chain Support** - Works with Polkadot, Kusama, or any custom Substrate chain
2. **Version Agnostic** - Automatically handles runtime upgrades
3. **No Code Generation** - No build steps or generated files needed

### Key Components

| Component | Purpose |
|-----------|---------|
| `RuntimeMetadataPrefixed` | Decoded metadata with version detection (V14/V15/V16) |
| `MetadataTypeRegistry` | Core type resolution and codec generation |
| `ChainInfo` | High-level facade for common operations |
| `EventsRecordCodec` | Decode/encode event records |
| `ExtrinsicsCodec` | Decode/encode block extrinsics (V4 and V5 format) |
| `ConstantsCodec` | Access runtime constants |
| `MetadataMerkleizer` | Compute metadata digest and generate merkle proofs |

## Metadata Versions

### V14

- Portable type registry
- Pallet metadata (calls, events, errors, constants, storage)
- Extrinsic metadata with signed extensions

### V15

Everything in V14, plus:

- **Runtime APIs**: Metadata for runtime API methods
- **Outer Enums**: Direct access to RuntimeCall, RuntimeEvent, RuntimeError types
- **Custom Metadata**: Chain-specific metadata extensions
- **Pallet Documentation**: Documentation strings for pallets

```dart
// V15-specific: Access runtime APIs
if (registry.outerEnums != null) {
  final apiCodec = registry.getRuntimeApiOutputCodec('TransactionPaymentApi', 'query_info');
  // Use codec for runtime API calls
}
```

### V16 (Latest)

Everything in V15, plus:

- **Transaction Extensions**: Replace signed extensions with version-aware transaction extensions
- **Deprecation Tracking**: Mark pallets, calls, events, errors, constants, storage entries, and runtime APIs as deprecated
- **Associated Types**: Expose pallet Config trait associated types (e.g., `AccountId`, `BlockNumber`)
- **View Functions**: Read-only query functions with 32-byte identifiers and typed inputs/outputs
- **Runtime API Versioning**: Explicit version field and per-method deprecation on runtime APIs
- **Multi-Version Extrinsic Support**: Metadata declares supported extrinsic versions (e.g., `[4, 5]`)

```dart
// Decode V16 metadata (version routing is automatic)
final prefixed = RuntimeMetadataPrefixed.fromBytes(metadataBytes);
final chainInfo = prefixed.buildChainInfo();

// Access V16-specific features on the raw metadata
final metadata = prefixed.metadata;
if (metadata is RuntimeMetadataV16) {
  // Transaction extensions (replacing signed extensions)
  final extrinsic = metadata.extrinsic as ExtrinsicMetadataV16;
  print('Supported versions: ${extrinsic.versions}'); // e.g., [4, 5]
  final extensions = extrinsic.extensionsForVersion(5);
  for (final ext in extensions) {
    print('Extension: ${ext.identifier}, type: ${ext.type}, implicit: ${ext.implicit}');
  }

  // Deprecation tracking
  for (final pallet in metadata.pallets) {
    if (pallet.deprecationInfo.isDeprecated) {
      print('${pallet.name} is deprecated: ${pallet.deprecationInfo.note}');
    }

    // Per-variant deprecation on calls
    if (pallet.callsV16 != null) {
      final callDeprecation = pallet.callsV16!.deprecationInfo;
      // Check if a specific call variant is deprecated
      if (callDeprecation.isVariantDeprecated(0)) {
        final info = callDeprecation.getVariantDeprecation(0);
        print('Call variant 0 deprecated: ${info?.note}');
      }
    }
  }

  // Associated types
  for (final pallet in metadata.pallets) {
    for (final assocType in pallet.associatedTypes) {
      print('${pallet.name}.${assocType.name}: type ID ${assocType.type}');
    }
  }

  // View functions
  for (final pallet in metadata.pallets) {
    for (final viewFn in pallet.viewFunctions) {
      print('${pallet.name}.${viewFn.name}: ${viewFn.inputs.length} inputs, '
            'output type ${viewFn.output}');
      if (viewFn.deprecationInfo.isDeprecated) {
        print('  (deprecated: ${viewFn.deprecationInfo.note})');
      }
    }
  }

  // Runtime API versioning
  for (final api in metadata.apis) {
    print('${api.name} v${api.version}');
    if (api.deprecationInfo.isDeprecated) {
      print('  Deprecated: ${api.deprecationInfo.note}');
    }
    for (final method in api.methods) {
      if (method.deprecationInfo.isDeprecated) {
        print('  ${method.name} is deprecated');
      }
    }
  }
}
```

#### V16 Deprecation Model

V16 introduces a three-tier deprecation system:

```dart
// 1. ItemDeprecationInfo - for pallets, constants, storage, APIs
//    Variants: ItemNotDeprecated, ItemDeprecatedWithoutNote, ItemDeprecated
sealed class ItemDeprecationInfo {
  bool get isDeprecated;
  String? get note;   // Deprecation message (if provided)
  String? get since;  // Version since deprecated (if provided)
}

// 2. VariantDeprecationInfo - for individual call/event/error variants
//    Variants: VariantDeprecatedWithoutNote, VariantDeprecated
sealed class VariantDeprecationInfo {
  String? get note;
  String? get since;
}

// 3. EnumDeprecationInfo - maps variant indices to their deprecation info
class EnumDeprecationInfo {
  bool isVariantDeprecated(int variantIndex);
  VariantDeprecationInfo? getVariantDeprecation(int variantIndex);
}
```

#### V16 Backward Compatibility

Version routing is automatic. Code that works with V14/V15 continues to work unchanged:

```dart
// This works regardless of metadata version (V14, V15, or V16)
final prefixed = RuntimeMetadataPrefixed.fromBytes(metadataBytes);
final chainInfo = prefixed.buildChainInfo();

// Unified access via extension methods across all versions
final pallets = chainInfo.registry.metadata.pallets;
final extrinsic = chainInfo.registry.metadata.extrinsic;
final types = chainInfo.registry.metadata.types;

// Decode events and extrinsics the same way for all versions
final events = chainInfo.eventsCodec.decode(Input.fromHex(eventsHex));
final extrinsics = chainInfo.extrinsicsCodec.decode(Input.fromHex(blockExtrinsicsHex));
```

---

# Breaking Changes from 2.0.0 Version

This is a **major rewrite** of the `substrate_metadata` package. If you're upgrading from a pre `2.0.0` version, please read this section carefully.

### Removed: Legacy Metadata Support (V9-V13)

The new implementation **only supports Metadata V14, V15, and V16**. Support for legacy metadata versions V9 through V13 has been removed.

```dart
// OLD: Legacy versions were supported
final metadata = MetadataDecoder.instance.decode(hexString); // Worked with V9-V15

// NEW: Only V14, V15, and V16 are supported
final prefixed = RuntimeMetadataPrefixed.fromBytes(bytes); // V14, V15, or V16
```

**Impact**: If you're connecting to chains running very old runtimes (pre-V14), you'll need to upgrade those chains or use the legacy version of this package.

### Removed: `Chain` Class and Spec Version Management

The `Chain` class and the entire spec version management system have been removed. The old API managed multiple metadata versions indexed by block number.

```dart
// OLD API (removed)
final chain = Chain();
await chain.initSpecVersionFromFile('spec_versions.json');
final versionDesc = chain.getVersionDescription(blockNumber);
final decoded = chain.decodeExtrinsics(rawBlockExtrinsics);
final events = chain.decodeEvents(rawBlockEvents);

// NEW API
final prefixed = RuntimeMetadataPrefixed.fromBytes(metadataBytes);
final chainInfo = prefixed.buildChainInfo();
final decoded = chainInfo.extrinsicsCodec.decode(input);
final events = chainInfo.eventsCodec.decode(input);
```

**Migration**: Create a new `ChainInfo` instance when the chain's metadata changes (i.e., after a runtime upgrade).

### Removed: `MetadataDecoder` Singleton

The `MetadataDecoder.instance` singleton pattern has been replaced with direct static factory methods.

```dart
// OLD API (removed)
final decoded = MetadataDecoder.instance.decode(hexString);
final version = decoded.version;
final metadata = decoded.metadata;

// NEW API
final prefixed = RuntimeMetadataPrefixed.fromHex(hexString);
// or
final prefixed = RuntimeMetadataPrefixed.fromBytes(bytes);
final metadata = prefixed.metadata; // RuntimeMetadataV14, RuntimeMetadataV15, or RuntimeMetadataV16
```

### Removed: `DecodedMetadata`, `RawBlockExtrinsics`, `RawBlockEvents`

These wrapper classes have been removed. The new API works directly with codecs and typed models.

```dart
// OLD API (removed)
final rawBlock = RawBlockExtrinsics(blockNumber: 123, extrinsics: hexList);
final decoded = chain.decodeExtrinsics(rawBlock);  // DecodedBlockExtrinsics

// NEW API
final extrinsics = chainInfo.extrinsicsCodec.decode(Input.fromHex(blockExtrinsicsHex));
// Returns List<UncheckedExtrinsic> with strongly typed RuntimeCall
```

### Removed: `Constant<T>` Generic Class

The generic `Constant<T>` class with lazy value decoding has been replaced with `ConstantsCodec`.

```dart
// OLD API (removed)
final chainInfo = ChainInfo.fromMetadata(decoded, legacyTypes);
final constant = chainInfo.constants['Balances']!['ExistentialDeposit']!;
final value = constant.value;  // Decoded on access
final type = constant.type;    // Codec<T>
final docs = constant.docs;

// NEW API
final chainInfo = prefixed.buildChainInfo();
final value = chainInfo.constantsCodec.getConstant('Balances', 'ExistentialDeposit');
final info = chainInfo.constantsCodec.getConstantInfo('Balances', 'ExistentialDeposit');
// info.typeString, info.documentation, info.palletName, etc.

// For memory-efficient lazy loading:
final lazyCodec = LazyConstantsCodec(registry);
final value = lazyCodec.getConstant('Balances', 'ExistentialDeposit');
```

### Removed: `LegacyTypes`, `LegacyTypesBundle`, `LegacyParser`

All legacy type system components have been removed since V9-V13 support was dropped.

```dart
// OLD API (removed)
final legacyTypes = LegacyTypes(types: {...}, typesAlias: {...});
final chainInfo = ChainInfo.fromMetadata(decoded, legacyTypes);
```

**Migration**: These are no longer needed with V14+ metadata since all type information is self-contained in the metadata.

### Removed: Parsers (`V14Parser`, `TypeExpressionParser`, `TypeNormalizer`)

The parsers have been replaced with `MetadataTypeRegistry` which handles all type resolution internally.

```dart
// OLD API (removed)
final chainInfo = V14Parser.getChainInfo(decodedMetadata);

// NEW API
final registry = MetadataTypeRegistry(prefixedMetadata);
final codec = registry.codecFor(typeId);
```

### Changed: Event Decoding Returns Strongly Typed Models

```dart
// OLD API - returned List<dynamic>
final events = chain.decodeEvents(rawBlockEvents);
for (final event in events) {
  final pallet = event['pallet'];
  final name = event['name'];
  final data = event['data'];
}

// NEW API - returns List<EventRecord>
final events = chainInfo.eventsCodec.decode(input);
for (final record in events) {
  final pallet = record.event.palletName;    // String
  final name = record.event.eventName;       // String
  final data = record.event.data;            // Map<String, dynamic>
  final phase = record.phase;                // Phase (typed enum)
  final topics = record.topics;              // List<String>
}
```

### Changed: Extrinsic Decoding Returns Strongly Typed Models

```dart
// OLD API - returned List<Map>
final extrinsics = chain.decodeExtrinsics(rawBlockExtrinsics);
for (final ext in extrinsics) {
  final hash = ext['hash'];
  final calls = ext['calls'];
  final signature = ext['signature'];
}

// NEW API - returns List<UncheckedExtrinsic>
final extrinsics = chainInfo.extrinsicsCodec.decode(input);
for (final ext in extrinsics) {
  final version = ext.version;           // int
  final isSigned = ext.isSigned;         // bool
  final call = ext.call;                 // RuntimeCall
  final signature = ext.signature;       // ExtrinsicSignature?

  // Access call details
  print('${call.palletName}.${call.callName}');
  print('Args: ${call.args}');
}
```

### Changed: Type System Restructured

The `scale_info/` folder has been replaced with `metadata/common/type_def/`.

```dart
// OLD imports (removed)
import 'package:substrate_metadata/scale_info/scale_info.dart';
// TypeDef, TypeDefComposite, TypeDefVariant, Field, Variant, etc.

// NEW imports
import 'package:substrate_metadata/substrate_metadata.dart';
// Same types, different location in metadata/common/
```

### Changed: Dependencies Reduced

The package now has fewer dependencies:

| Removed | Kept | Added |
|---------|------|-------|
| `convert` | `pointycastle` | `hashlib_codecs` |
| `equatable` | `polkadart_scale_codec` | |
| `json_schema` | | |
| `polkadart` | | |
| `utility` | | |
| `cross_file` | | |

### Changed: Minimum Dart SDK Version

```yaml
# OLD
environment:
  sdk: ^3.6.0

# NEW
environment:
  sdk: ^3.8.0
```

### New: Built-in Substrate Hashers

Storage hashers are now built into this package.

```dart
import 'package:substrate_metadata/substrate_metadata.dart';

// Available hashers
final hash = Hasher.blake2b128.hash(bytes);
final hash = Hasher.blake2b256.hash(bytes);
final hash = Hasher.twoxx64.hash(bytes);
final hash = Hasher.twoxx128.hash(bytes);

// Storage key generation
final storageMap = StorageMap(
  prefix: 'System',
  storage: 'Account',
  hasher: StorageHasher.blake2b128Concat(accountIdCodec),
  valueCodec: accountInfoCodec,
);
final key = storageMap.hashedKeyFor(accountId);
```

### New: `LazyConstantsCodec` for Memory Optimization

```dart
// Load constants on-demand instead of all at once
final lazyCodec = LazyConstantsCodec(registry);

// Preload frequently used constants
lazyCodec.preloadConstants([
  ('Balances', 'ExistentialDeposit'),
  ('System', 'BlockHashCount'),
]);

// Check loading statistics
final stats = lazyCodec.getLoadingStats();
print('Loaded: ${stats['loadedConstants']}/${stats['totalConstants']}');
```

## Resources

- [Polkadart Repository](https://github.com/leonardocustodio/polkadart)
- [Polkadot Documentation](https://docs.polkadot.com/)
- [SCALE Codec Specification](https://docs.polkadot.com/polkadot-protocol/basics/data-encoding/)
- [Substrate Metadata](https://docs.substrate.io/build/application-dev/#metadata-system)
- [Polkadot.js](https://polkadot.js.org/)

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](./LICENSE) file for details.
