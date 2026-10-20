// Header rules the client checks itself (PROTOCOL.md Sections 3.5 and 4):
// median-time-past and the difficulty rule. With the proof of work and the
// history root, they're what makes a header chain valid on its own, without
// the blocks. Mirrors murmur core's difficulty.rs, in integer arithmetic on
// 256-bit numbers (BigInt here): every node computes the same target.

import 'dart:typed_data';

import 'bytes.dart';
import 'commitments.dart';
import 'models.dart';
import 'network.dart';

/// Time differences are limited to this many seconds either way, which no
/// real chain reaches, so that the node's signed 64-bit arithmetic can't
/// overflow: `floor((2^63 − 1) / 131072)`.
const _timeLimit = 70368744177663;

final BigInt _half48 = BigInt.one << 47;
final BigInt _c1 = BigInt.from(195766423245049);
final BigInt _c2 = BigInt.from(971821376);
final BigInt _c3 = BigInt.from(5127);
final BigInt _two16 = BigInt.from(65536);

/// `floor(a / b)` for a positive `b`: toward minus infinity, where `~/`
/// rounds toward zero. Dart's `%` is never negative for a positive divisor.
BigInt _floorDiv(BigInt a, BigInt b) => (a - a % b) ~/ b;

/// `65536 × 2^(f / 65536)` for `f` in 0..65535, to within 0.013%: the cubic
/// approximation of Bitcoin Cash's difficulty rule (aserti3-2d).
BigInt difficultyFactor(int f) {
  final x = BigInt.from(f);
  return _two16 + ((_c1 * x + _c2 * x * x + _c3 * x * x * x + _half48) >> 48);
}

/// `t × 2^(e / 65536)`, limited to 1 below and 2^256 − 1 above. Bits shifted
/// out at the bottom are dropped.
BigInt scaleTarget(BigInt t, BigInt e) {
  final whole = _floorDiv(e, _two16);
  final f = (e - whole * _two16).toInt();
  final product = t * difficultyFactor(f);
  // Far past either limit, without building a number that long.
  if (whole > BigInt.from(600)) return product == BigInt.zero ? BigInt.one : u256Max;
  if (whole < BigInt.from(-600)) return BigInt.one;
  final shift = whole.toInt() - 16;
  final scaled = shift >= 0 ? product << shift : product >> -shift;
  if (scaled > u256Max) return u256Max;
  return scaled < BigInt.one ? BigInt.one : scaled;
}

int _limited(int seconds) => seconds > _timeLimit ? _timeLimit : (seconds < -_timeLimit ? -_timeLimit : seconds);

/// The target a block stamped `timestamp` must carry, from its parent's
/// target, how long the parent took, and how long after its parent the block
/// itself comes (PROTOCOL.md Section 4). The first block after genesis keeps
/// the genesis target, whatever its time; `grandparent` is null only then.
Uint8List nextTarget({
  required BlockHeader parent,
  required BlockHeader? grandparent,
  required int timestamp,
  required NetworkInfo net,
}) {
  if (grandparent == null) return net.genesisTarget;
  final t = net.targetBlockSecs, s = net.difficultySlack;
  // Signed: a parent may be stamped before its own parent.
  var took = _limited(parent.timestamp - grandparent.timestamp);
  if (took > s) took = s;
  var late = _limited(timestamp - parent.timestamp) - s;
  if (late < 0) late = 0;
  // In 1/65536ths of a doubling, one division (protocol 15): a block late
  // beyond the slack is eased at the rate of a slow parent. BigInt: the
  // limits above allow products past 2^53, which a browser's numbers don't
  // hold.
  final exponent = _floorDiv(BigInt.from(took - t + late) * _two16, BigInt.from(net.difficultyTau));
  // A parent found exactly on time, and a block within the slack: unchanged
  // (a parent target of 0, which no chain holds, gives 1, as the node does).
  if (exponent == BigInt.zero && parent.targetValue > BigInt.zero) return parent.target;
  return u256Bytes(scaleTarget(parent.targetValue, exponent));
}

/// The median of the timestamps of the last 11 blocks ending at the parent
/// (all of them near genesis); with an even count, the upper median.
int medianTimePast(List<BlockHeader> lastUpTo11) {
  final times = [for (final h in lastUpTo11) h.timestamp]..sort();
  return times[times.length ~/ 2];
}

/// Checks header `h` as a node does (PROTOCOL.md Section 7.2): it links to
/// its parent, meets its target, is later than the median of the last 11
/// timestamps, carries the target the difficulty rule gives it, and commits
/// to the header history through its parent (`history`). `at` looks up
/// earlier headers (genesis included). Throws [FormatException] naming the
/// broken rule.
///
/// The client runs this on every header it accepts; `tool/header_bench.dart`
/// times it.
void checkHeaderRules(BlockHeader h, BlockHeader? Function(int height) at, HistoryPeaks history, NetworkInfo net) {
  final parent = at(h.height - 1);
  if (parent == null || !bytesEqual(h.prevHash, parent.hash)) {
    throw FormatException('header ${h.height} does not link to its parent');
  }
  if (!h.meetsTarget) throw FormatException('header ${h.height} does not meet its proof-of-work target');
  // The last 11 ending at the parent. Just after a checkpoint they are the
  // checkpoint's context (the 11 headers before it); a header whose window
  // isn't all at hand is checked for the rest.
  final from = h.height - 11 < 0 ? 0 : h.height - 11;
  final last11 = <BlockHeader>[];
  for (var i = from; i < h.height; i++) {
    final header = at(i);
    if (header == null) break;
    last11.add(header);
  }
  if (last11.length == h.height - from && h.timestamp <= medianTimePast(last11)) {
    throw FormatException('header ${h.height} is not later than the median of the last 11');
  }
  // An unrecognized network's difficulty parameters aren't known.
  final grandparent = h.height >= 2 ? at(h.height - 2) : null;
  if (net.known && (h.height < 2 || grandparent != null)) {
    final target = nextTarget(parent: parent, grandparent: grandparent, timestamp: h.timestamp, net: net);
    if (!bytesEqual(h.target, target)) {
      throw FormatException('header ${h.height} does not carry the target the difficulty rule gives it');
    }
  }
  if (!bytesEqual(h.historyRoot, history.root)) {
    throw FormatException('header ${h.height} commits to a different header history');
  }
}
