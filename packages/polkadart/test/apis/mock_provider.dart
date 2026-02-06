import 'dart:async' show Future, FutureOr, Stream, StreamController;
import 'package:polkadart/polkadart.dart'
    show Provider, RpcResponse, SubscriptionMessage, SubscriptionResponse;

/// Callback that produces a subscription stream for testing.
///
/// Returns the subscription ID and a stream of events to emit.
typedef SubscriptionCallback<S> =
    (String subscriptionId, Stream events) Function(List<dynamic> params, S state);

/// The Mock Provider allows mock requests and subscriptions.
class MockProvider<S> extends Provider {
  MockProvider(this._state) : super();

  /// Custom State
  final S _state;

  /// Maps the methods to the mock responses
  final Map<String, dynamic Function(List<dynamic>, S)> _callbacks = {};

  /// Maps subscription methods to callbacks that produce event streams
  final Map<String, SubscriptionCallback<S>> _subscriptionCallbacks = {};

  /// Tracks active subscription controllers for cleanup
  final Map<String, StreamController<SubscriptionMessage>> _activeSubscriptions = {};

  // Sequence used to generate unique query ids
  int _sequence = 0;

  void setMethodCallback(String method, dynamic Function(List<dynamic>, S) callback) {
    _callbacks[method] = callback;
  }

  /// Register a callback for a subscription method.
  ///
  /// The callback should return a tuple of (subscriptionId, eventStream).
  /// The eventStream will be forwarded as SubscriptionMessage results.
  void setSubscriptionCallback(String method, SubscriptionCallback<S> callback) {
    _subscriptionCallbacks[method] = callback;
  }

  @override
  Future<RpcResponse> send(String method, List<dynamic> params) async {
    if (_callbacks[method] == null) {
      throw Exception('MockProvider: The callback for the method "$method" isn\'t defined');
    }

    final response = _callbacks[method]!(params, _state);
    return RpcResponse(id: ++_sequence, result: response);
  }

  @override
  Future<SubscriptionResponse> subscribe(
    String method,
    List params, {
    FutureOr<void> Function(String subscription)? onCancel,
  }) async {
    final subscriptionCallback = _subscriptionCallbacks[method];
    if (subscriptionCallback == null) {
      throw Exception(
        'MockProvider: The subscription callback for "$method" isn\'t defined. '
        'Use setSubscriptionCallback() to register one.',
      );
    }

    final (subscriptionId, eventStream) = subscriptionCallback(params, _state);

    final controller = StreamController<SubscriptionMessage>.broadcast(
      onCancel: () async {
        if (onCancel != null) {
          await onCancel(subscriptionId);
        }
        _activeSubscriptions.remove(subscriptionId);
      },
    );

    _activeSubscriptions[subscriptionId] = controller;

    // Forward events from the source stream into subscription messages
    eventStream.listen(
      (event) {
        if (!controller.isClosed) {
          controller.add(
            SubscriptionMessage(method: method, subscription: subscriptionId, result: event),
          );
        }
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
      onDone: () {
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    return SubscriptionResponse(id: subscriptionId, stream: controller.stream);
  }

  /// Close all active subscriptions (for test teardown).
  Future<void> closeAllSubscriptions() async {
    for (final controller in _activeSubscriptions.values) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
    _activeSubscriptions.clear();
  }

  @override
  Future connect() {
    return Future.value();
  }

  @override
  Future disconnect() {
    return Future.value();
  }

  @override
  bool isConnected() {
    return true;
  }
}
