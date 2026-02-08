## 2.0.1

- Updated `equatable` dependency constraint to `^2.0.8`
- Updated `json_annotation` dependency constraint to `^4.10.0`

## 2.0.0

### Breaking Changes
- **`RegistryItem` simplified**
  - Removed: `displayName`, `symbols`, `decimals`, `standardAccount`, `website`
  - Kept: `prefix`, `network` only
- **`Registry.fromJsonString()` renamed** to `Registry.fromMap()` accepting `List<Map<String, dynamic>>`
- Registry data format changed from JSON string to typed Dart list
- Constructor is now public and const

### Added
- **`Address.tryDecode()`** - Safe decoding that returns null instead of throwing exceptions
- **Cached Blake2b instance** for better performance (avoids algorithm instantiation per hash)
- **Exceptions export** - Exception classes now publicly exported
- **Comprehensive test suite** covering all functionality
- **60 new networks** - Registry expanded from 93 to 153 networks:
  - Notable additions: karmachain (21), vara (137), bittensor (13116), mythos (29972)
  - Also: sora_dot_para, frequency, allfeat_network, metaquity_network, curio, ternoa, krest, societal, logion, vow-chain, moonsama, peerplays, krigan, golden_gate, t3rn, impact, analog-timechain, goro, mosaic-chain, xcavate, and many more

### Changed
- Registry data updated from 04/08/2022 to 07/12/2025
- `UnmodifiableListView` used in `Registry.items` getter instead of creating copies
- Documentation URL updated from substrate.io to docs.polkadot.com
- Code generation: Added `json_annotation` and generated `registry_item.g.dart`
- Example code improved with `final` keyword usage

### Improved
- Exception documentation clarified (e.g., "Invalid CheckSum Exception" comment fix)
- Simplified example documentation in exception classes

## 1.3.1
- Packages were bumped for new publish workflow

## 1.3.0
- All packages have been bumped to add web support

## 1.2.0
- Removes `json_schema2` from being a required dependency

## 1.1.3
- Fixes `UnmodifiableUint8ListView` missing on newer dart versions

## 1.1.2
- License update

## 1.1.1
- Publishing packages under polkadart.dev publisher

## 1.1.0
 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## [1.1.0-pre.1] - 2023-03-21

### Prerelease version
- [#280](https://github.com/rankanizer/polkadart/pull/280) Move `ss58_codec` logic to `ss58`
- [#283](https://github.com/rankanizer/polkadart/pull/283) `Address.withPrefix(newPrefix)` for change the address prefix
- [#283](https://github.com/rankanizer/polkadart/pull/283) Accept a custom prefix at `Address.encode(prefix: 42)`

## [1.0.0] - 2022-08-24

### First Version
- First Initialized Version
