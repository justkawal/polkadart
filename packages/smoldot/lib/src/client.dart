import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'bindings.dart';
import 'types.dart';
import 'chain.dart';

/// Global callback registry for async FFI operations
/// Maps callback ID to completer
final Map<int, Completer<int>> _globalCallbackRegistry = {};

/// Main client for interacting with smoldot-light
///
/// The [SmoldotClient] provides a high-level, idiomatic Dart interface for
/// working with the smoldot-light library. It manages the lifecycle of the
/// native client, handles multiple chains, and provides async/await wrappers
/// for all operations.
///
/// Example usage:
/// ```dart
/// final client = SmoldotClient(
///   config: SmoldotConfig(
///     maxLogLevel: 3,
///     maxChains: 8,
///   ),
/// );
///
/// await client.initialize();
///
/// final chain = await client.addChain(
///   AddChainConfig(
///     chainSpec: polkadotChainSpec,
///   ),
/// );
///
/// final response = await chain.request('system_chain', []);
/// print('Chain name: ${response.result}');
///
/// await client.dispose();
/// ```
class SmoldotClient {
  /// Configuration for the client
  final SmoldotConfig config;

  /// FFI bindings to the native library
  late final SmoldotBindings _bindings;

  /// Native client handle (u64 from Rust)
  int? _clientHandle;

  /// Whether the client has been initialized
  bool _isInitialized = false;

  /// Map of chain ID to Chain instance
  final Map<int, Chain> _chains = {};

  /// Stream controller for log messages
  final StreamController<LogMessage> _logController =
      StreamController<LogMessage>.broadcast();

  /// Counter for generating unique callback IDs
  int _nextCallbackId = 1;

  /// Native callback for cross-thread communication
  late final NativeCallable<DartCallbackNative> _nativeCallable;

  /// Native callback function pointer
  late final Pointer<NativeFunction<DartCallbackNative>> _nativeCallback;

  /// Creates a new smoldot client with the given configuration
  SmoldotClient({SmoldotConfig? config})
    : config = config ?? const SmoldotConfig() {
    _bindings = SmoldotBindings();

    // Use NativeCallable.listener for callbacks from background threads
    _nativeCallable = NativeCallable<DartCallbackNative>.listener(
      _dartCallback,
    );
    _nativeCallback = _nativeCallable.nativeFunction;
  }

  /// Dart callback function that Rust will invoke
  static void _dartCallback(int callbackId, int result, Pointer<Utf8> error) {
    final completer = _globalCallbackRegistry.remove(callbackId);
    if (completer == null) {
      print('Warning: No completer found for callback ID $callbackId');
      return;
    }

    if (error != nullptr) {
      final errorMsg = error.toDartString();
      completer.completeError(
        SmoldotException('FFI operation failed: $errorMsg'),
      );
    } else {
      completer.complete(result);
    }
  }

  /// Whether the client is initialized
  bool get isInitialized => _isInitialized;

  /// Stream of log messages from smoldot
  Stream<LogMessage> get logs => _logController.stream;

  /// Get all active chains
  List<Chain> get chains => _chains.values.toList();

  /// Get a chain by its ID
  Chain? getChain(int chainId) => _chains[chainId];

  /// Get the number of active chains
  int get chainCount => _chains.length;

  /// Check if a chain exists
  bool hasChain(int chainId) => _chains.containsKey(chainId);

  /// Get information about all chains
  Future<List<ChainInfo>> getAllChainInfo() async {
    _ensureInitialized();

    final futures = _chains.values.map((chain) => chain.getInfo()).toList();
    return await Future.wait(futures);
  }

  /// Initialize the smoldot client
  ///
  /// This must be called before any other operations.
  /// Throws [SmoldotException] if initialization fails.
  Future<void> initialize() async {
    if (_isInitialized) {
      throw SmoldotException('Client is already initialized');
    }

    try {
      final configJson = jsonEncode(config.toJson());
      _clientHandle = _bindings.initClient(configJson);

      if (_clientHandle == null || _clientHandle == 0) {
        throw SmoldotException('Failed to initialize smoldot client');
      }

      _isInitialized = true;
    } catch (e, stackTrace) {
      throw SmoldotException(
        'Failed to initialize smoldot client',
        details: e.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  /// Add a new chain to the client
  ///
  /// Returns a [Chain] instance for interacting with the chain.
  /// Throws [SmoldotException] if the operation fails.
  Future<Chain> addChain(AddChainConfig config) async {
    _ensureInitialized();

    try {
      // Generate callback ID and create completer
      final callbackId = _nextCallbackId++;
      final completer = Completer<int>();
      _globalCallbackRegistry[callbackId] = completer;

      // Prepare chain spec JSON
      final chainSpecJson = config.chainSpec;

      // Call FFI with callback
      _bindings.addChain(
        clientHandle: _clientHandle!,
        chainSpecJson: chainSpecJson,
        callbackId: callbackId,
        callback: _nativeCallback,
        potentialRelayChains: config.potentialRelayChains,
        databaseContent: config.databaseContent,
      );

      // Wait for callback to complete
      final chainHandle = await completer.future;

      final chain = Chain(
        chainId: chainHandle,
        client: this,
        bindings: _bindings,
        clientHandle: _clientHandle!,
      );

      _chains[chainHandle] = chain;
      return chain;
    } catch (e, stackTrace) {
      throw SmoldotException(
        'Failed to add chain',
        details: e.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  /// Remove a chain from the client
  ///
  /// Throws [ChainException] if the operation fails.
  Future<void> removeChain(int chainId) async {
    _ensureInitialized();

    final chain = _chains[chainId];
    if (chain == null) {
      throw SmoldotException('Chain not found: $chainId');
    }

    try {
      _bindings.removeChain(chainId);
      await chain.dispose();
      _chains.remove(chainId);
    } catch (e, stackTrace) {
      throw SmoldotException(
        'Failed to remove chain',
        details: e.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  /// Dispose of the client and free all resources
  ///
  /// This must be called when done with the client to prevent memory leaks.
  Future<void> dispose() async {
    if (!_isInitialized) {
      return;
    }

    // Dispose all chains
    for (final chain in _chains.values) {
      await chain.dispose();
    }
    _chains.clear();

    // Destroy the client
    if (_clientHandle != null) {
      _bindings.destroyClient(_clientHandle!);
      _clientHandle = null;
    }

    _isInitialized = false;

    await _logController.close();

    // Close the native callable
    _nativeCallable.close();
  }

  /// Ensure the client is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw SmoldotException(
        'Client is not initialized. Call initialize() first.',
      );
    }
  }
}
