// Keeps the app's own node (local_node.dart) in line with the user's
// settings and wallet, and the client connected to it while it runs:
// - "run a node on this computer" on: start it; off: stop it, and go back
//   to the node the user chose (NodeSettings);
// - a different wallet, or mining settings: restart it with new options
//   (the app never uses the node's control port, AGENTS.md rule 1);
// - once it reports its port: connect the client to it.

import 'dart:async';

import 'local_node.dart';
import 'node_client.dart';
import 'storage.dart';

class LocalNodeLink {
  LocalNodeLink({required this.node, required this.prefs, required this.wallets, required this.client}) {
    prefs.addListener(_update);
    wallets.addListener(_update);
    node.addListener(_follow);
    _update();
  }

  final LocalNode node;
  final Preferences prefs;
  final WalletController wallets;
  final MurmurClient client;

  /// The options the node runs with; null while it shouldn't run.
  List<String>? _running;
  int? _connectedPort;
  Future<void> _last = Future.value();

  static bool _same(List<String>? a, List<String>? b) =>
      a == null || b == null ? a == b : a.length == b.length && a.join('\u0000') == b.join('\u0000');

  /// What the settings ask for; applied one change at a time.
  void _update() {
    if (!node.available) return;
    final address = wallets.wallet?.addressHex;
    final wanted = prefs.runLocalNode
        ? localNodeArgs(
            dataDir: node.dataDir,
            address: address,
            mine: prefs.localNodeMining,
            cpuPct: prefs.localNodeCpu,
          )
        : null;
    if (_same(wanted, _running)) return;
    _running = wanted;
    _last = _last.then((_) async {
      if (wanted != null) {
        await node.start(wanted);
      } else {
        await node.stop();
        if (_connectedPort != null) {
          _connectedPort = null;
          final (host, port) = await NodeSettings.load();
          await client.connect(host, port);
        }
      }
    });
  }

  /// Connects the client to the node once it's listening.
  void _follow() {
    final port = node.port;
    if (node.state == LocalNodeState.running && port != null && port != _connectedPort) {
      _connectedPort = port;
      unawaited(client.connect('127.0.0.1', port));
    }
  }

  /// Stops the node (the app is closing).
  Future<void> close() async {
    prefs.removeListener(_update);
    wallets.removeListener(_update);
    node.removeListener(_follow);
    await _last;
    await node.stop();
  }
}
