import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'platform.dart';

// Native type definitions matching C header
typedef ClientHandle = Uint64;
typedef ChainHandle = Uint64;

// Dart callback type
typedef DartCallbackNative =
    Void Function(Int64 callbackId, Int64 result, Pointer<Utf8> error);
typedef DartCallbackDart =
    void Function(int callbackId, int result, Pointer<Utf8> error);

// Native function signatures
typedef SmoldotClientInitNative =
    ClientHandle Function(
      Pointer<Utf8> configJson,
      Pointer<Pointer<Utf8>> errorOut,
    );
typedef SmoldotClientInitDart =
    int Function(Pointer<Utf8> configJson, Pointer<Pointer<Utf8>> errorOut);

typedef SmoldotAddChainNative =
    Int32 Function(
      ClientHandle clientHandle,
      Pointer<Utf8> chainSpecJson,
      Pointer<ChainHandle> potentialRelayChains,
      Int32 relayCount,
      Pointer<Utf8> databaseContent,
      Int64 callbackId,
      Pointer<NativeFunction<DartCallbackNative>> callback,
      Pointer<Pointer<Utf8>> errorOut,
    );
typedef SmoldotAddChainDart =
    int Function(
      int clientHandle,
      Pointer<Utf8> chainSpecJson,
      Pointer<Uint64> potentialRelayChains,
      int relayCount,
      Pointer<Utf8> databaseContent,
      int callbackId,
      Pointer<NativeFunction<DartCallbackNative>> callback,
      Pointer<Pointer<Utf8>> errorOut,
    );

typedef SmoldotSendJsonRpcNative =
    Int32 Function(
      ChainHandle chainHandle,
      Pointer<Utf8> requestJson,
      Pointer<Pointer<Utf8>> errorOut,
    );
typedef SmoldotSendJsonRpcDart =
    int Function(
      int chainHandle,
      Pointer<Utf8> requestJson,
      Pointer<Pointer<Utf8>> errorOut,
    );

typedef SmoldotNextJsonRpcResponseNative =
    Int32 Function(
      ChainHandle chainHandle,
      Int64 callbackId,
      Pointer<NativeFunction<DartCallbackNative>> callback,
      Pointer<Pointer<Utf8>> errorOut,
    );
typedef SmoldotNextJsonRpcResponseDart =
    int Function(
      int chainHandle,
      int callbackId,
      Pointer<NativeFunction<DartCallbackNative>> callback,
      Pointer<Pointer<Utf8>> errorOut,
    );

typedef SmoldotRemoveChainNative =
    Int32 Function(ChainHandle chainHandle, Pointer<Pointer<Utf8>> errorOut);
typedef SmoldotRemoveChainDart =
    int Function(int chainHandle, Pointer<Pointer<Utf8>> errorOut);

typedef SmoldotClientDestroyNative =
    Int32 Function(ClientHandle clientHandle, Pointer<Pointer<Utf8>> errorOut);
typedef SmoldotClientDestroyDart =
    int Function(int clientHandle, Pointer<Pointer<Utf8>> errorOut);

typedef SmoldotFreeStringNative = Void Function(Pointer<Utf8> ptr);
typedef SmoldotFreeStringDart = void Function(Pointer<Utf8> ptr);

typedef SmoldotVersionNative = Pointer<Utf8> Function();
typedef SmoldotVersionDart = Pointer<Utf8> Function();

/// FFI bindings for smoldot-light native library
class SmoldotBindings {
  late final DynamicLibrary _library;
  late final Allocator _allocator;

  // Function pointers
  late final SmoldotClientInitDart _clientInit;
  late final SmoldotAddChainDart _addChain;
  late final SmoldotSendJsonRpcDart _sendJsonRpc;
  late final SmoldotNextJsonRpcResponseDart _nextJsonRpcResponse;
  late final SmoldotRemoveChainDart _removeChain;
  late final SmoldotClientDestroyDart _clientDestroy;
  late final SmoldotFreeStringDart _freeString;
  late final SmoldotVersionDart _version;

  /// Initialize the bindings by loading the native library
  SmoldotBindings() {
    _library = SmoldotPlatform.loadLibrary();
    _allocator = malloc;
    _initializeBindings();
  }

  /// Initialize function pointers from the library
  void _initializeBindings() {
    _clientInit = _library
        .lookupFunction<SmoldotClientInitNative, SmoldotClientInitDart>(
          'smoldot_client_init',
        );
    _addChain = _library
        .lookupFunction<SmoldotAddChainNative, SmoldotAddChainDart>(
          'smoldot_add_chain',
        );
    _sendJsonRpc = _library
        .lookupFunction<SmoldotSendJsonRpcNative, SmoldotSendJsonRpcDart>(
          'smoldot_send_json_rpc',
        );
    _nextJsonRpcResponse = _library
        .lookupFunction<
          SmoldotNextJsonRpcResponseNative,
          SmoldotNextJsonRpcResponseDart
        >('smoldot_next_json_rpc_response');
    _removeChain = _library
        .lookupFunction<SmoldotRemoveChainNative, SmoldotRemoveChainDart>(
          'smoldot_remove_chain',
        );
    _clientDestroy = _library
        .lookupFunction<SmoldotClientDestroyNative, SmoldotClientDestroyDart>(
          'smoldot_client_destroy',
        );
    _freeString = _library
        .lookupFunction<SmoldotFreeStringNative, SmoldotFreeStringDart>(
          'smoldot_free_string',
        );
    _version = _library
        .lookupFunction<SmoldotVersionNative, SmoldotVersionDart>(
          'smoldot_version',
        );
  }

  // ===== Core Client Functions =====

  /// Initialize the smoldot client
  ///
  /// Takes a JSON configuration string and returns a client handle.
  /// Returns 0 if initialization fails.
  int initClient(String configJson) {
    final configPtr = configJson.toNativeUtf8(allocator: _allocator);
    final errorOutPtr = _allocator<Pointer<Utf8>>();
    errorOutPtr.value = nullptr;

    try {
      final handle = _clientInit(configPtr, errorOutPtr);

      if (errorOutPtr.value != nullptr) {
        final error = errorOutPtr.value.toDartString();
        _freeString(errorOutPtr.value);
        throw Exception('Failed to initialize client: $error');
      }

      if (handle == 0) {
        throw Exception('Failed to initialize client: returned null handle');
      }

      return handle;
    } finally {
      _allocator.free(configPtr);
      _allocator.free(errorOutPtr);
    }
  }

  /// Destroy the smoldot client and free resources
  void destroyClient(int clientHandle) {
    final errorOutPtr = _allocator<Pointer<Utf8>>();
    errorOutPtr.value = nullptr;

    try {
      final result = _clientDestroy(clientHandle, errorOutPtr);

      if (errorOutPtr.value != nullptr) {
        final error = errorOutPtr.value.toDartString();
        _freeString(errorOutPtr.value);
        throw Exception('Failed to destroy client: $error');
      }

      if (result != 0) {
        throw Exception('Failed to destroy client: error code $result');
      }
    } finally {
      _allocator.free(errorOutPtr);
    }
  }

  /// Add a chain to the client (async operation via callback)
  ///
  /// Returns immediately, actual result comes via callback.
  void addChain({
    required int clientHandle,
    required String chainSpecJson,
    required int callbackId,
    required Pointer<NativeFunction<DartCallbackNative>> callback,
    List<int>? potentialRelayChains,
    String? databaseContent,
  }) {
    final chainSpecPtr = chainSpecJson.toNativeUtf8(allocator: _allocator);
    final errorOutPtr = _allocator<Pointer<Utf8>>();
    errorOutPtr.value = nullptr;

    Pointer<Uint64>? relayChainPtr;
    Pointer<Utf8>? dbContentPtr;

    try {
      // Handle relay chains
      if (potentialRelayChains != null && potentialRelayChains.isNotEmpty) {
        relayChainPtr = _allocator<Uint64>(potentialRelayChains.length);
        for (var i = 0; i < potentialRelayChains.length; i++) {
          relayChainPtr[i] = potentialRelayChains[i];
        }
      }

      // Handle database content
      if (databaseContent != null) {
        dbContentPtr = databaseContent.toNativeUtf8(allocator: _allocator);
      }

      final result = _addChain(
        clientHandle,
        chainSpecPtr,
        relayChainPtr ?? nullptr,
        potentialRelayChains?.length ?? 0,
        dbContentPtr ?? nullptr,
        callbackId,
        callback,
        errorOutPtr,
      );

      if (errorOutPtr.value != nullptr) {
        final error = errorOutPtr.value.toDartString();
        _freeString(errorOutPtr.value);
        throw Exception('Failed to add chain: $error');
      }

      if (result != 0) {
        throw Exception('Failed to add chain: error code $result');
      }
    } finally {
      _allocator.free(chainSpecPtr);
      _allocator.free(errorOutPtr);
      if (relayChainPtr != null) _allocator.free(relayChainPtr);
      if (dbContentPtr != null) _allocator.free(dbContentPtr);
    }
  }

  /// Remove a chain from the client
  void removeChain(int chainHandle) {
    final errorOutPtr = _allocator<Pointer<Utf8>>();
    errorOutPtr.value = nullptr;

    try {
      final result = _removeChain(chainHandle, errorOutPtr);

      if (errorOutPtr.value != nullptr) {
        final error = errorOutPtr.value.toDartString();
        _freeString(errorOutPtr.value);
        throw Exception('Failed to remove chain: $error');
      }

      if (result != 0) {
        throw Exception('Failed to remove chain: error code $result');
      }
    } finally {
      _allocator.free(errorOutPtr);
    }
  }

  // ===== JSON-RPC Functions =====

  /// Send a JSON-RPC request to a chain
  void sendJsonRpcRequest(int chainHandle, String requestJson) {
    final requestPtr = requestJson.toNativeUtf8(allocator: _allocator);
    final errorOutPtr = _allocator<Pointer<Utf8>>();
    errorOutPtr.value = nullptr;

    try {
      final result = _sendJsonRpc(chainHandle, requestPtr, errorOutPtr);

      if (errorOutPtr.value != nullptr) {
        final error = errorOutPtr.value.toDartString();
        _freeString(errorOutPtr.value);
        throw Exception('Failed to send JSON-RPC request: $error');
      }

      if (result != 0) {
        throw Exception('Failed to send JSON-RPC request: error code $result');
      }
    } finally {
      _allocator.free(requestPtr);
      _allocator.free(errorOutPtr);
    }
  }

  /// Get the next JSON-RPC response (async operation via callback)
  void nextJsonRpcResponse({
    required int chainHandle,
    required int callbackId,
    required Pointer<NativeFunction<DartCallbackNative>> callback,
  }) {
    final errorOutPtr = _allocator<Pointer<Utf8>>();
    errorOutPtr.value = nullptr;

    try {
      final result = _nextJsonRpcResponse(
        chainHandle,
        callbackId,
        callback,
        errorOutPtr,
      );

      if (errorOutPtr.value != nullptr) {
        final error = errorOutPtr.value.toDartString();
        _freeString(errorOutPtr.value);
        throw Exception('Failed to get next JSON-RPC response: $error');
      }

      if (result != 0) {
        throw Exception(
          'Failed to get next JSON-RPC response: error code $result',
        );
      }
    } finally {
      _allocator.free(errorOutPtr);
    }
  }

  /// Free a string allocated by Rust
  void freeString(Pointer<Utf8> ptr) {
    if (ptr != nullptr) {
      _freeString(ptr);
    }
  }

  /// Get the version of the smoldot FFI library
  String getVersion() {
    final versionPtr = _version();
    try {
      return versionPtr.toDartString();
    } finally {
      _freeString(versionPtr);
    }
  }
}
