## 1.0.1

- Updated `equatable` dependency constraint to `^2.0.8`
- Updated `json_annotation` dependency constraint to `^4.10.0`

## 1.0.0

### Breaking Changes
- **Complete architectural redesign** from custom type system to substrate-metadata integration
- Removed `InkAbiDescription` class - functionality absorbed by registry
- Removed `TypesNormalizer` class - no longer needed with substrate-metadata types
- Removed all custom interfaces in `/lib/interfaces/` directory
- Removed `/lib/utils/` directory
- Changed import path from `package:ink_abi/ink_abi_base.dart` to `package:ink_abi/ink_abi.dart`
- Field access changed from camelCase to snake_case (e.g., `totalSupply` → `total_supply`)
- `decodeEventFromHex()` merged into `decodeEvent()`

### Added
- **`InkMetadataRegistry`** New centralized registry handling all type resolution and codec management
- **Structured model classes** with JSON serialization:
  - `MessageSpec` - Message specification with selector, args, returnType, mutates, payable
  - `ConstructorSpec` - Constructor specification
  - `EventSpec` - Enhanced event specification replacing `InkAbiEvent`
  - `ArgSpec` - Argument specification with type info
  - `TypeSpec` - Type specification linking type IDs to display names
  - `TypeInfo` - Type information helper class
- **Exception hierarchy** with rich error context:
  - `InkAbiException` - Base exception with context support
  - `EncodingException` - Specialized for encoding failures with factory methods
  - `DecodingException` - Specialized for decoding failures
  - `InkEventException` - Event-specific exception
  - `TypeResolutionException` - Type lookup failures
- New `decodeConstructorOutput()` method
- New accessor methods: `messages`, `constructors`, `registry`
- `version` property getter

### Changed
- `InkAbi` now delegates to `InkMetadataRegistry` instead of managing codecs directly
- Leverages `substrate_metadata`'s `PortableRegistry` and `MetadataTypeRegistry` instead of custom implementation
- Converts ink! types to substrate `PortableType` format internally
- `SelectorByteInput` enhanced with proper error handling and validation

## 0.3.1

## 0.3.0

 - Bump polkadart version to 0.7.0

## 0.2.3
- Improves state mutation for ink smart contracts

## 0.2.2
- Upgrade `ink_abi` to work with the new version of `ink_cli`

## 0.2.1
- Packages were bumped for new publish workflow

## 0.2.0
- All packages have been bumped to add web support

## 0.1.0
- Removes `json_schema2` from being a required dependency

## 0.0.2
* Add CodecTypeInterfaces to support `ink_cli`

## 0.0.1
* Initial version if `ink_abi`
