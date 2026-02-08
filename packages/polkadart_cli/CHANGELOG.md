## 1.0.1

- Fixed multi-query methods to decode storage value instead of key

## 1.0.0

### Breaking Changes
- **Metadata API migration**: `getTypedMetadata()` → `getMetadata()`, `metadata.runtimeMetadataVersion()` → `metadata.version`
- **SCALE codec import update**: `package:polkadart/scale_codec.dart` → `package:polkadart_scale_codec/polkadart_scale_codec.dart`
- Pallet generator now imports from `package:polkadart_scale_codec/io/io.dart`

### Changed
- Storage type parsing modernized using Dart 3+ pattern matching with sealed types (`StorageEntryTypePlain`, `StorageEntryTypeMap`)
- Replaced switch-case with pattern matching for `StorageHasherEnum`
- Outer enums extraction improved with conditional inclusion (checks for -1 sentinel values)
- Runtime call variant matching by original name with case-insensitive comparison
- Multi-query type casting: intelligent unwrapping of typedefs, only adds `.asA()` cast for Sequence/Array types with non-primitive elements

### Added
- New type exports: `SequenceDescriptor`, `ArrayDescriptor`, `PrimitiveDescriptor`

### Improved
- Code formatting consistency throughout config, generator, and typegen files
- Better parameter alignment and trailing commas

## 0.7.2

## 0.7.1
- Adds support for multi-queries for single storage keys

## 0.7.0
- Bump polkadart version to 0.7.0

## 0.6.2
- Downgrade `substrate_metadata` to 1.4.1

## 0.6.1
- Packages were bumped for new publish workflow

## 0.6.0
- All packages have been bumped to add web support

## 0.5.0
- Removes `json_schema2` from being a required dependency

## 0.4.3
- Fixes `UnmodifiableUint8ListView` missing on newer dart versions

## 0.4.2
- Bump polkadart dependency

## 0.4.1
- Bump dependency requirements

## 0.4.0
- Bump polkadart dependency

## 0.3.2
- Makes params from runtime calls strongly typed

## 0.3.1
- Fixes issues with generating extrinsics called 'call'

## 0.3.0

- Generate storage key prefix methods

## 0.2.4

- Added method for getting a storage key

## 0.2.3

- Bump code_builder min version to 4.8.0 to stop using deprecated APIs

## 0.2.2

- Fixes issue with enum type generation

## 0.2.1

- Fixes polkadart dependency version

## 0.2.0

- Adds generator for system calls and extrinsics calls.

## 0.1.1

- Publishing packages under polkadart.dev publisher

## 0.1.0

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 0.1.0-pre.1

- Initial version.
