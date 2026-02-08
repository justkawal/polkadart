## 1.1.0

### Changed
- Updated extrinsic builder with extension builder support
- Updated extrinsic encoder for V5 format
- Updated signing payload builder

## 1.0.0

### Breaking Changes
- **Extrinsic API completely redesigned** - Manual `SigningPayload` and `ExtrinsicPayload` replaced with fluent `ExtrinsicBuilder`
- Removed `SigningPayload`, `ExtrinsicPayload`, and related classes
- Removed `Transfers` class with static methods - replaced by `Balances` module
- Removed `substrate.dart` and `scale_codec.dart` wrapper libraries
- Removed `provider.dart` as standalone export - now part of `apis` library
- Multisig API changed from static methods to instance-based pattern

### Added
- **`ExtrinsicBuilder`** - New fluent API for building extrinsics:
  - Factory constructor: `ExtrinsicBuilder.fromChainData()` for automatic chain data integration
  - Configuration methods: `.nonce()`, `.tip()`, `.era()`, `.immortal()`, `.assetId()`, `.metadataHash()`
  - Signing methods: `signAndBuild()`, `signBuildAndSubmit()`, `signBuildAndSubmitWatch()`
  - Static `quickSend()` method for one-liner transaction submission
  - `SigningCallback` typedef: `Uint8List Function(Uint8List payload)`
- **Balances module** with builder pattern:
  - `Balances.transfer`, `Balances.transferKeepAlive`, `Balances.transferAll`, `Balances.forceTransfer`, `Balances.forceSetBalance`, `Balances.setBalanceDeprecated`
  - Three address input methods: `.to()` (SS58), `.toAccountId()` (pubkey), `.toMultiAddress()` (advanced)
  - Automatic conversion to `RuntimeCall` via `.toRuntimeCall(chainInfo)`
- **`ChainDataFetcher`** - Parallel fetching of chain state with structured `ChainData` return
- **`CallIndicesLookup`** - Helper for resolving pallet and call indices from metadata
- **`MultisigAccount`** class - Automatic multisig address derivation with validation
- **Enhanced `MultisigStorage`**:
  - Static `fetch()` method for async retrieval
  - Status methods: `hasApproved()`, `isDepositor()`, `isFinalApproval()`, `isComplete()`
  - `getStatus()` method returning `MultisigStorageStatus` object

### Changed
- **Multisig refactored** from static methods to instance-based:
  - Constructor: `Multisig({required provider, required chainInfo, required multisigAccount})`
  - Uses `SigningCallback` instead of `KeyPair` for signing
  - Instance methods: `createAndFundMultisig()`, `createCallData()`, `initiateTransfer()`, `approveAsMulti()`, `asMulti()`, `cancel()`
- Direct exports of `polkadart_scale_codec` and `substrate_metadata` in main library
- Provider classes moved to `/lib/apis/provider.dart` as part of APIs library

### Removed
- `primitives/runtime_metadata.dart` - replaced by direct substrate_metadata usage
- `primitives/transfers.dart` - replaced by balances module
- Multisig helper files: `multisig_meta.dart`, `signatories.dart`, `signatory.dart`, `exceptions.dart`, `extensions.dart`, `utilities.dart`
- Extrinsic files: `abstract_payload.dart`, `signing_payload.dart`, `extrinsic_payload.dart`, `signature_type.dart`
- Signed extensions: `asset_hub.dart`, `signed_extensions_abstract.dart`, `substrate.dart`

## 0.7.2

## 0.7.1

 - Bumps all dependencies

## 0.7.0
- Websocket provider now supports auto-reconnect

## 0.6.2
- Bumps `substrate_metadata` dependency for wasm support

## 0.6.1
- Fixes `multisig_meta` and adds 'CheckMetadataHash' extension functionality

## 0.6.0
- All packages have been bumped to add web support

## 0.5.0
- Removes `json_schema2` from being a required dependency

## 0.4.7
- Fixes `UnmodifiableUint8ListView` missing on newer dart versions

## 0.4.6
- Add missing error value parse for http provider

## 0.4.5
- Add support for CheckMetadataHash extension

## 0.4.4
- Fixes http provider when rpc sends a non integer ID

## 0.4.3
- Bumps keyring version

## 0.4.2
- Fixes extrinsics encoded with ecdsa signature

## 0.4.1
- Improves custom signed extensions

## 0.4.0
- Adds support for custom signed extensions and multisig accounts

## 0.3.2
- Fixes issue with AssetHub extrinsics

## 0.3.1
- Bump polkadart_keyring version

## 0.3.0

- Generate storage key prefix methods

## 0.2.6

- Fixes issue with subscribeStorage

## 0.2.5

- Fixes issue with hex signed 2's complement in xxh64 algorithm

## 0.2.4

- Fixes issue with xxh64 hash function

## 0.2.3

- Fix isConnected check for websocket provider

## 0.2.2

- Fixes issue to encode immortal transactions (eraPeriod = 0)

## 0.2.1

- Added AssetHub signed extensions.

## 0.2.0

- Added support for creating extrinsics and query RPC api and listen to events.

## 0.1.1

- Publishing packages under polkadart.dev publisher.

## 0.1.0

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 0.1.0-pre.2

- pre-release.

## 0.1.0-pre.1

- pre-release.

## 0.1.0

- Initial version.
