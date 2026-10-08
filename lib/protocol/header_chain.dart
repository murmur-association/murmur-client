// The header chain, packed. An object per header costs well over a
// thousand bytes in a browser (eight byte arrays each), several times its
// 248-byte wire encoding; a year of testnet would need about 1.5 GB. So
// headers are kept here as their wire bytes plus their 32-byte hash, 280
// bytes each, in
// one growing byte array, and rebuilt as BlockHeader objects only when asked
// for (a small cache keeps the recently used ones, such as the last 11 a
// new header's time is checked against). The fields long loops need (previous hash, miner, timestamp,
// roots) are read straight from the bytes.

import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'bytes.dart';
import 'models.dart';
import 'wire.dart';

/// Headers by index (index i holds height i + 1, as the client numbers
/// them), any of which may be unknown.
///
/// What it holds doesn't grow with the chain's age, only with the headers
/// it is given: the unknown indexes before the first header take no room (a
/// chain that starts at a checkpoint), the headers from there on are packed
/// side by side, and a header put below them (an old one, fetched on its
/// own) is kept apart.
class HeaderChain {
  static const _slot = headerBytes + 32;

  // Where fields start in the wire encoding (wire.dart, _encodeHeader).
  static const _prevAt = 8;
  static const _stateAt = 72;
  static const _filterAt = 104;
  static const _timeAt = 168;
  static const _minerAt = 216;

  /// How many headers to keep as objects: what the header rules read (the
  /// last 11) and what views show, many times over.
  static const _recentMax = 1024;

  /// The packed headers: slot 0 is index [_base].
  Uint8List _bytes = Uint8List(0);

  /// 1 where a slot holds a header.
  Uint8List _known = Uint8List(0);

  /// The first index that has a slot. Below it, [_apart].
  int _base = 0;
  int _length = 0;

  /// Headers below [_base], each as its slot's bytes.
  final _apart = <int, Uint8List>{};
  final _recent = <int, BlockHeader>{}; // in use order: a LinkedHashMap

  int get length => _length;
  bool get isEmpty => _length == 0;
  bool get isNotEmpty => _length > 0;

  /// Bytes held for headers, for measuring.
  int get bytesHeld => _bytes.length + _known.length + _apart.length * _slot;

  /// The first index whose headers are packed side by side: what [snapshot]
  /// starts at.
  int get packedFrom => _base;

  void _grow(int slots) {
    if (slots <= _known.length) return;
    final used = _length - _base;
    final capacity = max(slots, max(1024, _known.length * 2));
    _bytes = Uint8List(capacity * _slot)..setRange(0, used * _slot, _bytes);
    _known = Uint8List(capacity)..setRange(0, used, _known);
  }

  // A header just stored is likely read again soon (the next headers'
  // rules read the 11 before them), so it's kept as it is.
  void _write(int i, BlockHeader h) {
    if (i < _base) {
      _apart[i] = Uint8List(_slot)
        ..setRange(0, headerBytes, encodeHeader(h))
        ..setRange(headerBytes, _slot, h.hash);
    } else {
      final at = (i - _base) * _slot;
      _bytes
        ..setRange(at, at + headerBytes, encodeHeader(h))
        ..setRange(at + headerBytes, at + _slot, h.hash);
      _known[i - _base] = 1;
    }
    _remember(i, h);
  }

  /// The bytes that hold index `i`'s slot, and where it starts in them.
  (Uint8List, int) _where(int i) => i < _base ? (_apart[i]!, 0) : (_bytes, (i - _base) * _slot);

  void _remember(int i, BlockHeader h) {
    _recent
      ..remove(i)
      ..[i] = h;
    if (_recent.length > _recentMax) _recent.remove(_recent.keys.first);
  }

  /// Appends `h`, or an unknown slot for null.
  void add(BlockHeader? h) {
    // Unknown, with nothing packed yet: no slot is kept for it.
    if (h == null && _length == _base) {
      _base = ++_length;
      return;
    }
    _grow(_length - _base + 1);
    final i = _length++;
    if (h != null) {
      _write(i, h);
    } else {
      _known[i - _base] = 0;
      _recent.remove(i);
    }
  }

  /// Makes the next header added the one at index `i`, leaving every index
  /// before it unknown (an empty chain only).
  void startAt(int i) {
    if (_length != 0) throw StateError('the chain is not empty');
    _base = _length = i;
  }

  /// Lets go of the packed headers below index `i`: they become unknown.
  void dropBelow(int i) {
    if (i <= _base) return;
    final keepFrom = min(i, _length);
    final used = _length - keepFrom;
    final bytes = Uint8List(max(used, 1024) * _slot)
      ..setRange(0, used * _slot, Uint8List.sublistView(_bytes, (keepFrom - _base) * _slot));
    final known = Uint8List(max(used, 1024))..setRange(0, used, Uint8List.sublistView(_known, keepFrom - _base));
    _bytes = bytes;
    _known = known;
    _base = keepFrom;
    _recent.removeWhere((at, _) => at < keepFrom);
  }

  void addAll(Iterable<BlockHeader?> headers) {
    for (final h in headers) {
      add(h);
    }
  }

  /// Whether index `i` holds a header.
  bool isKnown(int i) => i >= 0 && i < _length && (i < _base ? _apart.containsKey(i) : _known[i - _base] == 1);

  /// The header at index `i`, rebuilt from its bytes (or recently used);
  /// null if that slot is unknown.
  BlockHeader? operator [](int i) {
    if (!isKnown(i)) return null;
    final h = _recent[i] ?? _decode(i);
    _remember(i, h);
    return h;
  }

  BlockHeader _decode(int i) {
    final (bytes, at) = _where(i);
    return _decodeAt(bytes, at);
  }

  static BlockHeader _decodeAt(Uint8List bytes, int at) {
    final h = decodeHeader(Uint8List.sublistView(bytes, at, at + headerBytes));
    return BlockHeader(
      height: h.height,
      prevHash: h.prevHash,
      merkleRoot: h.merkleRoot,
      stateRoot: h.stateRoot,
      filterHash: h.filterHash,
      historyRoot: h.historyRoot,
      timestamp: h.timestamp,
      target: h.target,
      nonce: h.nonce,
      miner: h.miner,
      hash: Uint8List.fromList(Uint8List.sublistView(bytes, at + headerBytes, at + _slot)),
    );
  }

  /// Puts `h` at index `i` (below the length: an old header).
  void operator []=(int i, BlockHeader h) {
    RangeError.checkValidIndex(i, this);
    _write(i, h);
  }

  /// A copy of `length` bytes at `offset` in slot `i`.
  Uint8List _field(int i, int offset, int length) {
    final (bytes, slot) = _where(i);
    return Uint8List.fromList(Uint8List.sublistView(bytes, slot + offset, slot + offset + length));
  }

  Uint8List? hashAt(int i) => isKnown(i) ? _field(i, headerBytes, 32) : null;
  Uint8List? prevHashAt(int i) => isKnown(i) ? _field(i, _prevAt, 32) : null;
  Uint8List? stateRootAt(int i) => isKnown(i) ? _field(i, _stateAt, 32) : null;
  Uint8List? filterHashAt(int i) => isKnown(i) ? _field(i, _filterAt, 32) : null;
  Uint8List? minerAt(int i) => isKnown(i) ? _field(i, _minerAt, 32) : null;

  int? timestampAt(int i) {
    if (!isKnown(i)) return null;
    // ByteReader, not getUint64: the web has no 64-bit accessors (rule 7).
    final (bytes, slot) = _where(i);
    return ByteReader(Uint8List.sublistView(bytes, slot + _timeAt, slot + _timeAt + 8)).u64();
  }

  /// Whether the miner at index `i` is `address`, without copying.
  bool minedBy(int i, Uint8List address) => _matches(i, _minerAt, address);

  /// Whether the header at index `i` has this hash, without copying.
  bool hashIs(int i, Uint8List hash) => _matches(i, headerBytes, hash);

  bool _matches(int i, int offset, Uint8List value) {
    if (!isKnown(i) || value.length != 32) return false;
    final (bytes, slot) = _where(i);
    for (var k = 0; k < 32; k++) {
      if (bytes[slot + offset + k] != value[k]) return false;
    }
    return true;
  }

  /// Drops everything from index `start` on.
  void truncate(int start) {
    if (start >= _length) return;
    _length = max(0, start);
    if (_base > _length) _base = _length;
    _apart.removeWhere((i, _) => i >= _length);
    _recent.removeWhere((i, _) => i >= _length);
  }

  /// Becomes `other`, taking its packed bytes rather than copying them, and
  /// leaves `other` empty (a chain loaded and checked apart, then adopted).
  void takeFrom(HeaderChain other) {
    _bytes = other._bytes;
    _known = other._known;
    _base = other._base;
    _length = other._length;
    _apart
      ..clear()
      ..addAll(other._apart);
    _recent
      ..clear()
      ..addAll(other._recent);
    other.clear();
  }

  void clear() {
    _bytes = Uint8List(0);
    _known = Uint8List(0);
    _base = _length = 0;
    _apart.clear();
    _recent.clear();
  }

  /// The packed headers as they are now (the first is index [packedFrom]),
  /// as a read-only list rebuilt as it's read
  /// (without filling the cache): for storing them, which reads only those
  /// that changed, across awaits. It shares the packed bytes, which growing
  /// or clearing replace rather than change, so it costs nothing and stays
  /// readable while the chain moves on. (A reorganization during a save may
  /// show it newer headers; the next save rewrites from the fork anyway.)
  /// Unknown slots can't be read.
  List<BlockHeader> snapshot() => _Snapshot(_bytes, _known, _length - _base);
}

class _Snapshot extends ListBase<BlockHeader> {
  _Snapshot(this._bytes, this._known, this.length);

  final Uint8List _bytes;
  final Uint8List _known;

  @override
  final int length;

  @override
  set length(int _) => throw UnsupportedError('read-only');

  @override
  BlockHeader operator [](int i) {
    RangeError.checkValidIndex(i, this);
    if (_known[i] != 1) throw StateError('that header is not known');
    return HeaderChain._decodeAt(_bytes, i * HeaderChain._slot);
  }

  @override
  void operator []=(int i, BlockHeader value) => throw UnsupportedError('read-only');
}
