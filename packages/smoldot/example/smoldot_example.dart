import 'dart:io';

import 'package:smoldot/smoldot.dart';

/// Example demonstrating the smoldot package
///
/// This example showcases all implemented features including:
/// - Client initialization and multi-chain management
/// - JSON-RPC requests (including concurrent requests)
/// - Chain subscriptions
/// - Chain information queries
void main() async {
  await basicExample();
  await jsonRpcExample();
  await chainInfoExample();
  await subscriptionExample();
  await multiChainExample();
  await concurrentRequestsExample();
}

/// Basic example showing client initialization and chain creation
Future<void> basicExample() async {
  print('\n=== Basic Example: Client Initialization & Chain Creation ===\n');

  // Create and initialize the client
  final client = SmoldotClient(
    config: SmoldotConfig(maxLogLevel: 3, maxChains: 8),
  );

  try {
    print('Initializing client...');
    await client.initialize();
    print('✓ Client initialized');

    // Load real Westend chain spec
    final chainSpecFile = File('test/fixtures/westend.json');
    if (!chainSpecFile.existsSync()) {
      print('⚠ Westend chain spec not found at test/fixtures/westend.json');
      print(
        '  Download it with: curl -o test/fixtures/westend.json https://raw.githubusercontent.com/smol-dot/smoldot/main/demo-chain-specs/westend.json',
      );
      return;
    }

    print('Loading Westend chain spec...');
    final chainSpec = await chainSpecFile.readAsString();

    print('Adding Westend chain...');
    final chain = await client.addChain(AddChainConfig(chainSpec: chainSpec));
    print('✓ Chain added with ID: ${chain.chainId}');
    print('✓ Westend chain successfully initialized');

    print('\nChain object created successfully!');
    print('Chain ID: ${chain.chainId}');
    print('Is disposed: ${chain.isDisposed}');

    // Test basic JSON-RPC request
    print('\nMaking system_chain request...');
    final chainName = await chain.request('system_chain', []);
    print('✓ Chain name: ${chainName.result}');
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    print('\nDisposing client...');
    await client.dispose();
    print('✓ Client disposed');
  }
}

/// Example showing multi-chain support (relay + parachain)
Future<void> multiChainExample() async {
  print('\n=== Multi-Chain Example: Relay Chain + Parachain ===\n');

  final client = SmoldotClient();

  try {
    await client.initialize();
    print('✓ Client initialized');

    // Load Polkadot relay chain spec
    final polkadotSpecFile = File('test/fixtures/polkadot.json');
    if (!polkadotSpecFile.existsSync()) {
      print('⚠ Polkadot chain spec not found');
      print('  This example requires both Polkadot and Statemint chain specs');
      print(
        '  Download them from: https://github.com/smol-dot/smoldot/tree/main/demo-chain-specs',
      );
      return;
    }

    print('Adding Polkadot relay chain...');
    final polkadotSpec = await polkadotSpecFile.readAsString();
    final polkadot = await client.addChain(
      AddChainConfig(chainSpec: polkadotSpec),
    );
    print('✓ Polkadot relay chain added (ID: ${polkadot.chainId})');

    // Note: Parachain support requires the parachain chain spec
    // and proper relay chain reference
    print('\nTo add a parachain, use:');
    print('  AddChainConfig(');
    print('    chainSpec: parachainSpec,');
    print('    potentialRelayChains: [polkadot.chainId],');
    print('  )');

    print('\nActive chains in client: ${client.chains.length}');
    for (final chain in client.chains) {
      print('  - Chain ID: ${chain.chainId}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await client.dispose();
    print('✓ Client disposed');
  }
}

/// Example showing subscriptions to blockchain events
Future<void> subscriptionExample() async {
  print('\n=== Subscription Example ===\n');

  final client = SmoldotClient();

  try {
    await client.initialize();
    print('✓ Client initialized');

    final chainSpecFile = File('test/fixtures/westend.json');
    if (!chainSpecFile.existsSync()) {
      print('⚠ Westend chain spec not found');
      return;
    }

    final chainSpec = await chainSpecFile.readAsString();
    final chain = await client.addChain(AddChainConfig(chainSpec: chainSpec));
    print('✓ Chain added');

    print('\nSubscribing to new block headers...');
    print('(Will receive 3 blocks then unsubscribe)');

    final subscription = chain.subscribe('chain_subscribeNewHeads', []);

    int blockCount = 0;
    await for (final response in subscription) {
      final header = response.result as Map<String, dynamic>;
      final blockNumber = header['number'] as String;
      final blockHash = header['parentHash'] as String;

      print('✓ New block #$blockNumber');
      print('  Hash: ${blockHash.substring(0, 20)}...');

      blockCount++;
      if (blockCount >= 3) {
        print('\nReceived 3 blocks, stopping subscription...');
        break;
      }
    }

    print('✓ Subscription completed');
  } catch (e) {
    print('Error: $e');
  } finally {
    await client.dispose();
  }
}

/// Example showing JSON-RPC requests
Future<void> jsonRpcExample() async {
  print('\n=== JSON-RPC Example ===\n');

  final client = SmoldotClient();

  try {
    await client.initialize();
    print('✓ Client initialized');

    final chainSpecFile = File('test/fixtures/westend.json');
    if (!chainSpecFile.existsSync()) {
      print('⚠ Westend chain spec not found');
      return;
    }

    final chainSpec = await chainSpecFile.readAsString();
    final chain = await client.addChain(AddChainConfig(chainSpec: chainSpec));
    print('✓ Chain added');

    print('\nMaking JSON-RPC requests...');

    final chainName = await chain.request('system_chain', []);
    print('✓ Chain: ${chainName.result}');

    final version = await chain.request('system_version', []);
    print('✓ Version: ${version.result}');

    final properties = await chain.request('system_properties', []);
    print('✓ Properties: $properties');

    final health = await chain.request('system_health', []);
    print('✓ Health: $health');
  } catch (e) {
    print('Error: $e');
  } finally {
    await client.dispose();
  }
}

/// Example showing chain information queries
Future<void> chainInfoExample() async {
  print('\n=== Chain Information Example ===\n');

  final client = SmoldotClient();

  try {
    await client.initialize();
    print('✓ Client initialized');

    final chainSpecFile = File('test/fixtures/westend.json');
    if (!chainSpecFile.existsSync()) {
      print('⚠ Westend chain spec not found');
      return;
    }

    final chainSpec = await chainSpecFile.readAsString();
    final chain = await client.addChain(AddChainConfig(chainSpec: chainSpec));
    print('✓ Chain added');

    print('\nGetting chain information...');

    // Get comprehensive chain info
    final info = await chain.getInfo();
    print('✓ Chain Info:');
    print('  Name: ${info.name}');
    print('  Status: ${info.status}');
    print('  Peers: ${info.peerCount}');
    print('  Best Block: #${info.bestBlockNumber}');
    print('  Best Hash: ${info.bestBlockHash?.substring(0, 20)}...');

    // Get individual pieces of information
    final blockNumber = await chain.getBestBlockNumber();
    print('\n✓ Best block number: $blockNumber');

    final blockHash = await chain.getBestBlockHash();
    print('✓ Best block hash: ${blockHash?.substring(0, 20)}...');

    final peerCount = await chain.getPeerCount();
    print('✓ Peer count: $peerCount');

    final status = await chain.getStatus();
    print('✓ Chain status: $status');

    // Get info for all chains
    final allInfo = await client.getAllChainInfo();
    print('\n✓ Total chains: ${allInfo.length}');
    for (final chainInfo in allInfo) {
      print('  - ${chainInfo.name} (${chainInfo.status})');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await client.dispose();
  }
}

/// Example showing concurrent JSON-RPC requests
Future<void> concurrentRequestsExample() async {
  print('\n=== Concurrent Requests Example ===\n');

  final client = SmoldotClient();

  try {
    await client.initialize();
    print('✓ Client initialized');

    final chainSpecFile = File('test/fixtures/westend.json');
    if (!chainSpecFile.existsSync()) {
      print('⚠ Westend chain spec not found');
      return;
    }

    final chainSpec = await chainSpecFile.readAsString();
    final chain = await client.addChain(AddChainConfig(chainSpec: chainSpec));
    print('✓ Chain added');

    print('\nMaking 4 concurrent JSON-RPC requests...');

    final stopwatch = Stopwatch()..start();

    final futures = [
      chain.request('system_chain', []),
      chain.request('system_version', []),
      chain.request('system_name', []),
      chain.request('system_properties', []),
    ];

    final responses = await Future.wait(futures);
    stopwatch.stop();

    print('✓ All requests completed in ${stopwatch.elapsedMilliseconds}ms');
    print('\nResults:');
    print('  Chain: ${responses[0].result}');
    print('  Version: ${responses[1].result}');
    print('  Name: ${responses[2].result}');
    print('  Properties: ${responses[3].result}');
  } catch (e) {
    print('Error: $e');
  } finally {
    await client.dispose();
  }
}
