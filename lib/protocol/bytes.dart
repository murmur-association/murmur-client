// Byte-level helpers: hex, SHA-256, and cursor-style readers/writers for the
// node's binary formats. Wire integers are big-endian; the signing and header
// preimages (see models.dart) use little-endian, matching the Rust core.

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

final _hexPattern = RegExp(r'^[0-9a-fA-F]*$');
final _u128Mask = (BigInt.one << 128) - BigInt.one;
const _two32 = 0x100000000;

String toHex(List<int> bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}

Uint8List fromHex(String s) {
  s = s.trim();
  if (s.length.isOdd || !_hexPattern.hasMatch(s)) {
    throw const FormatException('not a hex string');
  }
  final out = Uint8List(s.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(s.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}

/// Parses a 32-byte value (address, hash) from 64 hex chars, or null.
Uint8List? tryParseHash32(String s) {
  try {
    final b = fromHex(s);
    return b.length == 32 ? b : null;
  } on FormatException {
    return null;
  }
}

bool bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Uint8List sha256Bytes(List<int> data) =>
    Uint8List.fromList(crypto.sha256.convert(data).bytes);

/// The low 128 bits of `v`, 16 bytes. Through hex: sixteen BigInt
/// mask-and-shift steps are slow on the web, and headers carry three u128s
/// each (the target, and work and targets in their history nodes).
Uint8List _u128Bytes(BigInt v, Endian endian) {
  final hex = (v & _u128Mask).toRadixString(16).padLeft(32, '0');
  final out = fromHex(hex);
  return endian == Endian.big ? out : Uint8List.fromList(out.reversed.toList());
}

/// A big-endian unsigned integer from bytes, through hex (see _u128Bytes).
BigInt bigIntFromBytes(List<int> bytes) => bytes.isEmpty ? BigInt.zero : BigInt.parse(toHex(bytes), radix: 16);

class ByteWriter {
  final _b = BytesBuilder();
  final _scratch = ByteData(8);

  void u8(int v) => _b.addByte(v & 0xff);

  void u16(int v) {
    _scratch.setUint16(0, v);
    _b.add(_scratch.buffer.asUint8List(0, 2));
  }

  void u32(int v, [Endian endian = Endian.big]) {
    _scratch.setUint32(0, v, endian);
    _b.add(_scratch.buffer.asUint8List(0, 4));
  }

  /// Written as two u32 halves: ByteData's 64-bit accessors don't exist on
  /// the web, where ints are doubles (exact up to 2^53, plenty for amounts,
  /// heights, timestamps and nonces).
  void u64(int v, [Endian endian = Endian.big]) {
    final hi = v ~/ _two32;
    final lo = v % _two32;
    if (endian == Endian.big) {
      _scratch
        ..setUint32(0, hi)
        ..setUint32(4, lo);
    } else {
      _scratch
        ..setUint32(0, lo, Endian.little)
        ..setUint32(4, hi, Endian.little);
    }
    _b.add(_scratch.buffer.asUint8List(0, 8));
  }

  void u128(BigInt v, [Endian endian = Endian.big]) => _b.add(_u128Bytes(v, endian));

  void bytes(List<int> v) => _b.add(v);

  /// Length-prefixed (u32 BE) byte string.
  void vec(List<int> v) {
    u32(v.length);
    bytes(v);
  }

  Uint8List take() => _b.takeBytes();
}

class ByteReader {
  ByteReader(this._data) : _view = ByteData.sublistView(_data);

  final Uint8List _data;
  final ByteData _view;
  int _pos = 0;

  /// Returns a copy, so decoded values never pin a large frame buffer.
  Uint8List take(int n) {
    if (n < 0 || n > _data.length - _pos) {
      throw const FormatException('unexpected end of message');
    }
    final s = _data.sublist(_pos, _pos + n);
    _pos += n;
    return s;
  }

  void _need(int n) {
    if (n > _data.length - _pos) {
      throw const FormatException('unexpected end of message');
    }
  }

  int u8() {
    _need(1);
    return _data[_pos++];
  }

  int u16() {
    _need(2);
    final v = _view.getUint16(_pos);
    _pos += 2;
    return v;
  }

  int u32() {
    _need(4);
    final v = _view.getUint32(_pos);
    _pos += 4;
    return v;
  }

  /// See ByteWriter.u64. Values above 2^53 (only ever a peer's random
  /// Hello nonce, which the client ignores) lose precision on the web.
  int u64() {
    _need(8);
    final v = _view.getUint32(_pos) * _two32 + _view.getUint32(_pos + 4);
    _pos += 8;
    return v;
  }

  BigInt u128() => bigIntFromBytes(take(16));

  bool boolean() {
    final v = u8();
    if (v > 1) throw FormatException('invalid bool byte $v');
    return v == 1;
  }

  Uint8List hash32() => take(32);

  Uint8List vec() => take(u32());

  void finish() {
    if (_pos != _data.length) {
      throw const FormatException('trailing bytes after message');
    }
  }
}
