part of apis;

/// ChainHead API for the new Substrate JSON-RPC specification.
///
/// The chainHead API uses a follow/unfollow session model. Calling [follow]
/// creates a [ChainHeadSession] that wraps the subscription and provides
/// typed methods for querying block data.
///
/// Reference: https://paritytech.github.io/json-rpc-interface-spec/api/chainHead.html
class ChainHeadApi<P extends Provider> {
  final P _provider;

  const ChainHeadApi(this._provider);

  /// Start following the chain head.
  ///
  /// Creates a new follow subscription and returns a [ChainHeadSession]
  /// that can be used to query block data and receive chain events.
  ///
  /// Parameters:
  /// - [withRuntime]: If true, runtime information is included in events.
  Future<ChainHeadSession<P>> follow({bool withRuntime = false}) async {
    final subscription = await _provider.subscribe(
      'chainHead_v1_follow',
      [withRuntime],
      onCancel: (subscriptionId) async {
        await _provider.send('chainHead_v1_unfollow', [subscriptionId]);
      },
    );

    return ChainHeadSession<P>(
      provider: _provider,
      followSubscriptionId: subscription.id,
      rawStream: subscription.stream,
    );
  }
}

/// A session representing an active chainHead follow subscription.
///
/// Provides typed methods for all chainHead operations scoped to this
/// follow subscription. The session must be closed by calling [unfollow]
/// when no longer needed.
class ChainHeadSession<P extends Provider> {
  final P _provider;

  /// The subscription ID from the follow call.
  final String followSubscriptionId;

  /// The raw subscription stream from the provider.
  final Stream<SubscriptionMessage> _rawStream;

  /// Whether this session has been unfollowed.
  bool _unfollowed = false;

  ChainHeadSession({
    required P provider,
    required this.followSubscriptionId,
    required Stream<SubscriptionMessage> rawStream,
  }) : _provider = provider,
       _rawStream = rawStream;

  /// Stream of typed chain head events.
  ///
  /// Events include: initialized, newBlock, bestBlockChanged, finalized, stop.
  Stream<ChainHeadEvent> get stream =>
      _rawStream.map((message) => ChainHeadEvent.fromJson(message.result as Map<String, dynamic>));

  /// Get the header of a pinned block.
  ///
  /// Parameters:
  /// - [blockHash]: The hash of the pinned block.
  ///
  /// Returns the SCALE-encoded header as a hex string, or null if the block
  /// is not pinned.
  Future<String?> header(String blockHash) async {
    _ensureActive();
    final response = await _provider.send('chainHead_v1_header', [followSubscriptionId, blockHash]);

    if (response.error != null) {
      throw Exception(response.error.toString());
    }

    return response.result as String?;
  }

  /// Request the body (extrinsics) of a pinned block.
  ///
  /// Parameters:
  /// - [blockHash]: The hash of the pinned block.
  ///
  /// Returns a [ChainHeadOperationResult]. If `isStarted`, use the
  /// `operationId` to track the operation's progress via the event stream.
  Future<ChainHeadOperationResult> body(String blockHash) async {
    _ensureActive();
    final response = await _provider.send('chainHead_v1_body', [followSubscriptionId, blockHash]);

    if (response.error != null) {
      throw Exception(response.error.toString());
    }

    return ChainHeadOperationResult.fromJson(Map<String, dynamic>.from(response.result as Map));
  }

  /// Query storage items of a pinned block.
  ///
  /// Parameters:
  /// - [blockHash]: The hash of the pinned block.
  /// - [items]: List of storage items to query.
  /// - [childTrie]: Optional child trie key.
  ///
  /// Returns a [ChainHeadOperationResult]. If `isStarted`, use the
  /// `operationId` to track the operation's progress via the event stream.
  Future<ChainHeadOperationResult> storage(
    String blockHash,
    List<StorageQueryItem> items, {
    String? childTrie,
  }) async {
    _ensureActive();
    final params = <dynamic>[
      followSubscriptionId,
      blockHash,
      items.map((item) => item.toJson()).toList(),
    ];
    if (childTrie != null) {
      params.add(childTrie);
    }

    final response = await _provider.send('chainHead_v1_storage', params);

    if (response.error != null) {
      throw Exception(response.error.toString());
    }

    return ChainHeadOperationResult.fromJson(Map<String, dynamic>.from(response.result as Map));
  }

  /// Make a runtime call at a pinned block.
  ///
  /// Parameters:
  /// - [blockHash]: The hash of the pinned block.
  /// - [function]: The runtime function name, like "Metadata_metadata".
  /// - [callParameters]: Hex-encoded SCALE parameters for the call.
  ///
  /// Returns a [ChainHeadOperationResult]. If `isStarted`, use the
  /// `operationId` to track the operation's progress via the event stream.
  Future<ChainHeadOperationResult> call(
    String blockHash,
    String function,
    String callParameters,
  ) async {
    _ensureActive();
    final response = await _provider.send('chainHead_v1_call', [
      followSubscriptionId,
      blockHash,
      function,
      callParameters,
    ]);

    if (response.error != null) {
      throw Exception(response.error.toString());
    }

    return ChainHeadOperationResult.fromJson(Map<String, dynamic>.from(response.result as Map));
  }

  /// Unpin one or more previously-pinned blocks.
  ///
  /// Parameters:
  /// - [blockHashes]: List of block hashes to unpin.
  Future<void> unpin(List<String> blockHashes) async {
    _ensureActive();
    final response = await _provider.send('chainHead_v1_unpin', [
      followSubscriptionId,
      blockHashes,
    ]);

    if (response.error != null) {
      throw Exception(response.error.toString());
    }
  }

  /// Stop the follow subscription.
  ///
  /// After calling this method, the session is no longer active and
  /// no further operations can be performed.
  Future<void> unfollow() async {
    if (_unfollowed) return;
    _unfollowed = true;

    final response = await _provider.send('chainHead_v1_unfollow', [followSubscriptionId]);

    if (response.error != null) {
      throw Exception(response.error.toString());
    }
  }

  /// Whether this session is still active.
  bool get isActive => !_unfollowed;

  void _ensureActive() {
    if (_unfollowed) {
      throw StateError('ChainHeadSession has been unfollowed');
    }
  }
}
