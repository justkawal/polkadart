part of apis;

/// Transaction API for the new Substrate JSON-RPC specification.
///
/// Provides methods to broadcast and manage transactions using the
/// subscription-based `transaction_v1_*` RPC methods.
///
/// Reference: https://paritytech.github.io/json-rpc-interface-spec/api/transaction.html
class TransactionApi<P extends Provider> {
  final P _provider;

  const TransactionApi(this._provider);

  /// Broadcasts a transaction to the network.
  ///
  /// This method initiates a subscription that tracks the lifecycle of the
  /// transaction. The returned [TransactionBroadcast] contains an operation ID
  /// that can be used to stop the broadcast, and a stream of events.
  ///
  /// Parameters:
  /// - [extrinsic]: The SCALE-encoded extrinsic bytes to broadcast
  ///
  /// Returns a [TransactionBroadcast] with the operation ID and event stream.
  Future<TransactionBroadcast> broadcast(Uint8List extrinsic) async {
    final List<dynamic> params = ['0x${hex.encode(extrinsic)}'];

    final subscription = await _provider.subscribe(
      'transaction_v1_broadcast',
      params,
      onCancel: (subscriptionId) async {
        await _provider.send('transaction_v1_stop', [subscriptionId]);
      },
    );

    return TransactionBroadcast(
      operationId: subscription.id,
      stream: subscription.stream.map((message) => message.result),
    );
  }

  /// Stops an ongoing broadcast operation.
  ///
  /// Parameters:
  /// - [operationId]: The operation ID returned by [broadcast]
  Future<void> stop(String operationId) async {
    final response = await _provider.send('transaction_v1_stop', [operationId]);

    if (response.error != null) {
      throw Exception(response.error.toString());
    }
  }
}

/// Result of a transaction broadcast operation.
class TransactionBroadcast {
  /// The unique operation ID for this broadcast.
  final String operationId;

  /// Stream of events related to this broadcast.
  final Stream<dynamic> stream;

  const TransactionBroadcast({required this.operationId, required this.stream});
}
