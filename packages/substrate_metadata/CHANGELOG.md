## 2.1.0

### Changed
- Updated `SignedExtensionsCodec` for V16 compatibility
- Updated `UncheckedExtrinsicCodec` for V16 extrinsic format
- Updated `MetadataTypeRegistry` for V16 type resolution
- Updated merkleization utilities

## 2.0.0

### Breaking Changes
- **Complete architectural rewrite** - Native Dart codec-based system replaces type-definition approach
- **Dropped metadata versions v9-v13** - Now supports only V14 and V15 with native codecs
- **Removed entire `definitions/` directory** with type definition maps for all versions
- **Removed `parsers/` directory** - LegacyParser, V14Parser, type expression parser, type normalizer
- **Removed `core/metadata_decoder.dart`** with RegistryCreator pattern
- **Removed `scale_info/` library** - merged into metadata/common/
- **`ChainInfo` completely redesigned** from simple model to comprehensive facade

### Added
- **`MetadataTypeRegistry`** - Intelligent type registry with:
  - Codec caching system for performance
  - Type path lookup caching
  - Proxy codec pattern for handling recursive types
  - O(1) pallet lookups by name and index
  - Comprehensive API for storage, constants, extrinsics, runtime APIs
  - Special handling for Option, Result, and common composite types
  - BitSequence codec building with store/order resolution
  - Cache statistics tracking
- **Derived codecs library** (`derived_codecs/`):
  - `EventsRecordCodec` - Decodes Vec<EventRecord> from System.Events storage
  - `RuntimeEventCodec` - Decodes runtime events with pallet/event lookup
  - `PhaseCodec` - Decodes event phase (ApplyExtrinsic, Finalization, Initialization)
  - `ExtrinsicsCodec` - Decodes block extrinsics
  - `UncheckedExtrinsicCodec` - Handles signed/unsigned extrinsics
  - `RuntimeCallCodec` - Encodes/decodes runtime calls
  - `ExtrinsicSignatureCodec` - Handles extrinsic signatures with signed extensions
  - `ConstantsCodec` and `LazyConstantsCodec` - Type-safe constant access
  - `Era` utility class - Mortal/immortal era encoding
- **`ChainInfo` facade** - Unified access to registry + pre-built derived codecs:
  - Factory methods: `fromMetadata(bytes)`, `fromRuntimeMetadataPrefixed(prefixed)`
  - Convenience methods: `decodeEvents()`, `decodeExtrinsics()`, `getConstant()`
  - Access to pallets and pallet lookup
- **Substrate hashers library** (`substrate_hashers/`):
  - Blake3, Blake2b hashers
  - XXH64 implementation with sink
  - Block hash utilities
- **Unified metadata structure**:
  - Sealed `RuntimeMetadata` base class with V14/V15 variants
  - `RuntimeMetadataPrefixed` with built-in codec
  - Common abstractions shared between v14/v15 in `common/` directory
- **Simplified models**:
  - `EventRecord` - Clean event record structure with phase, event, topics
  - `RuntimeEvent` - Pallet name/index, event name/index, data map
  - `RuntimeCall` - Similar structure for calls
  - `UncheckedExtrinsic` - Signature option, function, era, hash
  - `ExtrinsicSignature` - Address, signature, extra/extensions
  - `Phase` enum - ApplyExtrinsic, Finalization, Initialization
  - `PortableRegistry` - Simple wrapper with `getType(id)` method
- **Utils reorganization**:
  - `hex_extension.dart` - String hex utilities
  - `primitive_extension.dart` - Primitive to Codec mapping
  - `runtime_metadata_extension.dart` - Version-agnostic extensions for pallets, extrinsic, types, outerEnums

### Removed
- All `/lib/definitions/` files (metadata v9-v15 definitions, substrate types, bundles)
- `/lib/exceptions/exceptions.dart`
- All `/lib/parsers/` files
- All `/lib/scale_info/` files
- `/lib/types/` directory
- `/lib/models/` subdirectories (error_metadata, events, function, module_metadata, pallet, portable, si0_type, si1_type, decoded_block, raw_block)
- `/lib/utils/functions.dart` and `/lib/utils/spec_version_maker.dart`
- `/lib/constants/spec_version_schema.dart`

### Changed
- Tests moved from `/test/chains/` to `/test/chain_tests/` with v14 subdirectories
- Era handling moved from `/types/era_extrinsic.dart` to `/derived_codecs/era_codec.dart`

### Key Improvements
- **Performance**: Codec caching, type path caching, O(1) pallet lookups
- **API Clarity**: ChainInfo facade, MetadataTypeRegistry comprehensive API
- **Type Safety**: Sealed classes, pattern matching, direct codec implementations
- **Maintainability**: Single source of truth for metadata, no parser layer
- **Features**: Native V15 support with runtime APIs and outer enums

## 1.6.0

## 1.5.0

 - Bump polkadart version to 0.7.0

## 1.4.2
- Removed `dart:io` for wasm support

## 1.4.1
- Packages were bumped for new publish workflow

## 1.4.0
- All packages have been bumped to add web support

## 1.3.0
- Removes `json_schema2` from being a required dependency

## 1.2.3
- Fixes: Exception: Type not found for `MinInflation`

## 1.2.2
- Fixes `toJson()` when decoding BitArray`s

## 1.2.1
- Fixes `UnmodifiableUint8ListView` missing on newer dart versions

## 1.2.0
- Adds support for custom signed extensions

## 1.1.2

- License update

## 1.1.1

- Publishing packages under polkadart.dev publisher

## 1.1.0

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## [1.1.0-pre.1] - 2023-03-21

### Pre-release
- Pre-release 1

## [1.0.0] - 2022-09-21

### First Version
- First Initialized Version
