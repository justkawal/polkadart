part of apis;

/// Substrate payment API for querying transaction fees
class PaymentApi<P extends Provider> {
  final P _provider;
  const PaymentApi(this._provider);

  /// Query the fee information for an extrinsic
  ///
  /// This method creates a signed extrinsic with a dummy signature and queries
  /// the chain for fee information. The dummy signature allows fee estimation
  /// without requiring actual signing.
  ///
  /// Parameters:
  /// - [builder]: The ExtrinsicBuilder with all chain data configured
  /// - [signerAddress]: SS58-encoded address of the signer
  /// - [signatureType]: Type of signature to use for dummy signature (default: sr25519)
  ///
  /// Returns:
  /// A [BigInt] representing the partial fee (in smallest units, e.g., planck for DOT)
  ///
  /// Throws:
  /// - [Exception] if the RPC call fails
  /// - [Exception] if the response format is invalid
  ///
  /// Example:
  /// ```dart
  /// final builder = ExtrinsicBuilder.fromChainData(
  ///   chainInfo: chainInfo,
  ///   callData: callData,
  ///   chainData: chainData,
  /// );
  ///
  /// final fee = await PaymentApi(provider).getFee(
  ///   builder: builder,
  ///   signerAddress: alice.address,
  /// );
  /// print('Transaction fee: $fee');
  /// ```
  Future<BigInt> getFee({
    required final ExtrinsicBuilder builder,
    required final String signerAddress,
    final SignatureType signatureType = SignatureType.sr25519,
  }) async {
    final dummySignature = _createDummySignature(signatureType);

    final encodedExtrinsic = await builder.signAndBuild(
      provider: _provider,
      signerAddress: signerAddress,
      signingCallback: (_) => dummySignature,
    );

    final hexEncodedExtrinsic = '0x${hex.encode(encodedExtrinsic.bytes)}';

    final response = await _provider.send('payment_queryInfo', [hexEncodedExtrinsic, null]);

    if (response.error != null) {
      throw Exception('RPC Error: ${response.error}');
    }

    final result = response.result;
    if (result is Map<String, dynamic>) {
      final partialFeeString = result['partialFee'] as String?;
      if (partialFeeString == null) {
        throw Exception('Invalid response: missing partialFee field');
      }
      return BigInt.parse(partialFeeString);
    } else if (result is String) {
      return BigInt.parse(result);
    } else {
      throw Exception('Invalid response format: expected Map or String, got ${result.runtimeType}');
    }
  }

  /// Query the fee information for a call using CallBuilder
  ///
  /// This is a convenience method that builds an ExtrinsicBuilder from a CallBuilder
  /// and then queries the fee. It automatically fetches chain data.
  ///
  /// Parameters:
  /// - [callBuilder]: The CallBuilder representing the call to estimate fees for
  /// - [chainInfo]: Chain metadata and configuration
  /// - [signerAddress]: SS58-encoded address of the signer
  /// - [eraPeriod]: Era period in blocks (default: 64, 0 for immortal)
  /// - [tip]: Optional tip for transaction prioritization
  /// - [signatureType]: Type of signature to use for dummy signature (default: sr25519)
  ///
  /// Returns:
  /// A [BigInt] representing the partial fee
  ///
  /// Example:
  /// ```dart
  /// final transferCall = Balances.transfer.toAccountId(
  ///   destination: destinationAddress,
  ///   amount: BigInt.from(1000000),
  /// );
  ///
  /// final fee = await PaymentApi(provider).getFeeForCall(
  ///   callBuilder: transferCall,
  ///   chainInfo: chainInfo,
  ///   signerAddress: alice.address,
  /// );
  /// ```
  Future<BigInt> getFeeForCall({
    required final CallBuilder callBuilder,
    required final ChainInfo chainInfo,
    required final String signerAddress,
    final int eraPeriod = 64,
    final BigInt? tip,
    final SignatureType signatureType = SignatureType.sr25519,
  }) async {
    final callData = callBuilder.encode(chainInfo);
    final fetcher = ChainDataFetcher(_provider);
    final chainData = await fetcher.fetchStandardData(accountAddress: signerAddress);

    final builder = ExtrinsicBuilder.fromChainData(
      chainInfo: chainInfo,
      callData: callData,
      chainData: chainData,
      eraPeriod: eraPeriod,
      tip: tip,
    );

    return getFee(
      builder: builder,
      signerAddress: signerAddress,
      signatureType: signatureType,
    );
  }

  Uint8List _createDummySignature(final SignatureType type) {
    switch (type) {
      case SignatureType.sr25519:
      case SignatureType.ed25519:
      case SignatureType.unknown:
        return Uint8List(64);
      case SignatureType.ecdsa:
        return Uint8List(65);
    }
  }
}

