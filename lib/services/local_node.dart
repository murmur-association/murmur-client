// A Murmur node on this computer, run by the app (desktop builds only): the
// `murmur-node` binary shipped next to the app (tool/bundle_node.dart), in a
// data folder of its own. The app connects to it like to any node, over
// the peer-to-peer port; it never uses the node's control port (AGENTS.md
// rule 1). Changing a setting restarts the node with new options.
//
// The node the app runs is a legally light one (whitepaper Section 8.6):
// short-retention (--prune-content), so it keeps nobody's content past the
// one-hour check, except the user's own messages (--keep-author), and
// retracted messages are deleted (--prune-retracted). It listens only on
// this machine (--port 127.0.0.1:0): it connects out to the network, and
// peers aren't told an address nobody can reach. It holds no key: mining
// pays the wallet's address.

import 'package:flutter/foundation.dart';

import 'local_node_io.dart' if (dart.library.js_interop) 'local_node_web.dart' as impl;

enum LocalNodeState {
  /// No node binary next to the app, or not a desktop build.
  unavailable,
  stopped,
  starting,
  running,

  /// It stopped by itself; [LocalNode.problem] says why, if it said.
  failed,
}

/// The network the app's own node joins: `whitepaper` (the testnet), or
/// `demo` for local testing (`--dart-define=MURMUR_LOCAL_NODE_SPEC=demo`).
const localNodeSpec = String.fromEnvironment('MURMUR_LOCAL_NODE_SPEC', defaultValue: 'whitepaper');

/// Default share of one CPU core the node may mine with.
const defaultLocalNodeCpu = 25;

/// The options the app starts its node with.
List<String> localNodeArgs({
  required String dataDir,
  String spec = localNodeSpec,
  String? address,
  bool mine = false,
  int cpuPct = defaultLocalNodeCpu,
}) =>
    [
      '--daemon',
      '--spec', spec,
      '--data-dir', dataDir,
      // Only this machine, on free ports: no firewall prompt, no clash with
      // another node here. The chosen port is read from the node's output.
      '--port', '127.0.0.1:0',
      '--rpc-port', '0',
      '--prune-content',
      '--prune-retracted',
      if (address != null) ...['--keep-author', address],
      if (mine && address != null) ...['--mine-to', address, '--mine-cpu', '${cpuPct.clamp(1, 100)}'],
    ];

/// The peer-to-peer port a node reports at startup ("[net] listening for
/// peers on 127.0.0.1:<port>"), if `line` is that line.
int? listeningPort(String line) {
  final m = RegExp(r'^\[net\] listening for peers on 127\.0\.0\.1:(\d+)\s*$').firstMatch(line);
  return m == null ? null : int.tryParse(m.group(1)!);
}

abstract class LocalNode extends ChangeNotifier {
  /// The node for this platform: unavailable on the web and on phones.
  factory LocalNode() => impl.createLocalNode();

  LocalNode.base();

  LocalNodeState get state;

  /// Where it listens for peers on 127.0.0.1, once running.
  int? get port;

  /// The last error the node reported, if any.
  String? get problem;

  /// Its data folder (chain, the user's own messages, peers).
  String get dataDir;

  bool get available => state != LocalNodeState.unavailable;

  /// Starts it with `args` (stopping a running one first).
  Future<void> start(List<String> args);

  /// Stops it, if running.
  Future<void> stop();
}
