// The real node for tests: the pinned murmur-node release
// (tool/node_release.dart), which `dart run tool/bundle_node.dart
// --for-tests` downloads into build/node and checks against its SHA256SUMS
// (MURMUR_NODE_BIN points elsewhere). Chains come from the node itself,
// `murmur-node demo-chain`: built and checked with the node's own rules, so
// nothing about them is restated here. The node then runs through the same
// ProcessLocalNode the app runs its own node with.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/services/local_node.dart';
import 'package:murmur_client/services/local_node_io.dart';
import 'package:murmur_client/services/node_client.dart';

import '../../tool/node_release.dart';

final _exe = Platform.isWindows ? 'murmur-node.exe' : 'murmur-node';
final _downloaded = File('$testNodeDir${Platform.pathSeparator}$_exe').absolute;
final _downloadedVersion = File('$testNodeDir${Platform.pathSeparator}murmur-node.version');

/// The node program: MURMUR_NODE_BIN, or the pinned release in build/node.
final String? nodeBinary =
    Platform.environment['MURMUR_NODE_BIN'] ?? (_downloaded.existsSync() ? _downloaded.path : null);

/// The skip reason for tests that need the node, or false. With
/// MURMUR_REQUIRE_NODE set (CI), a missing or stale node fails instead.
final Object nodeSkip = () {
  const fetch = 'run `dart run tool/bundle_node.dart --for-tests`';
  String? problem;
  if (nodeBinary == null) {
    problem = 'no murmur-node: $fetch (or set MURMUR_NODE_BIN)';
  } else if (Platform.environment['MURMUR_NODE_BIN'] == null) {
    final have = _downloadedVersion.existsSync() ? _downloadedVersion.readAsStringSync().trim() : 'an unknown release';
    if (have != nodeRelease) problem = 'build/node holds $have, the client pins $nodeRelease: $fetch';
  }
  if (problem != null && Platform.environment['MURMUR_REQUIRE_NODE'] != null) throw StateError(problem);
  return problem ?? false;
}();

/// A demo chain in a folder of its own, and the node that serves it.
class TestNode {
  TestNode._(this.dir) : node = ProcessLocalNode(binary: nodeBinary, dataDir: dir.path);

  final Directory dir;
  final ProcessLocalNode node;

  /// The best chain's block hashes (hex), by height: `hashes[h - 1]`.
  List<String> hashes = [];

  int get height => hashes.length;
  String hashAt(int h) => hashes[h - 1];

  int? _port;
  int get port => node.port!;

  /// A new demo chain of `blocks` blocks mined to `mineTo` (the node isn't
  /// started yet). Stopped, and its folder deleted, when the test ends.
  static Future<TestNode> build(int blocks, {required Uint8List mineTo, DateTime? endTime}) async {
    final n = TestNode._(await Directory.systemTemp.createTemp('murmur-test-node'));
    addTearDown(() async {
      await n.node.stop();
      await _deleteSoon(n.dir);
    });
    await n.grow(blocks, mineTo: mineTo, endTime: endTime);
    return n;
  }

  /// Builds on the chain with `murmur-node demo-chain` (the node must be
  /// stopped): up to height `blocks`, on the tip, or with `forkAt` a
  /// heavier branch from that block, which the node then follows. The new
  /// tip is at `endTime` (default now). New blocks are 2 s apart and never
  /// in the future, so a branch of n blocks needs n × 2 s after its fork
  /// point; without it demo-chain refuses, and says how much earlier the
  /// chain must end.
  Future<void> grow(int blocks, {required Uint8List mineTo, int? forkAt, DateTime? endTime}) async {
    final r = await Process.run(nodeBinary!, [
      'demo-chain',
      '--data-dir', dir.path,
      '--blocks', '$blocks',
      '--mine-to', toHex(mineTo),
      if (forkAt != null) ...['--fork-at', '$forkAt'],
      if (endTime != null) ...['--end-time', '${endTime.millisecondsSinceEpoch ~/ 1000}'],
    ]);
    if (r.exitCode != 0) fail('demo-chain failed: ${r.stderr}');
    final lines = const LineSplitter().convert('${r.stdout}').where((l) => l.trim().isNotEmpty).toList();
    final first = int.parse(lines.first.split(' ').first);
    hashes = [...hashes.take(first - 1), for (final l in lines) l.trim().split(RegExp(r'\s+'))[1]];
    expect(height, blocks);
  }

  /// Starts the node on the chain (on the port it had, if it ran before),
  /// mining on top to `mineTo` if given. With `webSocketPort` it also takes
  /// WebSocket connections there (`--ws-port`), as browsers need.
  Future<void> start({Uint8List? mineTo, int? webSocketPort}) async {
    await node.start([
      '--daemon',
      '--spec', 'demo',
      '--data-dir', dir.path,
      '--port', '127.0.0.1:${_port ?? 0}',
      '--rpc-port', '0',
      '--no-dns-seed',
      if (webSocketPort != null) ...['--ws-port', '127.0.0.1:$webSocketPort'],
      // At 1% of a core: the demo target starts easy, and a node mining
      // flat out races ahead of its clock (its timestamps follow the median
      // time past) until it waits out the future-timestamp limit, up to a
      // minute (Section 8.2). Slowly, it stays within seconds of the clock.
      if (mineTo != null) ...['--mine-to', toHex(mineTo), '--mine-cpu', '1'],
    ]);
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (node.state != LocalNodeState.running) {
      if (node.state == LocalNodeState.failed) fail('the node stopped: ${node.problem}');
      if (DateTime.now().isAfter(deadline)) fail('the node did not start: ${node.problem}');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    _port = node.port;
  }

  /// Stops the node; connected clients lose the link and reconnect once it
  /// starts again.
  Future<void> stop() => node.stop();

  /// `client` connected to the node and synced to the chain the node was
  /// started on. Disposed when the test ends.
  Future<MurmurClient> connect(MurmurClient client) async {
    addTearDown(client.dispose);
    await client.connect('127.0.0.1', port);
    await until(client, () => client.state == LinkState.live && client.height >= height);
    expect(toHex(client.hashAt(height)), hashAt(height));
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
  // What a client meets while its node restarts, until it's back.
  bool passing(LinkError e) => switch (e.kind) {
        LinkErrorKind.unreachable || LinkErrorKind.connection || LinkErrorKind.closed || LinkErrorKind.timeout => true,
        LinkErrorKind.syncFailed => e.cause != null && passing(e.cause!),
        _ => false,
      };
  while (!done()) {
    final e = c.error;
    if (e != null && !(reconnecting && passing(e))) fail('client error: $e (${e.cause} ${e.detail})');
    if (DateTime.now().isAfter(deadline)) {
      fail('timed out${what.isEmpty ? '' : ' waiting for $what'}: ${c.state.name}, height $from when waiting began, '
          '${c.height} now (node at ${c.peerHeight}), error ${c.error}${state == null ? '' : '; ${state()}'}');
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
