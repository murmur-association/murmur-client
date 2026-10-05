// What the live network says about a checkpoint, without taking any node's
// word (see refresh_checkpoint.dart and check_checkpoint.dart):
// - each node is asked separately, at its own address;
// - with the client itself, which starts from the checkpoint this source
//   ships (so the node's chain must contain it) and checks every header
//   back to genesis;
// - and the nodes must agree.
// Only the peer-to-peer port is used.

import 'dart:async';
import 'dart:io';

import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/services/node_client.dart';

/// The public testnet's nodes: every address this name stands for.
/// MURMUR_CHECKPOINT_NODES replaces it (`host:port,host:port`).
const defaultNodes = 'testnet-seed.murmur.info:7878';

/// The network whose checkpoint this is about.
const network = NetworkInfo.whitepaper;

/// How many nodes must answer (and agree) at least.
const minNodes = 2;

/// A node's chain, fully checked by a client.
class NodeChain {
  NodeChain(this.address, this.client);

  final String address;
  final MurmurClient client;

  int get height => client.height;
  String hashAt(int h) => toHex(client.hashAt(h));
}

/// Why the live network can't vouch for a checkpoint.
class CheckpointProblem implements Exception {
  CheckpointProblem(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Every node address to ask, as `(ip, port)`.
Future<List<(String, int)>> nodeAddresses() async {
  final found = <(String, int)>{};
  for (final entry in (Platform.environment['MURMUR_CHECKPOINT_NODES'] ?? defaultNodes).split(',')) {
    final at = entry.trim().lastIndexOf(':');
    if (at <= 0) throw CheckpointProblem('"$entry" is not host:port');
    final host = entry.trim().substring(0, at), port = int.parse(entry.trim().substring(at + 1));
    for (final address in await InternetAddress.lookup(host)) {
      found.add((address.address, port));
    }
  }
  return found.toList();
}

/// Each reachable node's chain, synced from the shipped checkpoint (if any)
/// and checked back to genesis. A node that can't be reached is left out
/// (and said so with `say`); a node on a chain without the shipped
/// checkpoint, or sending anything invalid, is a [CheckpointProblem]: the
/// network doesn't agree with this source. Dispose the clients when done.
Future<List<NodeChain>> checkedChains(void Function(String line) say) async {
  final addresses = await nodeAddresses();
  say('${network.id}: ${addresses.length} node address(es), '
      'starting from ${network.checkpoint == null ? 'genesis' : 'the shipped checkpoint at ${network.checkpoint!.height}'}');
  final chains = <NodeChain>[];
  for (final (ip, port) in addresses) {
    final name = '$ip:$port';
    final client = MurmurClient();
    await client.connect(ip, port);
    final deadline = DateTime.now().add(const Duration(minutes: 5));
    String? unreachable;
    while (true) {
      final e = client.error;
      if (e != null) {
        final kind = e.kind == LinkErrorKind.syncFailed ? (e.cause?.kind ?? e.kind) : e.kind;
        if (const {LinkErrorKind.unreachable, LinkErrorKind.timeout, LinkErrorKind.closed, LinkErrorKind.connection}
            .contains(kind)) {
          unreachable = kind.name;
          break;
        }
        client.dispose();
        throw CheckpointProblem('$name does not serve the chain this source expects: ${kind.name} ${e.detail}');
      }
      final synced = client.state == LinkState.live && client.height > 0 && client.checkingFromCheckpoint == null;
      if (synced && client.network?.id == network.id) break;
      if (client.network != null && client.network!.id != network.id) {
        client.dispose();
        throw CheckpointProblem('$name is on ${client.network!.id}, not ${network.id}');
      }
      if (DateTime.now().isAfter(deadline)) {
        unreachable = 'no full sync in five minutes';
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (unreachable != null) {
      say('  $name: left out ($unreachable)');
      client.dispose();
      continue;
    }
    say('  $name: height ${client.height}, checked back to genesis');
    chains.add(NodeChain(name, client));
  }
  if (chains.length < minNodes) {
    for (final c in chains) {
      c.client.dispose();
    }
    throw CheckpointProblem('only ${chains.length} node(s) answered; $minNodes must agree');
  }
  return chains;
}

/// The hash every chain has at `height`, or a [CheckpointProblem] if they
/// differ.
String agreedHashAt(List<NodeChain> chains, int height) {
  final hashes = {for (final c in chains) c.address: c.hashAt(height)};
  if (hashes.values.toSet().length != 1) {
    throw CheckpointProblem('the nodes disagree on block $height: $hashes');
  }
  return hashes.values.first;
}
