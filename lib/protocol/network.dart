// Per-network consensus parameters the client needs: enough to recognize the
// network from its genesis hash, check headers (retarget), and credit block
// rewards when rebuilding balances. Mirrors ChainParams in murmur core's
// consensus.rs.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'bytes.dart';
import 'models.dart';

/// A block a client release starts from instead of genesis (PROTOCOL.md
/// Section 7.7), taken from a node with `murmur-node ctl checkpoint`. The
/// client checks everything after it, then the headers back to genesis in
/// the background, and stops if they don't lead to it.
class Checkpoint {
  const Checkpoint(this.height, this.hash);

  final int height;

  /// The block hash, hex.
  final String hash;

  /// Whether this could be a real checkpoint: a height above genesis and a
  /// 32-byte hash in lowercase hex, as `ctl checkpoint` prints it.
  bool get wellFormed => height >= 1 && RegExp(r'^[0-9a-f]{64}$').hasMatch(hash);
}

class NetworkInfo {
  const NetworkInfo({
    required this.id,
    required this.genesisTimestamp,
    required this.genesisTargetShift,
    required this.targetBlockSecs,
    required this.halvingInterval,
    required this.maxBlockBytes,
    required this.burnPayoutBlocks,
    required this.lwmaWindow,
    this.maxSwingPct = 16,
    this.initialSubsidy = 25,
    this.tailEmission = 1,
    this.known = true,
    this.checkpoint,
  });

  final String id;
  final int genesisTimestamp;

  /// Genesis target is u128::MAX >> this.
  final int genesisTargetShift;
  final int targetBlockSecs;
  final int halvingInterval;

  /// Block byte cap (Section 4.4).
  final int maxBlockBytes;

  /// Each block pays its miner ceil(pool / this) from the burn pool.
  final int burnPayoutBlocks;
  final int initialSubsidy;
  final int tailEmission;

  /// Blocks the difficulty retarget averages over, and its largest step (%).
  final int lwmaWindow;
  final int maxSwingPct;

  /// False when the node's genesis matched none of the built-in networks,
  /// in which case reward accounting falls back to whitepaper values and the
  /// difficulty retarget isn't checked (its parameters aren't known).
  final bool known;

  /// Where this release starts syncing, if it ships one. The demo network
  /// has none: every demo node mines its own chain.
  final Checkpoint? checkpoint;

  /// A public test network: its tokens are for testing only.
  bool get isTestnet => id.startsWith('murmur-testnet-');

  BigInt get genesisTarget => ((BigInt.one << 128) - BigInt.one) >> genesisTargetShift;

  static const whitepaper = NetworkInfo(
    id: 'murmur-testnet-9',
    genesisTimestamp: 1790208000, // 2026-09-24T00:00:00Z
    genesisTargetShift: 8,
    targetBlockSecs: 30,
    halvingInterval: 4200000,
    maxBlockBytes: 2000000,
    burnPayoutBlocks: 2880,
    lwmaWindow: 90,
    // Written by tool/refresh_checkpoint.dart: the testnet's nodes, asked
    // one by one, agreed on it, on a chain checked from genesis that holds
    // the checkpoint shipped before it (the first, block 16,000, came from
    // `murmur-node ctl checkpoint` on a node the project trusts). Refresh it
    // with every release (AGENTS.md, Recipes); the release job checks it
    // against the live network, and test/network_test.dart its form.
    checkpoint: Checkpoint(24800, '000001c3527c4b783ddb5bfb37ae29b9b71a0594115d0ab9010a7e5429c32fae'),
  );

  static const demo = NetworkInfo(
    id: 'murmur-demo-9',
    genesisTimestamp: 0,
    genesisTargetShift: 4,
    targetBlockSecs: 2,
    halvingInterval: 2000,
    maxBlockBytes: 200000,
    burnPayoutBlocks: 100,
    lwmaWindow: 20,
  );

  static const all = [whitepaper, demo];

  /// Block subsidy at `height`: halves every `halvingInterval` blocks,
  /// floored at `tailEmission`.
  int subsidyAt(int height) {
    final halvings = height ~/ halvingInterval;
    // Halve by division: on the web, `>>` only handles shifts below 32.
    var subsidy = initialSubsidy;
    for (var i = 0; i < halvings && subsidy > 0; i++) {
      subsidy ~/= 2;
    }
    return max(subsidy, tailEmission);
  }

  /// What a block pays its miner out of a burn pool holding `pool`:
  /// ceil(pool / burnPayoutBlocks), so the pool always empties.
  int burnPayout(int pool) => (pool + burnPayoutBlocks - 1) ~/ burnPayoutBlocks;

  BlockHeader genesisHeader() => BlockHeader(
        height: 0,
        prevHash: sha256Bytes(utf8.encode(id)),
        merkleRoot: Uint8List(32),
        stateRoot: Uint8List(32), // the empty state tree
        filterHash: sha256Bytes(Uint8List(4)), // the empty filter, 00 00 00 00
        historyRoot: Uint8List(32), // no earlier blocks
        timestamp: genesisTimestamp,
        target: genesisTarget,
        nonce: 0,
        miner: Uint8List(32),
      );

  static NetworkInfo forGenesis(Uint8List genesis) {
    for (final n in all) {
      if (bytesEqual(n.genesisHeader().hash, genesis)) return n;
    }
    return const NetworkInfo(
      id: 'unknown network',
      genesisTimestamp: 0,
      genesisTargetShift: 8,
      targetBlockSecs: 30,
      halvingInterval: 4200000,
      maxBlockBytes: 2000000,
      burnPayoutBlocks: 2880,
      lwmaWindow: 90,
      known: false,
    );
  }
}
