// A Murmur node on this computer, run by the app (desktop builds only): the
// `murmur-node` binary shipped next to the app (tool/bundle_node.dart), in a
// data folder of its own. It takes part in the network beside the app: the
// client keeps reading from the node the user chose and never connects to
// this one, which keeps nobody else's messages. The app never uses its
// control port (AGENTS.md rule 1). Changing a setting restarts the node
// with new options.
//
// The node the app runs is a legally light one (whitepaper Section 8.6):
// short-retention (--prune-content), so it keeps nobody's content past the
// one-hour check, except the user's own messages (--keep-author), and
// retracted messages are deleted (--prune-retracted). It is a pruned node
// (--prune-blocks): it checks every block, keeps the latest day of them and
// no index, so it stays the same size however old the chain. A new one starts
// from the app's checkpoint (--checkpoint) and checks the blocks before it in
// the background. It listens only on
// this machine (--port 127.0.0.1:0): it connects out to the network, and
// peers aren't told an address nobody can reach. It holds no key: mining
// pays the wallet's address.
//
// Mining can use the graphics card (--gpu): the node then runs murmur-miner,
// shipped beside it, and mines on the processor whenever the card can't be
// used. What the app shows of it comes from the node's own output (the
// "[gpu]" lines), never from its control port.

import 'package:flutter/foundation.dart';

import '../protocol/network.dart';
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

/// The network [localNodeSpec] names, for its checkpoint.
NetworkInfo get localNodeNetwork => localNodeSpec == 'demo' ? NetworkInfo.demo : NetworkInfo.whitepaper;

/// Default share of one CPU core the node may mine with.
const defaultLocalNodeCpu = 25;

/// The options the app starts its node with.
List<String> localNodeArgs({
  required String dataDir,
  String spec = localNodeSpec,
  String? address,
  bool mine = false,
  int cpuPct = defaultLocalNodeCpu,
  bool gpu = false,
  Checkpoint? checkpoint,
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
      // Every block is checked, then only the latest day of them is kept,
      // so disk and memory stay flat however old the chain. It implies no
      // index, which serves clients, and none reads from this node.
      '--prune-blocks',
      // A new node starts at the tip from the checkpoint this app's release
      // carries (the trust is the app's own, Section 7.7), then checks every
      // block from genesis in the background (Section 7.10). A node that
      // already has a chain ignores it.
      if (checkpoint != null && checkpoint.wellFormed) ...['--checkpoint', '${checkpoint.height}:${checkpoint.hash}'],
      if (address != null) ...['--keep-author', address],
      if (mine && address != null) ...[
        '--mine-to', address,
        '--mine-cpu', '${cpuPct.clamp(1, 100)}',
        // Only with mining (the node refuses --gpu without --mine-to), and
        // only for a node that has the option: the caller checks
        // [LocalNode.canMineOnGpu].
        if (gpu) '--gpu',
      ],
    ];

/// Where the node's GPU miner stands, as the node last said.
enum GpuMiningState {
  /// The miner is opening the card, or starting again; the processor mines
  /// meanwhile.
  starting,

  /// The card mines; the processor's miner rests.
  mining,

  /// The card can't be used: the node mines on the processor, and tries
  /// the card again every few minutes.
  unavailable,
}

class GpuMining {
  const GpuMining(this.state, {this.device, this.reason});

  final GpuMiningState state;

  /// The driver's name for the card, once it mines.
  final String? device;

  /// Why the card isn't mining, in the node's own English words: a detail
  /// to show as it is, never to match on.
  final String? reason;

  @override
  bool operator ==(Object other) =>
      other is GpuMining && other.state == state && other.device == device && other.reason == reason;

  @override
  int get hashCode => Object.hash(state, device, reason);

  @override
  String toString() => 'GpuMining(${state.name}, $device, $reason)';
}

/// What a line of the node's output says of its GPU miner, if it's one of
/// those: "[gpu] mining on <card>", "[gpu] not available (<why>); mining on
/// the CPU", or "[gpu] <why>; starting it again".
GpuMining? gpuMiningOf(String line) {
  final said = RegExp(r'^\[gpu\] (.*?)\s*$').firstMatch(line)?.group(1);
  if (said == null) return null;
  final mining = RegExp(r'^mining on (.+)$').firstMatch(said);
  if (mining != null) {
    final device = mining.group(1)!;
    return GpuMining(GpuMiningState.mining, device: device == 'the GPU' ? null : device);
  }
  final unavailable = RegExp(r'^not available \((.*)\); mining on the CPU$').firstMatch(said);
  if (unavailable != null) return GpuMining(GpuMiningState.unavailable, reason: unavailable.group(1));
  final again = RegExp(r'^(.*); starting it again$').firstMatch(said);
  if (again != null) return GpuMining(GpuMiningState.starting, reason: again.group(1));
  return null;
}

/// How far the node has come with the chain, as its output last said: the
/// lines README calls stable for programs showing progress. All empty once
/// it's at the tip and has checked everything.
class NodeSync {
  const NodeSync({this.fromCheckpoint = false, this.catchingUp, this.history});

  /// Starting from the app's checkpoint (PROTOCOL.md Section 7.10): taking
  /// the state of a recent block, before following the chain from there.
  final bool fromCheckpoint;

  /// Catching up with the chain: at this height, of as far as the peer's
  /// checked headers go so far.
  final (int, int)? catchingUp;

  /// Started from the checkpoint, checking every block from genesis up to
  /// the one it started at, in the background: this far, of that height.
  final (int, int)? history;

  @override
  bool operator ==(Object other) =>
      other is NodeSync &&
      other.fromCheckpoint == fromCheckpoint &&
      other.catchingUp == catchingUp &&
      other.history == history;

  @override
  int get hashCode => Object.hash(fromCheckpoint, catchingUp, history);

  @override
  String toString() => 'NodeSync(fromCheckpoint: $fromCheckpoint, catchingUp: $catchingUp, history: $history)';

  /// What `line` of the node's output changes; this, if nothing.
  NodeSync after(String line) {
    final l = line.trimRight();
    Match? match(String pattern) => RegExp(pattern).firstMatch(l);
    int at(Match m, int group) => int.parse(m.group(group)!);
    if (l.startsWith('[start] starting from the checkpoint at height ')) {
      return NodeSync(fromCheckpoint: true, catchingUp: catchingUp, history: history);
    }
    // Started: the blocks below are checked from genesis next.
    if (match(r'^\[start\] started at height (\d+)') case final m?) {
      return NodeSync(catchingUp: catchingUp, history: (0, at(m, 1)));
    }
    // No peer could: the node syncs from genesis like any other.
    if (l.startsWith('[start] no peer could start this node from the checkpoint')) {
      return NodeSync(catchingUp: catchingUp, history: history);
    }
    if (match(r'^\[sync\] at height (\d+) of (\d+) from ') case final m?) {
      return NodeSync(fromCheckpoint: fromCheckpoint, catchingUp: (at(m, 1), at(m, 2)), history: history);
    }
    if (match(r'^\[sync\] synced from .* to height \d+$') != null) {
      return NodeSync(fromCheckpoint: fromCheckpoint, history: history);
    }
    if (match(r'^\[check\] checked the chain from the genesis block to height (\d+) of (\d+)$') case final m?) {
      return NodeSync(fromCheckpoint: fromCheckpoint, catchingUp: catchingUp, history: (at(m, 1), at(m, 2)));
    }
    // A restart, or another peer, checks again from genesis.
    if (match(r'^\[check\] checking the chain from the genesis block to height (\d+) again$') case final m?) {
      return NodeSync(fromCheckpoint: fromCheckpoint, catchingUp: catchingUp, history: (0, at(m, 1)));
    }
    if (l.startsWith('[check] checked every block from the genesis block to height ')) {
      return NodeSync(fromCheckpoint: fromCheckpoint, catchingUp: catchingUp);
    }
    return this;
  }
}

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

  /// Whether this node can mine on the graphics card: its miner program is
  /// beside it. An older node has none, and would refuse the option.
  bool get canMineOnGpu;

  /// Its GPU miner, when it was started to mine on the card; null otherwise.
  GpuMining? get gpu;

  /// How far it has come with the chain, while running.
  NodeSync get sync;

  bool get available => state != LocalNodeState.unavailable;

  /// Starts it with `args` (stopping a running one first).
  Future<void> start(List<String> args);

  /// Stops it, if running.
  Future<void> stop();
}
