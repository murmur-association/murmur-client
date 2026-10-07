// Keeps the app's own node (local_node.dart) in line with the user's
// settings and wallet:
// - "run a node on this computer" on: start it; off: stop it;
// - a different wallet, or mining settings (on or off, the processor's
//   share, the graphics card): restart it with new options
//   (the app never uses the node's control port, AGENTS.md rule 1).
//
// The node only takes part in the network beside the app. The client never
// connects to it: it keeps reading from the node the user chose
// (NodeSettings), like every other build. The app's node keeps nobody's
// messages but the user's own, so a client reading from it had no text to
// show.

import 'dart:async';

import 'local_node.dart';
import 'storage.dart';

class LocalNodeLink {
  LocalNodeLink({required this.node, required this.prefs, required this.wallets}) {
    prefs.addListener(_update);
    wallets.addListener(_update);
    _update();
  }

  final LocalNode node;
  final Preferences prefs;
  final WalletController wallets;

  /// The options the node runs with; null while it shouldn't run.
  List<String>? _running;
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
            gpu: prefs.localNodeGpu && node.canMineOnGpu,
          )
        : null;
    if (_same(wanted, _running)) return;
    _running = wanted;
    _last = _last.then((_) => wanted != null ? node.start(wanted) : node.stop());
  }

  /// Stops the node (the app is closing).
  Future<void> close() async {
    prefs.removeListener(_update);
    wallets.removeListener(_update);
    await _last;
    await node.stop();
  }
}
