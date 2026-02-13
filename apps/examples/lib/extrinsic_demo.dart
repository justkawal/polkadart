// ignore_for_file: non_constant_identifier_names
import 'dart:io';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:polkadart/apis/apis.dart';
import 'package:polkadart/polkadart.dart' show ExtrinsicBuilder, Provider, StateApi;
import 'package:polkadart_example/generated/polkadot/types/sp_runtime/multiaddress/multi_address.dart'
    as polkadot;
import 'package:polkadart_example/generated/paseo/types/sp_runtime/multiaddress/multi_address.dart'
    as paseo;
import 'package:polkadart_example/generated/assethub/types/sp_runtime/multiaddress/multi_address.dart'
    as assethub;
import 'package:polkadart_keyring/polkadart_keyring.dart';
import 'package:polkadart_scale_codec/polkadart_scale_codec.dart';
import 'package:ss58/ss58.dart';
import 'package:substrate_metadata/substrate_metadata.dart';

import 'generated/assethub/assethub.dart';
import 'generated/paseo/paseo.dart';
import 'generated/polkadot/polkadot.dart';

Future<void> main(List<String> arguments) async {
  final api = Polkadot(Provider.fromUri(Uri.parse('wss://rpc.polkadot.io')));
  final bob = await KeyPair.sr25519.fromUri('//Bob');
  final bobMultiAddress = polkadot.$MultiAddress().id(bob.publicKey.bytes);

  final encodedTx = api.tx.balances.transferAll(dest: bobMultiAddress, keepAlive: false).encode();
  print(encodeHex(encodedTx));

  // Create sr25519 wallet
  final sr25519Wallet = await KeyPair.sr25519.fromMnemonic(
    "resource mirror lecture smooth midnight muffin position cup pepper fruit vanish also//10",
  );
  print('Sr25519 Wallet: ${sr25519Wallet.address}');

  // Create ecdsa wallet
  final ecdsaWallet = await KeyPair.ecdsa.fromMnemonic(
    "mushroom grab answer fork ripple virus swamp food excess old client arena//10",
  );
  print('Ecdsa Wallet: ${ecdsaWallet.address}');

  {
    final paseoProvider = Provider.fromUri(Uri.parse('wss://paseo-rpc.n.dwellir.com'));
    final paseoApi = Paseo(paseoProvider);

    // Get info necessary to build an extrinsic
    final stateApi = StateApi(paseoProvider);
    final runtimeVersion = await stateApi.getRuntimeVersion();
    final specVersion = runtimeVersion.specVersion;
    final transactionVersion = runtimeVersion.transactionVersion;
    final block = await paseoProvider.send('chain_getBlock', []);
    final blockNumber = int.parse(block.result['block']['header']['number']);
    print('Block Number: $blockNumber');

    final blockHash = (await paseoProvider.send(
      'chain_getBlockHash',
      [],
    )).result.replaceAll('0x', '');
    final genesisHash = (await paseoProvider.send('chain_getBlockHash', [
      0,
    ])).result.replaceAll('0x', '');

    // Get Metadata and build ChainInfo
    final metadata = await stateApi.getMetadata();
    final chainInfo = ChainInfo.fromRuntimeMetadataPrefixed(metadata);

    //
    //
    // sending balance from sr25519 wallet to ecdsa wallet
    {
      //
      //
      // Ecdsa Wallet is becoming the receiver and the sr25519 wallet is the sender
      final dest = ecdsaWallet.address;
      final multiDest = paseo.$MultiAddress().id(Address.decode(dest).pubkey);
      print('Destination: $dest');

      // Encode call
      final runtimeCall = paseoApi.tx.balances.transferAll(dest: multiDest, keepAlive: false);
      final encodedCall = runtimeCall.encode();

      final nonce1 = await SystemApi(paseoProvider).accountNextIndex(sr25519Wallet.address);

      final builder = ExtrinsicBuilder(
        chainInfo: chainInfo,
        callData: encodedCall,
        specVersion: specVersion,
        transactionVersion: transactionVersion,
        genesisHash: Uint8List.fromList(hex.decode(genesisHash)),
        blockHash: Uint8List.fromList(hex.decode(blockHash)),
        blockNumber: blockNumber,
        eraPeriod: 64,
        nonce: nonce1,
        tip: BigInt.zero,
      );

      // Get fee
      final fee = await PaymentApi(paseoProvider).getFee(builder: builder, signerAddress: sr25519Wallet.address);
      print('Fee: $fee');

      // Build payload and sign with sr25519 wallet
      final srPayload = builder.getSigningPayload();
      print('Payload: ${hex.encode(srPayload)}');

      // Sign and submit
      final srHash = await builder.signBuildAndSubmit(
        provider: paseoProvider,
        signerAddress: sr25519Wallet.address,
        signingCallback: sr25519Wallet.sign,
      );
      print('Sr25519 extrinsic hash: ${hex.encode(srHash)}');
    }

    sleep(Duration(seconds: 10));

    //
    // Here we are sending back the received funds which we received from sr25519 wallet in previous step.
    //
    // sending back balance from ecdsa wallet to sr25519 wallet.
    {
      //
      //
      // sr25519 Wallet is becoming the receiver and the ecdsa wallet is the sender
      final dest = sr25519Wallet.address;
      final multiDest = paseo.$MultiAddress().id(Address.decode(dest).pubkey);
      print('Destination: $dest');

      // Encode call
      final runtimeCall = paseoApi.tx.balances.transferAll(dest: multiDest, keepAlive: false);
      final encodedCall = runtimeCall.encode();

      final nonce1 = await SystemApi(paseoProvider).accountNextIndex(ecdsaWallet.address);

      final builder = ExtrinsicBuilder(
        chainInfo: chainInfo,
        callData: encodedCall,
        specVersion: specVersion,
        transactionVersion: transactionVersion,
        genesisHash: Uint8List.fromList(hex.decode(genesisHash)),
        blockHash: Uint8List.fromList(hex.decode(blockHash)),
        blockNumber: blockNumber,
        eraPeriod: 64,
        nonce: nonce1,
        tip: BigInt.zero,
      );

      // Build payload and sign with ecdsa wallet
      final ecdsaPayload = builder.getSigningPayload();
      print('Payload: ${hex.encode(ecdsaPayload)}');

      // Sign and submit
      final ecdsaHash = await builder.signBuildAndSubmit(
        provider: paseoProvider,
        signerAddress: ecdsaWallet.address,
        signingCallback: ecdsaWallet.sign,
      );
      print('Ecdsa extrinsic hash: ${hex.encode(ecdsaHash)}');
    }
  }

  //
  //
  // Custom RPC call
  {
    final astarProvider = Provider.fromUri(Uri.parse('wss://rpc.astar.network'));
    final gasPrice = await astarProvider.send('eth_gasPrice', []);
    print('Gas Price: ${gasPrice.result}');
  }

  // Custom Signed Extension with TypeRegistry
  {
    final assetProvider = Provider.fromUri(Uri.parse('wss://westend-asset-hub-rpc.polkadot.io'));
    final assetApi = Assethub(assetProvider);
    final assetState = StateApi(assetProvider);

    final assetRuntimeVersion = await assetState.getRuntimeVersion();
    final assetSpecVersion = assetRuntimeVersion.specVersion;
    final assetTransactionVersion = assetRuntimeVersion.transactionVersion;
    final assetBlock = await assetProvider.send('chain_getBlock', []);
    final assetBlockNumber = int.parse(assetBlock.result['block']['header']['number']);
    final assetBlockHash = (await assetProvider.send(
      'chain_getBlockHash',
      [],
    )).result.replaceAll('0x', '');
    final assetGenesisHash = (await assetProvider.send('chain_getBlockHash', [
      0,
    ])).result.replaceAll('0x', '');

    final customDest = assethub.$MultiAddress().id(Address.decode(ecdsaWallet.address).pubkey);
    print('Custom Destination: $customDest');
    final customCall = assetApi.tx.balances.transferAll(dest: customDest, keepAlive: false);
    final customEncodedCall = customCall.encode();
    print('Custom Encoded Call: ${hex.encode(customEncodedCall)}');

    // Get Metadata and build ChainInfo
    final metadata = await assetState.getMetadata();
    final chainInfo = ChainInfo.fromRuntimeMetadataPrefixed(metadata);

    // Get SignedExtensions info
    final signedExtensions = chainInfo.registry.signedExtensions;
    print('Signed Extensions: ${signedExtensions.map((e) => e.identifier).toList()}');

    final nonce1 = await SystemApi(assetProvider).accountNextIndex(sr25519Wallet.address);
    print('sr25519 assethub address: ${sr25519Wallet.address}');
    print('Nonce: $nonce1');

    // Build extrinsic with custom signed extension
    final builder = ExtrinsicBuilder(
      chainInfo: chainInfo,
      callData: customEncodedCall,
      specVersion: assetSpecVersion,
      transactionVersion: assetTransactionVersion,
      genesisHash: Uint8List.fromList(hex.decode(assetGenesisHash)),
      blockHash: Uint8List.fromList(hex.decode(assetBlockHash)),
      blockNumber: assetBlockNumber,
      eraPeriod: 64,
      nonce: nonce1,
      tip: BigInt.zero,
    ).customExtension('ChargeAssetTxPayment', {"tip": BigInt.zero, "asset_id": Option.none()});

    final customExtensionPayload = builder.getSigningPayload();
    print('Encoded Payload: ${hex.encode(customExtensionPayload)}');

    // Sign and submit
    final hash = await builder.signBuildAndSubmit(
      provider: assetProvider,
      signerAddress: sr25519Wallet.address,
      signingCallback: sr25519Wallet.sign,
    );
    print('Custom Signed Extension Extrinsic Hash: ${hex.encode(hash)}');
  }
}
