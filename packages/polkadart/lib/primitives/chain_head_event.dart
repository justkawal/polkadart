part of primitives;

/// Event types emitted by the chainHead follow subscription.
enum ChainHeadEventType {
  initialized,
  newBlock,
  bestBlockChanged,
  finalized,
  stop,
  operationBodyDone,
  operationCallDone,
  operationStorageItems,
  operationStorageDone,
  operationError,
  operationInaccessible,
}

/// Base class for chainHead follow events.
abstract class ChainHeadEvent {
  final ChainHeadEventType type;

  const ChainHeadEvent(this.type);

  /// Parse a chainHead event from a JSON map.
  factory ChainHeadEvent.fromJson(Map<String, dynamic> json) {
    final String event = json['event'] as String;
    switch (event) {
      case 'initialized':
        return ChainHeadInitialized.fromJson(json);
      case 'newBlock':
        return ChainHeadNewBlock.fromJson(json);
      case 'bestBlockChanged':
        return ChainHeadBestBlockChanged.fromJson(json);
      case 'finalized':
        return ChainHeadFinalized.fromJson(json);
      case 'stop':
        return const ChainHeadStop();
      case 'operationBodyDone':
        return ChainHeadOperationBodyDone.fromJson(json);
      case 'operationCallDone':
        return ChainHeadOperationCallDone.fromJson(json);
      case 'operationStorageItems':
        return ChainHeadOperationStorageItems.fromJson(json);
      case 'operationStorageDone':
        return ChainHeadOperationStorageDone.fromJson(json);
      case 'operationError':
        return ChainHeadOperationError.fromJson(json);
      case 'operationInaccessible':
        return ChainHeadOperationInaccessible.fromJson(json);
      default:
        throw Exception('Unknown chainHead event type: $event');
    }
  }
}

/// Emitted when the follow subscription is initialized.
///
/// Contains the finalized block hash and optionally the runtime spec.
class ChainHeadInitialized extends ChainHeadEvent {
  /// Hash of the latest finalized block.
  final String finalizedBlockHash;

  /// Runtime specification, if `withRuntime` was true.
  final Map<String, dynamic>? finalizedBlockRuntime;

  const ChainHeadInitialized({required this.finalizedBlockHash, this.finalizedBlockRuntime})
    : super(ChainHeadEventType.initialized);

  factory ChainHeadInitialized.fromJson(Map<String, dynamic> json) {
    return ChainHeadInitialized(
      finalizedBlockHash: json['finalizedBlockHashes'] is List
          ? (json['finalizedBlockHashes'] as List).first as String
          : json['finalizedBlockHash'] as String,
      finalizedBlockRuntime: json['finalizedBlockRuntime'] as Map<String, dynamic>?,
    );
  }
}

/// Emitted when a new non-finalized block is imported.
class ChainHeadNewBlock extends ChainHeadEvent {
  /// Hash of the new block.
  final String blockHash;

  /// Hash of the parent block.
  final String parentBlockHash;

  /// New runtime specification if a runtime upgrade happened.
  final Map<String, dynamic>? newRuntime;

  const ChainHeadNewBlock({required this.blockHash, required this.parentBlockHash, this.newRuntime})
    : super(ChainHeadEventType.newBlock);

  factory ChainHeadNewBlock.fromJson(Map<String, dynamic> json) {
    return ChainHeadNewBlock(
      blockHash: json['blockHash'] as String,
      parentBlockHash: json['parentBlockHash'] as String,
      newRuntime: json['newRuntime'] as Map<String, dynamic>?,
    );
  }
}

/// Emitted when the best block changes.
class ChainHeadBestBlockChanged extends ChainHeadEvent {
  /// Hash of the new best block.
  final String bestBlockHash;

  const ChainHeadBestBlockChanged({required this.bestBlockHash})
    : super(ChainHeadEventType.bestBlockChanged);

  factory ChainHeadBestBlockChanged.fromJson(Map<String, dynamic> json) {
    return ChainHeadBestBlockChanged(bestBlockHash: json['bestBlockHash'] as String);
  }
}

/// Emitted when blocks are finalized.
class ChainHeadFinalized extends ChainHeadEvent {
  /// Hashes of the newly finalized blocks, ordered by block number.
  final List<String> finalizedBlockHashes;

  /// Hashes of blocks that were pruned (no longer part of any fork).
  final List<String> prunedBlockHashes;

  const ChainHeadFinalized({required this.finalizedBlockHashes, required this.prunedBlockHashes})
    : super(ChainHeadEventType.finalized);

  factory ChainHeadFinalized.fromJson(Map<String, dynamic> json) {
    return ChainHeadFinalized(
      finalizedBlockHashes: (json['finalizedBlockHashes'] as List).cast<String>(),
      prunedBlockHashes: (json['prunedBlockHashes'] as List).cast<String>(),
    );
  }
}

/// Emitted when the subscription is stopped by the server.
class ChainHeadStop extends ChainHeadEvent {
  const ChainHeadStop() : super(ChainHeadEventType.stop);
}

/// Emitted when a `body()` operation completes successfully.
class ChainHeadOperationBodyDone extends ChainHeadEvent {
  /// The operation ID that was returned by `body()`.
  final String operationId;

  /// The hex-encoded extrinsics of the block body.
  final List<String> value;

  const ChainHeadOperationBodyDone({required this.operationId, required this.value})
    : super(ChainHeadEventType.operationBodyDone);

  factory ChainHeadOperationBodyDone.fromJson(Map<String, dynamic> json) {
    return ChainHeadOperationBodyDone(
      operationId: json['operationId'] as String,
      value: (json['value'] as List).cast<String>(),
    );
  }
}

/// Emitted when a `call()` operation completes successfully.
class ChainHeadOperationCallDone extends ChainHeadEvent {
  /// The operation ID that was returned by `call()`.
  final String operationId;

  /// The hex-encoded output of the runtime call.
  final String output;

  const ChainHeadOperationCallDone({required this.operationId, required this.output})
    : super(ChainHeadEventType.operationCallDone);

  factory ChainHeadOperationCallDone.fromJson(Map<String, dynamic> json) {
    return ChainHeadOperationCallDone(
      operationId: json['operationId'] as String,
      output: json['output'] as String,
    );
  }
}

/// A single storage item returned by a `storage()` operation.
class StorageResultItem {
  /// The storage key.
  final String key;

  /// The storage value (hex-encoded), if queried with type "value".
  final String? value;

  /// The storage hash, if queried with type "hash".
  final String? hash;

  const StorageResultItem({required this.key, this.value, this.hash});

  factory StorageResultItem.fromJson(Map<String, dynamic> json) {
    return StorageResultItem(
      key: json['key'] as String,
      value: json['value'] as String?,
      hash: json['hash'] as String?,
    );
  }
}

/// Emitted when a `storage()` operation returns partial results.
///
/// Multiple `operationStorageItems` events may be emitted for a single
/// operation before the final `operationStorageDone`.
class ChainHeadOperationStorageItems extends ChainHeadEvent {
  /// The operation ID that was returned by `storage()`.
  final String operationId;

  /// The storage items returned in this batch.
  final List<StorageResultItem> items;

  const ChainHeadOperationStorageItems({required this.operationId, required this.items})
    : super(ChainHeadEventType.operationStorageItems);

  factory ChainHeadOperationStorageItems.fromJson(Map<String, dynamic> json) {
    return ChainHeadOperationStorageItems(
      operationId: json['operationId'] as String,
      items: (json['items'] as List)
          .map((item) => StorageResultItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Emitted when a `storage()` operation has finished delivering all items.
class ChainHeadOperationStorageDone extends ChainHeadEvent {
  /// The operation ID that was returned by `storage()`.
  final String operationId;

  const ChainHeadOperationStorageDone({required this.operationId})
    : super(ChainHeadEventType.operationStorageDone);

  factory ChainHeadOperationStorageDone.fromJson(Map<String, dynamic> json) {
    return ChainHeadOperationStorageDone(operationId: json['operationId'] as String);
  }
}

/// Emitted when an operation fails with an error.
class ChainHeadOperationError extends ChainHeadEvent {
  /// The operation ID of the failed operation.
  final String operationId;

  /// Human-readable error message.
  final String error;

  const ChainHeadOperationError({required this.operationId, required this.error})
    : super(ChainHeadEventType.operationError);

  factory ChainHeadOperationError.fromJson(Map<String, dynamic> json) {
    return ChainHeadOperationError(
      operationId: json['operationId'] as String,
      error: json['error'] as String,
    );
  }
}

/// Emitted when the block was unpinned before the operation could complete.
class ChainHeadOperationInaccessible extends ChainHeadEvent {
  /// The operation ID of the inaccessible operation.
  final String operationId;

  const ChainHeadOperationInaccessible({required this.operationId})
    : super(ChainHeadEventType.operationInaccessible);

  factory ChainHeadOperationInaccessible.fromJson(Map<String, dynamic> json) {
    return ChainHeadOperationInaccessible(operationId: json['operationId'] as String);
  }
}

/// Result of a chainHead operation that returns an operationId.
class ChainHeadOperationResult {
  final String result;
  final String? operationId;

  const ChainHeadOperationResult({required this.result, this.operationId});

  factory ChainHeadOperationResult.fromJson(Map<String, dynamic> json) {
    return ChainHeadOperationResult(
      result: json['result'] as String,
      operationId: json['operationId'] as String?,
    );
  }

  bool get isStarted => result == 'started';
  bool get isLimitReached => result == 'limitReached';
}

/// Storage query item for chainHead_v1_storage.
class StorageQueryItem {
  /// The storage key to query.
  final String key;

  /// The type of query: "value", "hash", "closestDescendantMerkleValue",
  /// or "descendantsValues"/"descendantsHashes".
  final String queryType;

  const StorageQueryItem({required this.key, required this.queryType});

  Map<String, dynamic> toJson() => {'key': key, 'type': queryType};
}
