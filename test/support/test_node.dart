// The real node for tests: `murmur-node` (MURMUR_NODE_BIN) started on a demo
// chain the test generated (demo_chain.dart), through the same
// ProcessLocalNode the app runs its own node with. The node checks the
// chain with its own rules as it loads it, so what the client is tested
// against is a chain the reference implementation accepted.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/local_node.dart';
import 'package:murmur_client/services/local_node_io.dart';
import 'package:murmur_client/services/node_client.dart';

import 'demo_chain.dart';

final String? nodeBinary = Platform.environment['MURMUR_NODE_BIN'];

/// The skip reason for tests that need the node.
final Object nodeSkip = nodeBinary == null ? 'set MURMUR_NODE_BIN to a murmur-node binary (protocol 10) to run' : false;

class TestNode {
  TestNode._(this.dir, this.node);

  final Directory dir;
  final ProcessLocalNode node;

  /// What the node was started on: the best chain the test gave it.
  late List<Block> chain;

  int get port => node.port!;

  /// Starts the node on `chain` (and, mining to `mineTo`, on the blocks it
  /// adds), on a free port. The node is stopped and its folder deleted
  /// when the test ends.
  static Future<TestNode> start(List<Block> chain, {Uint8List? mineTo}) async {
    final dir = await Directory.systemTemp.createTemp('murmur-test-node');
    final n = TestNode._(dir, ProcessLocalNode(binary: nodeBinary, dataDir: dir.path));
    addTearDown(() async {
      await n.node.stop();
      await _deleteSoon(dir);
    });
    writeBlockLog(dir.path, chain);
    n.chain = chain;
    n._mineTo = mineTo;
    await n._run('127.0.0.1:0');
    return n;
  }

  Uint8List? _mineTo;

  Future<void> _run(String listen) async {
    await node.start([
      '--daemon',
      '--spec', 'demo',
      '--data-dir', dir.path,
      '--port', listen,
      '--rpc-port', '0',
      '--no-dns-seed',
      // At 1% of a core: the demo target starts easy, and a node mining
      // flat out races ahead of its clock (its timestamps follow the median
      // time past) until it waits out the future-timestamp limit, up to a
      // minute (Section 8.2). Slowly, it stays within seconds of the clock.
      if (_mineTo != null) ...['--mine-to', toHex(_mineTo!), '--mine-cpu', '1'],
    ]);
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (node.state != LocalNodeState.running) {
      if (node.state == LocalNodeState.failed) fail('the node stopped: ${node.problem}');
      if (DateTime.now().isAfter(deadline)) fail('the node did not start: ${node.problem}');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  /// Gives the node `fork`'s blocks after `forkAt` and restarts it on the
  /// same port: it replays them and moves to the heavier branch, as after a
  /// reorganization. Connected clients lose the link and reconnect.
  Future<void> reorganizeTo(List<Block> fork, int forkAt) async {
    final p = port;
    await node.stop();
    writeBlockLog(dir.path, fork.sublist(forkAt));
    chain = fork;
    await _run('127.0.0.1:$p');
  }

  /// A client connected to the node, synced to the chain it was started on:
  /// a node that refused any of the generated blocks fails here.
  Future<MurmurClient> connect(MurmurClient client) async {
    addTearDown(client.dispose);
    await client.connect('127.0.0.1', port);
    await until(client, () => client.state == LinkState.live && client.height >= chain.length);
    expect(client.hashAt(chain.length), chain.last.header.hash, reason: 'the node accepted the generated chain');
    return client;
  }
}

/// Waits for `done`, failing on a client error (unless `reconnecting`: a
/// lost link is then expected) or after `timeout`. A timeout names `what`
/// was awaited and adds `state()`, for finding out why.
Future<void> until(MurmurClient c, bool Function() done,
    {Duration timeout = const Duration(seconds: 60),
    bool reconnecting = false,
    String what = '',
    String Function()? state}) async {
  final deadline = DateTime.now().add(timeout);
  final from = c.height;
  while (!done()) {
    final e = c.error;
    if (e != null && !(reconnecting && c.retryAt != null)) fail('client error: $e (${e.cause} ${e.detail})');
    if (DateTime.now().isAfter(deadline)) {
      fail('timed out${what.isEmpty ? '' : ' waiting for $what'}: ${c.state.name}, height $from when waiting began, ${c.height} now '
          '(node at ${c.peerHeight}), error ${c.error}${state == null ? '' : '; ${state()}'}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

/// Deletes `dir`, retrying while Windows still holds the stopped node's
/// files.
Future<void> _deleteSoon(Directory dir) async {
  for (var i = 0; i < 20; i++) {
    try {
      await dir.delete(recursive: true);
      return;
    } on FileSystemException {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }
}
