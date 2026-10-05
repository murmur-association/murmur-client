// The app's own node: the options it's started with, reading the port it
// reports, and (with the pinned murmur-node release, see support/test_node.dart) running a
// real one and syncing a client from it.

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/services/local_node.dart';
import 'package:murmur_client/services/local_node_io.dart';
import 'package:murmur_client/services/node_client.dart';

import 'support/test_node.dart';

void main() {
  test('options: short-retention, local-only, and the wallet kept and paid only when given', () {
    final bare = localNodeArgs(dataDir: '/d', spec: 'whitepaper');
    expect(bare, containsAllInOrder(['--port', '127.0.0.1:0']));
    expect(bare, containsAll(['--prune-content', '--prune-retracted', '--daemon']));
    expect(bare, isNot(contains('--keep-author')));
    expect(bare, isNot(contains('--mine-to')));
    // Mining needs an address to pay.
    expect(localNodeArgs(dataDir: '/d', mine: true), isNot(contains('--mine-to')));

    final a = 'ab' * 32;
    final full = localNodeArgs(dataDir: '/d', address: a, mine: true, cpuPct: 250);
    expect(full, containsAllInOrder(['--keep-author', a]));
    expect(full, containsAllInOrder(['--mine-to', a, '--mine-cpu', '100']));
    expect(localNodeArgs(dataDir: '/d', address: a), isNot(contains('--mine-to')));
  });

  test('the listening port is read from the node\'s startup line', () {
    expect(listeningPort('[net] listening for peers on 127.0.0.1:49272'), 49272);
    expect(listeningPort('[net] listening for peers on 127.0.0.1:49272\r'), 49272);
    expect(listeningPort('[net] listening for websocket on 127.0.0.1:7880'), isNull);
    expect(listeningPort('[net] listening for peers on 0.0.0.0:7878'), isNull);
    expect(listeningPort('[rpc] control interface on 127.0.0.1:49273'), isNull);
  });

  test('runs a real node, syncs a client from it, and stops it', () async {
    final dir = await Directory.systemTemp.createTemp('murmur-local-node');
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        // Windows may still hold a file for a moment.
      }
    });
    final node = ProcessLocalNode(binary: nodeBinary, dataDir: dir.path);
    final wallet = await MurmurWallet.generate();
    await node.start(localNodeArgs(dataDir: dir.path, spec: 'demo', address: wallet.addressHex, mine: true, cpuPct: 50));
    addTearDown(node.stop);
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (node.state != LocalNodeState.running) {
      if (node.state == LocalNodeState.failed) fail('node failed: ${node.problem}');
      if (DateTime.now().isAfter(deadline)) fail('node did not start');
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    print('node listening on 127.0.0.1:${node.port}');

    final client = MurmurClient();
    addTearDown(client.dispose);
    await client.connect('127.0.0.1', node.port!);
    final synced = DateTime.now().add(const Duration(seconds: 60));
    while (!(client.state == LinkState.live && client.height >= 3)) {
      if (client.error != null) fail('client error: ${client.error}');
      if (DateTime.now().isAfter(synced)) fail('client did not sync');
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    expect(client.network?.id, 'murmur-demo-9');
    print('client synced to height ${client.height} from the app\'s own node');

    await node.stop();
    expect(node.state, LocalNodeState.stopped);
    expect(node.port, isNull);
  }, skip: nodeSkip,
      timeout: const Timeout(Duration(minutes: 2)));
}
