// Fee suggestions (whitepaper Section 5.2: one fee market for every
// transaction type).
//
// Fees are per byte, and a transaction weighs 264 bytes plus its content
// (PROTOCOL.md Section 2.3), so what to pay depends on the message's size.
// The node sends its mempool's fee bars (GetFees / Fees, Section 7.6): the
// pending transaction a new one must beat to make the next block, and the
// cheapest one when the mempool is full. When it doesn't answer, the client
// applies the node's rules (core mempool.rs, `fee_estimate`) to what it has
// seen itself: pending transactions relayed since it connected, and the fees
// in recent blocks.

import 'dart:math';

import '../protocol/models.dart';
import '../protocol/wire.dart';

/// Lowest fee consensus accepts (core mempool.rs, `MIN_FEE`).
const minFee = 1;

/// Pending transactions a node's mempool holds (core mempool.rs).
const mempoolCapacity = 50000;

/// Blocks back from the tip that recent included fees are taken from, as in
/// the node's report.
const feeWindow = 20;

/// The largest transaction: a full message with its salt.
const largestWeight = txBaseBytes + maxContentSize;

enum FeeSource {
  /// The node's own mempool figures.
  node,

  /// This client's estimate from what it has seen.
  local,
}

/// A fee-per-byte threshold to beat: the fee a pending transaction of
/// `weight` bytes pays.
class _Bar {
  const _Bar(this.fee, this.weight);

  final int fee;
  final int weight;

  /// Fee a transaction of `size` bytes must pay to beat this bar
  /// (mempool.rs `fee_to_beat`: strictly more per byte).
  int feeFor(int size) => fee * size ~/ weight + 1;
}

class FeeInfo {
  FeeInfo._({
    required this.source,
    required _Bar? nextBlockBar,
    required _Bar? poolEntryBar,
    required this.pending,
    this.recentLowest,
    this.recentMedian,
  })  : _nextBlockBar = nextBlockBar,
        _poolEntryBar = poolEntryBar;

  final FeeSource source;
  final _Bar? _nextBlockBar;
  final _Bar? _poolEntryBar;
  final int pending;

  /// Lowest fee included in recent blocks, and the median of each recent
  /// block's lowest fee; null when recent blocks were empty.
  final int? recentLowest;
  final int? recentMedian;

  /// Fee a transaction of `weight` bytes needs to be picked for the next
  /// block if every pending transaction competed for it.
  int nextBlockFee(int weight) => max(minFee, _nextBlockBar?.feeFor(weight) ?? minFee);

  /// Fee a transaction of `weight` bytes needs for a full mempool to accept it.
  int poolEntryFee(int weight) => max(minFee, _poolEntryBar?.feeFor(weight) ?? minFee);

  /// What to pay for a transaction of `weight` bytes to be accepted and
  /// mined in the next block as things stand.
  int suggested(int weight) => max(nextBlockFee(weight), poolEntryFee(weight));

  bool get congested => _nextBlockBar != null || _poolEntryBar != null;
}

_Bar? _bar(FeeBar? bar) => bar == null || bar.weight == 0 ? null : _Bar(bar.fee, bar.weight);

/// The node's figures (Fees). Advisory: nothing in them can be checked.
FeeInfo feeInfoFromNode(Fees fees) => FeeInfo._(
      source: FeeSource.node,
      nextBlockBar: _bar(fees.nextBlock),
      poolEntryBar: _bar(fees.poolEntry),
      pending: fees.pending,
      recentLowest: fees.recentLowest,
      recentMedian: fees.recentMedian,
    );

/// The node's `fee_estimate` over a set of pending transactions, given as
/// (fee, weight), and the lowest fee of each recent non-empty block.
FeeInfo estimateFees({
  required List<(int, int)> pending,
  required int maxBlockBytes,
  required List<int> recentBlockMins,
}) {
  // Highest fee per byte first, compared exactly (cross-multiplied).
  final byRate = [...pending]..sort((a, b) => (b.$1 * a.$2).compareTo(a.$1 * b.$2));
  var used = 0;
  (int, int)? lowestFitting;
  var overflow = false;
  for (final tx in byRate) {
    if (used + tx.$2 > maxBlockBytes) {
      overflow = true;
      break;
    }
    used += tx.$2;
    lowestFitting = tx;
  }
  final cheapest = byRate.isEmpty ? null : byRate.last;
  final mins = [...recentBlockMins]..sort();
  return FeeInfo._(
    source: FeeSource.local,
    nextBlockBar: overflow && lowestFitting != null ? _Bar(lowestFitting.$1, lowestFitting.$2) : null,
    poolEntryBar: pending.length >= mempoolCapacity && cheapest != null ? _Bar(cheapest.$1, cheapest.$2) : null,
    pending: pending.length,
    recentLowest: mins.isEmpty ? null : mins.first,
    recentMedian: mins.isEmpty ? null : mins[mins.length ~/ 2],
  );
}
