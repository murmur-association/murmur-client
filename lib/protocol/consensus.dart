// Header rules the client checks itself (PROTOCOL.md Sections 3.5 and 4):
// median-time-past and the difficulty retarget. With the proof of work and
// the history root, they're what makes a header chain valid on its own,
// without the blocks. Mirrors murmur core's difficulty.rs, in integer
// arithmetic (BigInt here, u128 there): every node computes the same target.

import 'bytes.dart';
import 'commitments.dart';
import 'models.dart';
import 'network.dart';

final BigInt _u128Max = (BigInt.one << 128) - BigInt.one;
final BigInt _u64Max = (BigInt.one << 64) - BigInt.one;

/// A header's difficulty: expected hashes per block (its work), capped at
/// 2^64 − 1, as in difficulty.rs.
BigInt _difficulty(BlockHeader h) {
  if (h.target == BigInt.zero) return _u64Max;
  final d = h.work;
  return d > _u64Max ? _u64Max : d;
}

BigInt _target(BigInt difficulty) => _u128Max ~/ (difficulty < BigInt.one ? BigInt.one : difficulty);

/// The target the block after `window` must carry: `window` is the headers
/// from the parent back through at most `lwmaWindow + 1` blocks, oldest
/// first (fewer near genesis).
BigInt nextTarget(List<BlockHeader> window, NetworkInfo net) {
  if (window.length < 2) {
    return window.isEmpty ? net.genesisTarget : window.last.target;
  }
  final w = window.length > net.lwmaWindow + 1 ? window.sublist(window.length - (net.lwmaWindow + 1)) : window;
  // Solvetimes in sixths of a second, so T/6 is exactly T.
  final t = net.targetBlockSecs;
  final minSt = t, maxSt = 36 * t;
  var weightedDifficulty = BigInt.zero, weightedSolvetime = BigInt.zero;
  for (var i = 1; i < w.length; i++) {
    final weight = BigInt.from(i);
    // Timestamps can go backwards (only median-time-past is enforced).
    final raw = (w[i].timestamp - w[i - 1].timestamp) * 6;
    final solvetime = raw < minSt ? minSt : (raw > maxSt ? maxSt : raw);
    weightedDifficulty += weight * _difficulty(w[i]);
    weightedSolvetime += weight * BigInt.from(solvetime);
  }
  final rawNext = weightedDifficulty * BigInt.from(6 * t) ~/ weightedSolvetime;
  final prev = _difficulty(w.last);
  final swing = BigInt.from(net.maxSwingPct);
  final hundred = BigInt.from(100);
  final minAllowed = prev * (hundred - swing) ~/ hundred;
  var maxAllowed = prev * (hundred + swing) ~/ hundred;
  // At least one above: at very low difficulty the percentage rounds to nothing.
  if (maxAllowed < prev + BigInt.one) maxAllowed = prev + BigInt.one;
  final clamped = rawNext < minAllowed ? minAllowed : (rawNext > maxAllowed ? maxAllowed : rawNext);
  return _target(clamped);
}

/// The median of the timestamps of the last 11 blocks ending at the parent
/// (all of them near genesis); with an even count, the upper median.
int medianTimePast(List<BlockHeader> lastUpTo11) {
  final times = [for (final h in lastUpTo11) h.timestamp]..sort();
  return times[times.length ~/ 2];
}

/// Checks header `h` as a node does (PROTOCOL.md Section 7.2): it links to
/// its parent, meets its target, is later than the median of the last 11
/// timestamps, carries the retarget's target, and commits to the header
/// history through its parent (`history`). `at` looks up earlier headers
/// (genesis included). Throws [FormatException] naming the broken rule.
///
/// The client runs this on every header it accepts; `tool/header_bench.dart`
/// times it.
void checkHeaderRules(BlockHeader h, BlockHeader? Function(int height) at, HistoryPeaks history, NetworkInfo net) {
  final parent = at(h.height - 1);
  if (parent == null || !bytesEqual(h.prevHash, parent.hash)) {
    throw FormatException('header ${h.height} does not link to its parent');
  }
  if (!h.meetsTarget) throw FormatException('header ${h.height} does not meet its proof-of-work target');
  // The window of earlier headers: the parent back through lwma_window + 1.
  final window = <BlockHeader>[];
  for (var i = h.height - 1; i >= 0 && i >= h.height - 1 - net.lwmaWindow; i--) {
    final header = at(i);
    if (header == null) break;
    window.insert(0, header);
  }
  final complete = window.first.height == (h.height - 1 - net.lwmaWindow < 0 ? 0 : h.height - 1 - net.lwmaWindow);
  // Just after a checkpoint the window is the checkpoint's context (90
  // headers), enough for both rules.
  if (complete) {
    final last11 = window.length > 11 ? window.sublist(window.length - 11) : window;
    if (h.timestamp <= medianTimePast(last11)) {
      throw FormatException('header ${h.height} is not later than the median of the last 11');
    }
    // An unrecognized network's retarget parameters aren't known.
    if (net.known && h.target != nextTarget(window, net)) {
      throw FormatException('header ${h.height} does not carry the retarget\'s target');
    }
  }
  if (!bytesEqual(h.historyRoot, history.root)) {
    throw FormatException('header ${h.height} commits to a different header history');
  }
}
