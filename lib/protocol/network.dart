// Per-network consensus parameters the client needs: enough to recognize the
// network from its genesis hash, check headers (difficulty), sign for it, and
// credit block rewards when rebuilding balances. Mirrors ChainParams in murmur core's
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
    this.initialSubsidy = 25 * unitsPerToken,
    this.tailEmission = unitsPerToken,
    this.minFee = unitsPerToken ~/ 2,
    this.known = true,
    this.checkpoint,
  });

  final String id;
  final int genesisTimestamp;

  /// Genesis target is (2^256 − 1) >> this.
  final int genesisTargetShift;
  final int targetBlockSecs;
  final int halvingInterval;

  /// Block byte cap (Section 4.4).
  final int maxBlockBytes;

  /// Each block pays its miner ceil(pool / this) from the burn pool.
  final int burnPayoutBlocks;

  /// In units, as every amount.
  final int initialSubsidy;
  final int tailEmission;

  /// The least fee a transaction may pay, by consensus (PROTOCOL.md Section
  /// 2.3): one paying less is invalid, not merely refused.
  final int minFee;

  /// False when the node's genesis matched none of the built-in networks,
  /// in which case reward accounting falls back to whitepaper values and the
  /// difficulty rule isn't checked (its parameters aren't known).
  final bool known;

  /// Where this release starts syncing, if it ships one. The demo network
  /// has none: every demo node mines its own chain.
  final Checkpoint? checkpoint;

  /// A public test network: its tokens are for testing only.
  bool get isTestnet => id.startsWith('murmur-testnet-');

  Uint8List get genesisTarget => u256Bytes(u256Max >> genesisTargetShift);

  /// What a signature covers before the transaction itself, and the genesis
  /// block's `prev_hash`: `H(network id)` (PROTOCOL.md Section 2.2). A
  /// transaction signed for one network is invalid on every other.
  Uint8List get tag => sha256Bytes(utf8.encode(id));

  /// The difficulty rule's two times (PROTOCOL.md Section 4), in seconds: a
  /// parent this much faster or slower than the block time halves or doubles
  /// the target, and a block later than its parent by more than the slack is
  /// eased at that same rate.
  int get difficultyTau => 30 * targetBlockSecs;
  int get difficultySlack => 40 * targetBlockSecs;

  static const whitepaper = NetworkInfo(
    id: 'murmur-testnet-15',
    genesisTimestamp: 1793404800, // 2026-10-31T00:00:00Z
    genesisTargetShift: 8,
    targetBlockSecs: 30,
    halvingInterval: 4200000,
    maxBlockBytes: 1000000,
    burnPayoutBlocks: 2880,
    checkpoint: Checkpoint(8500, '000000c4eb2d8385417e0f60b1b8014280f7b80b6ec0667fe22c6db0a57da61c'),
  );

  static const demo = NetworkInfo(
    id: 'murmur-demo-15',
    genesisTimestamp: 0,
    genesisTargetShift: 4,
    targetBlockSecs: 2,
    halvingInterval: 2000,
    maxBlockBytes: 200000,
    burnPayoutBlocks: 100,
  );

  static const all = [whitepaper, demo];

  /// Block subsidy at `height`: halves exactly every `halvingInterval`
  /// blocks (25, 12.5, 6.25, 3.125 and 1.5625 tokens), floored at
  /// `tailEmission`.
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
        nonce: u64Bytes(0),
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
      maxBlockBytes: 1000000,
      burnPayoutBlocks: 2880,
      known: false,
    );
  }
}
