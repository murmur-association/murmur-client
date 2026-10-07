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
// retracted messages are deleted (--prune-retracted). It listens only on
// this machine (--port 127.0.0.1:0): it connects out to the network, and
// peers aren't told an address nobody can reach. It holds no key: mining
// pays the wallet's address.
//
// Mining can use the graphics card (--gpu): the node then runs murmur-miner,
// shipped beside it, and mines on the processor whenever the card can't be
// used. What the app shows of it comes from the node's own output (the
// "[gpu]" lines), never from its control port.

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
  bool gpu = false,
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

  bool get available => state != LocalNodeState.unavailable;

  /// Starts it with `args` (stopping a running one first).
  Future<void> start(List<String> args);

  /// Stops it, if running.
  Future<void> stop();
}
