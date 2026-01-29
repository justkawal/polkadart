library metadata;

import 'dart:math';
import 'dart:typed_data' show Uint8List;

import 'package:polkadart_scale_codec/polkadart_scale_codec.dart';
import 'package:substrate_metadata/chain/chain_info.dart' show ChainInfo;
import 'package:substrate_metadata/registry/metadata_type_registry.dart' show MetadataTypeRegistry;
import 'package:substrate_metadata/substrate_hashers/substrate_hashers.dart' show Blake3Hasher;
import 'package:substrate_metadata/utils/utils.dart';

part 'merkleize.dart';

// Common
part 'common/extrinsic_metadata.dart';
part 'common/field.dart';
part 'common/portable_type.dart';
part 'common/portable_type_def.dart';
part 'common/type_parameter.dart';
part 'common/variant_def.dart';
part 'common/outer_enums.dart';

// Common -> Pallet
part 'common/pallet/pallet_call_metadata.dart';
part 'common/pallet/pallet_constant_metadata.dart';
part 'common/pallet/pallet_error_metadata.dart';
part 'common/pallet/pallet_event_metadata.dart';
part 'common/pallet/pallet_metadata.dart';
part 'common/pallet/pallet_storage_metadata.dart';
// Common -> Storage
part 'common/storage/storage_entry_metadata.dart';
part 'common/storage/storage_entry_modifier.dart';
part 'common/storage/storage_entry_type.dart';
part 'common/storage/storage_hasher.dart';
// Common -> TypeDefVariant
part 'common/type_def/type_def.dart';
part 'common/type_def/type_def_array.dart';
part 'common/type_def/type_def_compact.dart';
part 'common/type_def/type_def_composite.dart';
part 'common/type_def/type_def_primitive.dart';
part 'common/type_def/type_def_sequence.dart';
part 'common/type_def/type_def_tuple.dart';
part 'common/type_def/type_def_variant_type.dart';
part 'common/type_def/type_def_bit_sequence.dart';

//
// V14 -> Pallet
part 'v14/pallet/pallet_metadata_v14.dart';
// V14 -> Runtime
part 'runtime_metadata_prefixed.dart';
part 'v14/runtime/runtime_metadata_v14.dart';
// V14 -> Extrinsic
part 'v14/extrinsic_metadata_v14.dart';

//
// V15 -> Pallet
part 'v15/pallet/pallet_metadata_v15.dart';
// V15 -> Runtime
part 'v15/runtime/runtime_api_metadata_v15.dart';
part 'v15/runtime/runtime_metadata_v15.dart';
// V15 -> Extrinsic
part 'v15/extrinsic_metadata_v15.dart';
part 'v15/custom_metadata_v15.dart';

//
// V16 -> Common
part 'v16/deprecation_info.dart';
part 'v16/transaction_extension_metadata.dart';
// V16 -> Pallet
part 'v16/pallet/pallet_metadata_v16.dart';
part 'v16/pallet/pallet_call_metadata_v16.dart';
part 'v16/pallet/pallet_event_metadata_v16.dart';
part 'v16/pallet/pallet_error_metadata_v16.dart';
part 'v16/pallet/pallet_constant_metadata_v16.dart';
part 'v16/pallet/pallet_storage_metadata_v16.dart';
part 'v16/pallet/pallet_associated_type_metadata.dart';
part 'v16/pallet/pallet_view_function_metadata.dart';
// V16 -> Storage
part 'v16/storage/storage_entry_metadata_v16.dart';
// V16 -> Runtime
part 'v16/runtime/runtime_api_metadata_v16.dart';
part 'v16/runtime/runtime_metadata_v16.dart';
// V16 -> Extrinsic
part 'v16/extrinsic_metadata_v16.dart';
