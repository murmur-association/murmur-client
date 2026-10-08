// The three commitments every header carries (PROTOCOL.md Section 3.6), so
// a client holding only headers can check what a node tells it:
//
// - the state tree (`state_root`): a sparse Merkle tree over accounts,
//   threads, names, flags, the burn pool and the total issued;
// - the block filter (`filter_hash`): a Golomb-Rice coded set of the
//   addresses and references a block's transactions touch;
// - the header history (`history_root`): a Merkle Mountain Range over every
//   earlier block, whose nodes also commit to work, times and targets.
//
// Mirrors murmur core's smt.rs, filter.rs and mmr.rs. Integers above 2^32
// avoid shifts (on the web, `>>` and `<<` are 32-bit) and 64-bit products
// go through BigInt.

import 'dart:typed_data';

import 'bytes.dart';
import 'models.dart';

final Uint8List _zero32 = Uint8List(32);

Uint8List _tagged(int tag, List<int> a, List<int> b) => sha256Bytes([tag, ...a, ...b]);

/// `2^k` without shifting.
int _pow2(int k) {
  var p = 1;
  for (var i = 0; i < k; i++) {
    p *= 2;
  }
  return p;
}

// ---- state tree -------------------------------------------------------------------

/// Key of an account's entry ([AccountEntry]).
Uint8List accountKey(Uint8List address) => sha256Bytes([0x00, ...address]);

/// Key of a thread's entry ([ThreadEntry]); `root` is the txid of the
/// thread's first message.
Uint8List threadKey(Uint8List root) => sha256Bytes([0x04, ...root]);

/// Key of an address's name: the `message_hash` of its latest Name.
Uint8List nameKey(Uint8List address) => sha256Bytes([0x05, ...address]);

/// A list's digest after `txids` are added to one that stood at `start`:
/// each entry makes it `H(digest ‖ txid)` (PROTOCOL.md Section 3.6). A list
/// starts at `0^32`.
Uint8List chainDigest(Uint8List start, Iterable<Uint8List> txids) {
  var digest = start;
  for (final txid in txids) {
    digest = sha256Bytes([...digest, ...txid]);
  }
  return digest;
}

/// An account's entry: its balance and nonce, and the count and digest of
/// the two lists the state commits to for it. What it sent has `nonce`
/// entries; what credited it (a transfer to it, a reply in a thread it
/// started) has `credits`. A block's reward is in neither.
class AccountEntry {
  const AccountEntry(this.balance, this.nonce, this.sentDigest, this.credits, this.creditDigest);

  /// An address the chain has never seen: no entry.
  static final empty = AccountEntry(0, 0, Uint8List(32), 0, Uint8List(32));

  /// `balance:u64le ‖ nonce:u64le ‖ sent_digest:32 ‖ credits:u64le ‖
  /// credit_digest:32`, or null if `value` isn't that.
  static AccountEntry? parse(Uint8List value) {
    if (value.length != 88) return null;
    return AccountEntry(
      readU64le(value),
      readU64le(value, 8),
      value.sublist(16, 48),
      readU64le(value, 48),
      value.sublist(56, 88),
    );
  }

  final int balance, nonce, credits;
  final Uint8List sentDigest, creditDigest;
}

/// A thread's entry: who started it, and the count and digest of its events
/// (its Replies and the Flags that name it, in chain order).
class ThreadEntry {
  const ThreadEntry(this.author, this.events, this.digest);

  /// `author:32 ‖ events:u64le ‖ digest:32`, or null if `value` isn't that.
  static ThreadEntry? parse(Uint8List value) {
    if (value.length != 72) return null;
    return ThreadEntry(value.sublist(0, 32), readU64le(value, 32), value.sublist(40, 72));
  }

  final Uint8List author;
  final int events;
  final Uint8List digest;
}

/// `flag_key = H(from ‖ reference)` (PROTOCOL.md Section 2.3).
Uint8List flagKeyOf(Uint8List from, Uint8List reference) => sha256Bytes([...from, ...reference]);

/// Key of a flag's entry, holding `0x01` once the flag is on the chain.
Uint8List flagEntryKey(Uint8List flagKey) => sha256Bytes([0x01, ...flagKey]);

/// Key of the burn pool's entry, `pool:u64le`.
final Uint8List poolKey = sha256Bytes([0x02]);

/// Key of the total issued, `issued:u64le`.
final Uint8List issuedKey = sha256Bytes([0x03]);

/// A u64 stored little-endian (state values). As [ByteReader.u64], 2^53 and
/// above is refused: nothing the state counts gets there.
int readU64le(Uint8List bytes, [int offset = 0]) {
  final d = ByteData.sublistView(bytes);
  final hi = d.getUint32(offset + 4, Endian.little);
  if (hi >= 0x200000) throw const FormatException('a number too large to be valid here');
  return hi * 4294967296 + d.getUint32(offset, Endian.little);
}

Uint8List u64le(int v) => (ByteWriter()..u64(v, Endian.little)).take();

bool _bit(Uint8List key, int depth) => key[depth ~/ 8] & (0x80 >> (depth % 8)) != 0;

/// `H(0x00 ‖ key ‖ H(value))`.
Uint8List stateLeafHash(Uint8List key, Uint8List valueHash) => _tagged(0x00, key, valueHash);

/// What a state proof ends in, below its last sibling.
sealed class StateTerminal {
  const StateTerminal();
}

/// An empty subtree: the key isn't in the tree.
class EmptyTerminal extends StateTerminal {
  const EmptyTerminal();
}

/// The key's own entry, with its value.
class ValueTerminal extends StateTerminal {
  const ValueTerminal(this.value);
  final Uint8List value;
}

/// Another entry alone where the key would be: the key isn't in the tree.
class OtherTerminal extends StateTerminal {
  const OtherTerminal(this.key, this.valueHash);
  final Uint8List key;
  final Uint8List valueHash;
}

class StateProof {
  const StateProof(this.siblings, this.terminal);

  /// Sibling hashes from the terminal up: the first at depth
  /// `siblings.length - 1`, the last at depth 0.
  final List<Uint8List> siblings;
  final StateTerminal terminal;
}

/// What a checked proof says about its key.
class StateFact {
  const StateFact(this.value);

  /// The key's value, or null if it provably isn't in the tree.
  final Uint8List? value;
}

/// Checks `proof` for `key` against `root`: the key's value or its proven
/// absence, or null if the proof doesn't match the root.
StateFact? verifyStateProof(Uint8List root, Uint8List key, StateProof proof) {
  final depth = proof.siblings.length;
  if (depth > 256 || key.length != 32) return null;
  Uint8List hash;
  Uint8List? value;
  switch (proof.terminal) {
    case EmptyTerminal():
      hash = _zero32;
    case ValueTerminal(value: final v):
      hash = stateLeafHash(key, sha256Bytes(v));
      value = v;
    case OtherTerminal(key: final other, valueHash: final valueHash):
      // It must sit where `key` would: the same path so far, another key.
      if (other.length != 32 || bytesEqual(other, key)) return null;
      for (var d = 0; d < depth; d++) {
        if (_bit(other, d) != _bit(key, d)) return null;
      }
      hash = stateLeafHash(other, valueHash);
  }
  for (var i = 0; i < depth; i++) {
    final sibling = proof.siblings[i];
    hash = _bit(key, depth - 1 - i) ? _tagged(0x01, sibling, hash) : _tagged(0x01, hash, sibling);
  }
  return bytesEqual(hash, root) ? StateFact(value) : null;
}

/// The root of the tree holding exactly these entries (key hex -> value):
/// what a node's `state_root` must be for that state.
Uint8List stateRootOf(Map<String, Uint8List> entries) {
  final keys = entries.keys.toList()..sort();
  final sorted = [for (final k in keys) (fromHex(k), sha256Bytes(entries[k]!))];
  Uint8List subtree(int from, int to, int depth) {
    if (from == to) return _zero32;
    if (to - from == 1) return stateLeafHash(sorted[from].$1, sorted[from].$2);
    // Sorted keys: those with bit `depth` clear come first.
    var split = from;
    while (split < to && !_bit(sorted[split].$1, depth)) {
      split++;
    }
    return _tagged(0x01, subtree(from, split, depth + 1), subtree(split, to, depth + 1));
  }

  return subtree(0, sorted.length, 0);
}

// ---- block filter -----------------------------------------------------------------

const filterP = 19;
const filterM = 784931;
final int _pSize = _pow2(filterP);

/// The distinct items a block's filter holds: each transaction's sender, a
/// Raw's `to`, a Reply's or a Flag's `reference`, and a Flag's `thread`. Not
/// the content hash, and not who a Reply pays: every item is in the
/// transactions themselves, so someone watching for replies to their
/// threads watches for the threads' txids.
List<Uint8List> blockFilterItems(List<Transaction> transactions) {
  final seen = <String, Uint8List>{};
  for (final tx in transactions) {
    seen.putIfAbsent(toHex(tx.from), () => tx.from);
    if (tx.to != null) seen.putIfAbsent(toHex(tx.to!), () => tx.to!);
    if (tx.reference != null) seen.putIfAbsent(toHex(tx.reference!), () => tx.reference!);
    if (tx.thread != null) seen.putIfAbsent(toHex(tx.thread!), () => tx.thread!);
  }
  return seen.values.toList();
}

/// `(u64be(H(prev_hash ‖ item)[0..8]) × F) >> 64`, with a 128-bit product.
int _hashToRange(Uint8List prevHash, Uint8List item, int f) {
  final h = sha256Bytes([...prevHash, ...item]);
  var x = BigInt.zero;
  for (var i = 0; i < 8; i++) {
    x = (x << 8) | BigInt.from(h[i]);
  }
  return ((x * BigInt.from(f)) >> 64).toInt();
}

/// The filter holding `items` (distinct), keyed with the block's `prev_hash`.
Uint8List buildFilter(Uint8List prevHash, List<Uint8List> items) {
  final n = items.length;
  final f = n * filterM;
  final values = [for (final item in items) _hashToRange(prevHash, item, f)]..sort();
  final out = BytesBuilder()..add((ByteWriter()..u32(n)).take());
  var byte = 0, used = 0;
  void bit(bool b) {
    if (b) byte |= 0x80 >> used;
    used++;
    if (used == 8) {
      out.addByte(byte);
      byte = 0;
      used = 0;
    }
  }

  var last = 0;
  for (final v in values) {
    final d = v - last;
    last = v;
    for (var q = d ~/ _pSize; q > 0; q--) {
      bit(true);
    }
    bit(false);
    final low = d % _pSize;
    for (var i = filterP - 1; i >= 0; i--) {
      bit((low >> i) & 1 == 1);
    }
  }
  if (used > 0) out.addByte(byte);
  return out.takeBytes();
}

/// The filter of a block: what `filter_hash` commits to.
Uint8List blockFilter(Block b) => buildFilter(b.header.prevHash, blockFilterItems(b.transactions));

/// Whether a block's filter may hold any of `items`: false means certainly
/// not, true probably (about 1 in [filterM] per item is a false positive).
/// Null if the filter is malformed.
bool? filterMatchesAny(Uint8List filter, Uint8List prevHash, List<Uint8List> items) {
  if (filter.length < 4) return null;
  final n = ByteData.sublistView(filter).getUint32(0);
  if (n > 1048576) return null;
  if (n == 0 || items.isEmpty) return false;
  final f = n * filterM;
  final wanted = [for (final item in items) _hashToRange(prevHash, item, f)]..sort();
  var pos = 32; // bits into the filter, past the count
  final bits = filter.length * 8;
  bool? readBit() {
    if (pos >= bits) return null;
    final b = filter[pos ~/ 8] & (0x80 >> (pos % 8)) != 0;
    pos++;
    return b;
  }

  var value = 0;
  var next = 0;
  for (var i = 0; i < n; i++) {
    var q = 0;
    while (true) {
      final b = readBit();
      if (b == null) return null;
      if (!b) break;
      q++;
      if (q > f ~/ _pSize) return null;
    }
    var low = 0;
    for (var j = 0; j < filterP; j++) {
      final b = readBit();
      if (b == null) return null;
      low = low * 2 + (b ? 1 : 0);
    }
    value += q * _pSize + low;
    while (next < wanted.length && wanted[next] < value) {
      next++;
    }
    if (next < wanted.length && wanted[next] == value) return true;
  }
  return false;
}

// ---- header history ---------------------------------------------------------------
//
// A Merkle Mountain Range over every earlier block whose nodes, as in
// Zcash's ZIP 221, commit to what their subtree holds: its total work and
// its first and last timestamps and targets. So a proof also shows how much
// work the chain claims around the proven header.

/// A node of the header history: a hash and the summary it commits to.
class HistoryNode {
  const HistoryNode({
    required this.hash,
    required this.work,
    required this.firstTime,
    required this.lastTime,
    required this.firstTarget,
    required this.lastTarget,
  });

  /// The leaf for a block: its hash, its work, and its time and target at
  /// both ends.
  factory HistoryNode.leaf(BlockHeader header) => HistoryNode(
        hash: header.hash,
        work: header.work,
        firstTime: header.timestamp,
        lastTime: header.timestamp,
        firstTarget: header.target,
        lastTarget: header.target,
      );

  final Uint8List hash;
  final BigInt work;
  final int firstTime, lastTime;

  /// Targets as their 32 bytes, most significant first.
  final Uint8List firstTarget, lastTarget;

  /// `work:32 ‖ first_time:u64le ‖ last_time:u64le ‖ first_target:32 ‖
  /// last_target:32`: the 112 bytes a parent's hash covers.
  Uint8List get data => (ByteWriter()
        ..u256(work)
        ..u64(firstTime, Endian.little)
        ..u64(lastTime, Endian.little)
        ..bytes(firstTarget)
        ..bytes(lastTarget))
      .take();

  /// Whether two nodes are the same (hash and summary).
  bool sameAs(HistoryNode other) =>
      bytesEqual(hash, other.hash) &&
      work == other.work &&
      firstTime == other.firstTime &&
      lastTime == other.lastTime &&
      bytesEqual(firstTarget, other.firstTarget) &&
      bytesEqual(lastTarget, other.lastTarget);
}

/// `join(tag, L, R)`: the summaries combine (work adds, saturating), and the
/// hash is `H(tag ‖ L.hash ‖ R.hash ‖ data)`.
HistoryNode joinHistory(int tag, HistoryNode left, HistoryNode right) {
  final sum = left.work + right.work;
  final summary = HistoryNode(
    hash: _zero32,
    work: sum > u256Max ? u256Max : sum,
    firstTime: left.firstTime,
    lastTime: right.lastTime,
    firstTarget: left.firstTarget,
    lastTarget: right.lastTarget,
  );
  return HistoryNode(
    hash: sha256Bytes([tag, ...left.hash, ...right.hash, ...summary.data]),
    work: summary.work,
    firstTime: summary.firstTime,
    lastTime: summary.lastTime,
    firstTarget: summary.firstTarget,
    lastTarget: summary.lastTarget,
  );
}

/// The peaks bagged into one node: the last peak, then `join(0x02, peak,
/// acc)` for each earlier one. Its work is the total work of every block.
HistoryNode? bagPeaks(List<HistoryNode> peaks) {
  if (peaks.isEmpty) return null;
  var acc = peaks.last;
  for (var i = peaks.length - 2; i >= 0; i--) {
    acc = joinHistory(0x02, peaks[i], acc);
  }
  return acc;
}

/// `history_root` for these peaks: the bagged node's hash, or `0^32`.
Uint8List historyRootOf(List<HistoryNode> peaks) => bagPeaks(peaks)?.hash ?? _zero32;

/// The peaks of a growing MMR: enough to append leaves and compute its root.
/// Following headers with it checks each header's `history_root`.
class HistoryPeaks {
  HistoryPeaks() : _peaks = [];

  HistoryPeaks._(this._peaks, this.count);

  /// The peaks of an `n`-leaf MMR as a HeaderProof gives them (left to
  /// right), or null if their number doesn't fit `n`.
  static HistoryPeaks? fromPeaks(List<HistoryNode> peaks, int n) {
    final levels = _peakLevels(n);
    if (levels.length != peaks.length) return null;
    return HistoryPeaks._([for (var i = 0; i < peaks.length; i++) (levels[i], peaks[i])], n);
  }

  /// (level, node), largest peak first.
  final List<(int, HistoryNode)> _peaks;

  /// Leaves so far.
  int count = 0;

  HistoryPeaks copy() => HistoryPeaks._(List.of(_peaks), count);

  void push(HistoryNode leaf) {
    var level = 0;
    var node = leaf;
    while (_peaks.isNotEmpty && _peaks.last.$1 == level) {
      node = joinHistory(0x01, _peaks.removeLast().$2, node);
      level++;
    }
    _peaks.add((level, node));
    count++;
  }

  void pushHeader(BlockHeader header) => push(HistoryNode.leaf(header));

  List<HistoryNode> get nodes => [for (final p in _peaks) p.$2];

  Uint8List get root => historyRootOf(nodes);
}

/// The levels of the peaks of an `n`-leaf MMR, largest first.
List<int> _peakLevels(int n) {
  if (n <= 0) return const [];
  var top = 0, p = 1;
  while (p * 2 <= n) {
    p *= 2;
    top++;
  }
  final levels = <int>[];
  for (var level = top; level >= 0; level--) {
    if ((n ~/ p) % 2 == 1) levels.add(level);
    p ~/= 2;
  }
  return levels;
}

/// Checks that `header` is block `index` of the `n`-block history with these
/// peaks (left to right) and root `root`, given its sibling nodes inside its
/// peak, bottom first (HeaderProof).
bool verifyHistoryProof({
  required Uint8List root,
  required int n,
  required int index,
  required BlockHeader header,
  required List<HistoryNode> siblings,
  required List<HistoryNode> peaks,
}) {
  if (index < 0 || index >= n) return false;
  final levels = _peakLevels(n);
  if (peaks.length != levels.length || !bytesEqual(historyRootOf(peaks), root)) return false;
  var start = 0;
  var position = 0;
  while (index >= start + _pow2(levels[position])) {
    start += _pow2(levels[position]);
    position++;
  }
  final level = levels[position];
  if (siblings.length != level) return false;
  var node = HistoryNode.leaf(header);
  final local = index - start;
  for (var k = 0; k < level; k++) {
    node = (local ~/ _pow2(k)) % 2 == 0 ? joinHistory(0x01, node, siblings[k]) : joinHistory(0x01, siblings[k], node);
  }
  return node.sameAs(peaks[position]);
}
