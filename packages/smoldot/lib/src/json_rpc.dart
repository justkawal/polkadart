import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'bindings.dart';
import 'types.dart';

/// Global callback registry for JSON-RPC responses
final Map<int, Completer<String>> _jsonRpcCallbackRegistry = {};

/// Global JSON-RPC callback - called from Rust
void _jsonRpcCallback(int callbackId, int result, Pointer<Utf8> error) {
  final completer = _jsonRpcCallbackRegistry.remove(callbackId);
  if (completer == null) {
    print('Warning: No completer found for JSON-RPC callback ID $callbackId');
    return;
  }

  if (error != nullptr) {
    final errorMsg = error.toDartString();
    completer.completeError(JsonRpcException('JSON-RPC error: $errorMsg'));
  } else {
    // result contains pointer to response string
    final responsePtr = Pointer<Utf8>.fromAddress(result);
    final responseJson = responsePtr.toDartString();
    completer.complete(responseJson);
  }
}

/// Handles JSON-RPC requests and subscriptions for a chain
///
/// This class manages the JSON-RPC communication with smoldot,
/// including request/response handling and subscription management.
class JsonRpcHandler {
  /// Chain identifier (handle from Rust)
  final int chainId;

  /// FFI bindings
  final SmoldotBindings bindings;

  /// Native client handle (u64 from Rust)
  final int clientHandle;

  /// Request ID counter
  int _requestId = 0;

  /// Callback ID counter
  int _callbackId = 0;

  /// Pending requests map (request ID -> completer)
  final Map<String, Completer<JsonRpcResponse>> _pendingRequests = {};

  /// Active subscriptions map (subscription ID -> stream controller)
  final Map<String, StreamController<JsonRpcResponse>> _subscriptions = {};

  /// Pending subscription requests (request ID -> stream controller)
  final Map<String, StreamController<JsonRpcResponse>> _pendingSubscriptions =
      {};

  /// Native callback for JSON-RPC responses
  late final NativeCallable<DartCallbackNative> _nativeCallable;
  late final Pointer<NativeFunction<DartCallbackNative>> _nativeCallback;

  /// Creates a new JSON-RPC handler
  JsonRpcHandler({
    required this.chainId,
    required this.bindings,
    required this.clientHandle,
  }) {
    _nativeCallable = NativeCallable<DartCallbackNative>.listener(
      _jsonRpcCallback,
    );
    _nativeCallback = _nativeCallable.nativeFunction;
  }

  /// Send a JSON-RPC request
  ///
  /// Returns a [Future] that completes with the response.
  Future<JsonRpcResponse> request(String method, List<dynamic> params) async {
    final id = _generateRequestId();

    final request = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    };

    try {
      // Create completer for this request
      final completer = Completer<JsonRpcResponse>();
      _pendingRequests[id] = completer;

      // Send the request
      bindings.sendJsonRpcRequest(chainId, jsonEncode(request));

      // Start polling for response
      _pollForResponse();

      return await completer.future;
    } catch (e) {
      _pendingRequests.remove(id);
      rethrow;
    }
  }

  /// Poll for next JSON-RPC response
  void _pollForResponse() {
    final callbackId = _callbackId++;
    final completer = Completer<String>();
    _jsonRpcCallbackRegistry[callbackId] = completer;

    // Call Rust function to get next response
    bindings.nextJsonRpcResponse(
      chainHandle: chainId,
      callbackId: callbackId,
      callback: _nativeCallback,
    );

    // Process response when available
    completer.future
        .then((responseJson) {
          try {
            final response = jsonDecode(responseJson) as Map<String, dynamic>;

            // Check if this is a subscription notification
            final method = response['method'] as String?;
            if (method != null) {
              // This is a subscription notification
              _handleSubscriptionNotification(response);
            } else {
              // This is a regular response or subscription confirmation
              final id = response['id']?.toString();

              if (id != null) {
                // Check if this is a subscription confirmation
                if (_pendingSubscriptions.containsKey(id)) {
                  final controller = _pendingSubscriptions.remove(id);
                  final result = response['result'];

                  if (result != null) {
                    // Subscription successful - store the subscription ID
                    final subscriptionId = result.toString();
                    _subscriptions[subscriptionId] = controller!;
                  } else {
                    // Subscription failed
                    final error = response['error'];
                    controller?.addError(
                      JsonRpcException(
                        'Subscription failed',
                        error: error != null
                            ? JsonRpcError.fromJson(
                                error as Map<String, dynamic>,
                              )
                            : null,
                      ),
                    );
                    controller?.close();
                  }
                } else if (_pendingRequests.containsKey(id)) {
                  // Regular request response
                  final requestCompleter = _pendingRequests.remove(id);
                  requestCompleter?.complete(
                    JsonRpcResponse.fromJson(response),
                  );
                }
              }
            }

            // Continue polling if there are pending requests or active subscriptions
            if (_pendingRequests.isNotEmpty ||
                _pendingSubscriptions.isNotEmpty ||
                _subscriptions.isNotEmpty) {
              _pollForResponse();
            }
          } catch (e) {
            // JSON decode error - complete all pending with error
            for (final completer in _pendingRequests.values) {
              completer.completeError(
                JsonRpcException('Failed to decode JSON-RPC response: $e'),
              );
            }
            _pendingRequests.clear();
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          // Error getting response - complete all pending with error
          for (final completer in _pendingRequests.values) {
            completer.completeError(error, stackTrace);
          }
          _pendingRequests.clear();
        });
  }

  /// Handle subscription notification
  void _handleSubscriptionNotification(Map<String, dynamic> notification) {
    final params = notification['params'] as Map<String, dynamic>?;
    if (params == null) return;

    final subscriptionId = params['subscription']?.toString();
    if (subscriptionId == null) return;

    final controller = _subscriptions[subscriptionId];
    if (controller != null && !controller.isClosed) {
      // Create a response object from the notification
      final response = JsonRpcResponse(
        id: subscriptionId,
        result: params['result'],
      );
      controller.add(response);
    }
  }

  /// Subscribe to JSON-RPC notifications
  ///
  /// Returns a [Stream] of responses.
  Stream<JsonRpcResponse> subscribe(String method, List<dynamic> params) {
    final id = _generateRequestId();

    final request = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    };

    // Create stream controller for this subscription
    final controller = StreamController<JsonRpcResponse>.broadcast();
    _pendingSubscriptions[id] = controller;

    try {
      // Send the subscription request
      bindings.sendJsonRpcRequest(chainId, jsonEncode(request));

      // Start polling for responses
      _pollForResponse();

      return controller.stream;
    } catch (e) {
      _pendingSubscriptions.remove(id);
      controller.addError(e);
      controller.close();
      rethrow;
    }
  }

  /// Unsubscribe from a subscription
  Future<void> unsubscribe(String subscriptionId) async {
    final controller = _subscriptions.remove(subscriptionId);
    if (controller != null) {
      // Determine the unsubscribe method based on the original subscribe method
      // Most Substrate subscriptions use the pattern: method_unsubscribe
      // For example: chain_subscribeNewHeads -> chain_unsubscribeNewHeads

      // Send unsubscribe request
      try {
        await request('unsubscribe', [subscriptionId]);
      } catch (e) {
        // Ignore errors on unsubscribe
      }

      await controller.close();
    }
  }

  /// Generate a unique request ID
  String _generateRequestId() {
    return '${_requestId++}';
  }

  /// Dispose of resources
  void dispose() {
    _nativeCallable.close();
    _pendingRequests.clear();

    // Close all active subscriptions
    for (final controller in _subscriptions.values) {
      controller.close();
    }
    _subscriptions.clear();

    for (final controller in _pendingSubscriptions.values) {
      controller.close();
    }
    _pendingSubscriptions.clear();
  }
}

/// Predefined Substrate JSON-RPC methods
class SubstrateRpcMethods {
  /// Get the name of the blockchain
  static const systemChain = 'system_chain';

  /// Get the version of the node
  static const systemVersion = 'system_version';

  /// Get the name of the node
  static const systemName = 'system_name';

  /// Get properties of the blockchain
  static const systemProperties = 'system_properties';

  /// Get the node's health status
  static const systemHealth = 'system_health';

  /// Get the genesis hash
  static const chainGetBlockHash = 'chain_getBlockHash';

  /// Get the latest finalized block hash
  static const chainGetFinalizedHead = 'chain_getFinalizedHead';

  /// Get a block by hash
  static const chainGetBlock = 'chain_getBlock';

  /// Subscribe to new block headers
  static const chainSubscribeNewHeads = 'chain_subscribeNewHeads';

  /// Subscribe to finalized block headers
  static const chainSubscribeFinalizedHeads = 'chain_subscribeFinalizedHeads';

  /// Unsubscribe from block header updates
  static const chainUnsubscribeNewHeads = 'chain_unsubscribeNewHeads';

  /// Unsubscribe from finalized block header updates
  static const chainUnsubscribeFinalizedHeads =
      'chain_unsubscribeFinalizedHeads';

  /// Get runtime metadata
  static const stateGetMetadata = 'state_getMetadata';

  /// Get runtime version
  static const stateGetRuntimeVersion = 'state_getRuntimeVersion';

  /// Query storage at a block
  static const stateGetStorage = 'state_getStorage';

  /// Call a runtime method
  static const stateCall = 'state_call';

  /// Submit an extrinsic
  static const authorSubmitExtrinsic = 'author_submitExtrinsic';

  /// Subscribe to extrinsic statuses
  static const authorSubmitAndWatchExtrinsic = 'author_submitAndWatchExtrinsic';

  /// Unsubscribe from extrinsic status updates
  static const authorUnwatchExtrinsic = 'author_unwatchExtrinsic';
}
