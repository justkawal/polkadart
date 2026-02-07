part of apis;

/// ChainSpec API for the new Substrate JSON-RPC specification.
///
/// Provides methods to query chain specification information such as
/// the genesis hash, chain name, and chain properties.
///
/// Reference: https://paritytech.github.io/json-rpc-interface-spec/api/chainSpec.html
class ChainSpecApi<P extends Provider> {
  final P _provider;

  const ChainSpecApi(this._provider);

  /// Returns the hash of the genesis block of the chain.
  ///
  /// Returns a hex-encoded block hash string.
  Future<String> genesisHash() async {
    final response = await _provider.send('chainSpec_v1_genesisHash', const []);

    if (response.error != null) {
      throw Exception(response.error.toString());
    }

    return response.result as String;
  }

  /// Returns the human-readable name of the chain.
  Future<String> chainName() async {
    final response = await _provider.send('chainSpec_v1_chainName', const []);

    if (response.error != null) {
      throw Exception(response.error.toString());
    }

    return response.result as String;
  }

  /// Returns the chain properties as a JSON object.
  ///
  /// Properties typically include:
  /// - `ss58Format`: The SS58 address format prefix
  /// - `tokenDecimals`: Number of decimals for the native token
  /// - `tokenSymbol`: Symbol of the native token
  Future<Map<String, dynamic>> properties() async {
    final response = await _provider.send('chainSpec_v1_properties', const []);

    if (response.error != null) {
      throw Exception(response.error.toString());
    }

    return Map<String, dynamic>.from(response.result as Map);
  }
}
