## 2.0.1

- Updated `equatable` dependency constraint to `^2.0.8`

## 2.0.0

### Breaking Changes
- **Removed `Registry` class** (metadata parsing logic) from core library
- **Removed `ScaleCodec` wrapper class** from core library
- Core library now only contains `Codec` mixin
- **Added required `isSizeZero()` method** to `Codec` mixin - all custom codecs must implement this

### Added
- **`LengthPrefixedCodec<T>`** - Generic wrapper adding Compact<u32> length prefix to any codec
  - Useful for Substrate variable-length encoding patterns
- **`ScaleRawBytes`** - Wrapper class for already-encoded SCALE bytes
  - Avoids decode/re-encode cycles
  - Codec writes raw bytes directly without encoding
  - Extends `Equatable` for value comparison
- **`Primitives` enum utility** - Maps primitive type names to codecs with static `fromString()` method
- **`isSizeZero()` implementations** across all primitives:
  - `NullCodec`: Returns `true` - always size zero
  - `CompositeCodec`: Returns `true` if empty OR all inner codecs are size zero
  - `U8ArrayCodec`: Returns `length == 0` - zero only if empty array
  - `OptionCodec`, `NestedOptionCodec`, `ResultCodec`, `U8Codec`, `U8SequenceCodec`, `LengthPrefixedCodec`: Return `false`
- **ResultCodec test coverage** - New test file with test cases for encoding/decoding Result types

### Changed
- Core library simplified to only contain `codec_mixin.dart`
- Main library now exports `extended_codecs/length_prefixed_codec.dart`
- Minor formatting improvements in `CompositeCodec` and `Option.none()` constructor

## 1.6.0

 - Update dependencies

## 1.5.1

- Fixes an issue where `StrCodec` would preserve null bytes from fixed-length strings in blockchain metadata, causing invalid string literals in generated code. The decoder now strips trailing null bytes from decoded strings.

## 1.5.0

 - Bump polkadart version to 0.7.0

## 1.4.2
- Fixes an issue when decoding a Bytes string

## 1.4.1
- Packages were bumped for new publish workflow

## 1.4.0
- All packages have been bumped to add web support

## 1.3.0
- Removes `json_schema2` from being a required dependency

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

## [1.1.0-pre.3] - 2023-03-22

### Prerelease version 3
- [#285](https://github.com/rankanizer/polkadart/pull/285) Improved Detection of cyclic dependencies
- [#288](https://github.com/rankanizer/polkadart/pull/288) Scale-Codec examples
- [#295](https://github.com/rankanizer/polkadart/pull/295) Update Readme

## [1.1.0-pre.2] - 2023-03-21

### Prerelease version 2
- [#261](https://github.com/rankanizer/polkadart/pull/261) Support sparse enums
- [#266](https://github.com/rankanizer/polkadart/pull/266) Implements Extrinsics Encode/Decode functionality.

## [1.1.0-pre.1] - 2023-03-21

### Prerelease version
- [#283](https://github.com/rankanizer/polkadart/pull/283) Removed `HexInput`, now must use `Input.fromHex()`
- [#283](https://github.com/rankanizer/polkadart/pull/283) Use `Uint8Buffer` instead `BytesBuilder` when enconding.

## [1.0.0] - 2022-08-24

### First Version
- First Initialized Version
