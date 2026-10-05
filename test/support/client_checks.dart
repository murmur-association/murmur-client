// Read-only checks of a client against a node, shared by node_test.dart (the
// node a test starts), live_node_test.dart (a public node, by hand) and
// live_release_test.dart (a public node, before a release): they send
// nothing.

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/services/chain_cache_io.dart';
import 'package:murmur_client/services/node_client.dart';

import 'test_node.dart';

/// Makes `client` connected and synced (how depends on the node).
typedef Connect = Future<MurmurClient> Function(MurmurClient client);

/// Connects to the public node `hostPort` and syncs: from the shipped
/// checkpoint on a network that has one.
Connect publicNode(String hostPort) => (client) async {
      addTearDown(client.dispose);
      final at = hostPort.lastIndexOf(':');
      await client.connect(hostPort.substring(0, at), int.parse(hostPort.substring(at + 1)));
      await until(client, () => client.state == LinkState.live && client.height > 0, timeout: const Duration(minutes: 3));
      return client;
    };

/// What a few requests prove, whatever the chain's length: the supply and
/// the burn pool against the tip's state root, the tip miner's account, and
/// the node's fees. Bounded, so a release can wait on it (the checks below
/// do work that grows with the chain). Returns the miner's address.
Future<String> checkProvenBasics(MurmurClient client) async {
  await until(client, () => client.provenIssued != null && client.provenPool != null);
  var issued = 0;
  for (var h = 1; h <= client.height; h++) {
    issued += client.network!.subsidyAt(h);
  }
  expect(client.provenIssued, issued);
  expect(client.circulating! + client.provenPool!, client.provenIssued);

  final miner = toHex(client.headerAt(client.height)!.miner);
  await until(client, () => client.account(miner) != null);
  expect(client.account(miner)!.balance, greaterThan(0));

  final fees = await client.feeInfo();
  expect(fees.suggested(264), greaterThanOrEqualTo(1));
  return miner;
}

/// [checkProvenBasics], then the tip miner's history found through filters,
/// without the chain. The filter scan covers the whole chain, so it takes
/// longer as the chain grows: for a chain a test built, or a run by hand.
Future<void> checkProvenState(Connect connect) async {
  final started = DateTime.now();
  final client = await connect(MurmurClient());
  final headersAfter = DateTime.now().difference(started);
  final miner = await checkProvenBasics(client);
  final provedAfter = DateTime.now().difference(started);

  client.watchAddress(miner);
  await until(client, () => !client.historyPending(miner), timeout: const Duration(minutes: 10));
  final historyAfter = DateTime.now().difference(started);
  print('${client.network!.id} at ${client.height}: headers ${headersAfter.inMilliseconds} ms, '
      'proofs ${provedAfter.inMilliseconds} ms, miner history ${historyAfter.inMilliseconds} ms '
      '(${client.fetchedBlocks} of ${client.height} blocks fetched)');
  expect(client.fetchedBlocks, lessThanOrEqualTo(client.height));
}

/// With a local copy, the client fetches and counts the whole chain and
/// agrees with the tip's state root; a second session starts from the copy.
/// Every block is downloaded, so it takes longer as the chain grows: for a
/// chain a test built, or a run by hand.
Future<void> checkLocalCopy(Connect connect) async {
  final dir = await Directory.systemTemp.createTemp('murmur-cache-test');
  addTearDown(() async {
    try {
      await dir.delete(recursive: true);
    } on FileSystemException {
      // Windows may still hold a file for a moment; it's a temp folder.
    }
  });

  final first = await connect(MurmurClient()..useCache(FileChainCache(dir)));
  // A state root that disagrees with the client's own count is an error,
  // which `until` fails on.
  await until(first, () => first.complete, timeout: const Duration(minutes: 30));
  final height = first.height;
  first.disconnect(); // disposed when the test ends
  await Future<void>.delayed(const Duration(milliseconds: 500)); // last cache writes

  final second = await connect(MurmurClient()..useCache(FileChainCache(dir)));
  await until(second, () => second.complete && second.height >= height, timeout: const Duration(minutes: 10));
  expect(second.fetchedBlocks, second.height);
  expect(second.headersFromNode, lessThan(height), reason: 'the stored headers were not fetched again');
}
