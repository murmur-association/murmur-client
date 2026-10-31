// Ed25519 verification under ZIP 215 (PROTOCOL.md Section 1), the rule
// every node applies to transactions:
// - `s` must be below the group order `L`;
// - `A` and `R` must each decode to a point on the curve, and any encoding
//   that does is accepted: a `y` of `p` or more, an `x` of 0 written as
//   negative, small-order points;
// - valid when `[8][s]B = [8]R + [8][k]A`, `k = SHA-512(R ‖ A ‖ message)`
//   as a little-endian integer modulo `L`, with `A` and `R` the bytes as
//   written.
//
// Libraries' strict checks (the `cryptography` package's among them)
// reject some of these signatures, and must not decide what is valid: the
// client would call valid blocks invalid. So the curve arithmetic is here,
// in plain Dart with BigInt: a few milliseconds a signature natively, more
// in a browser, which is why the client checks signatures in the
// background (MurmurClient._checkSignatures).

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

final _p = (BigInt.one << 255) - BigInt.from(19);
final _l = (BigInt.one << 252) + BigInt.parse('27742317777372353535851937790883648493');
final _d = (-BigInt.from(121665) * BigInt.from(121666).modInverse(_p)) % _p;
final _d2 = (_d * BigInt.two) % _p;
final _sqrtM1 = BigInt.two.modPow((_p - BigInt.one) ~/ BigInt.from(4), _p);

/// A point in extended coordinates (X:Y:Z:T), `x = X/Z`, `y = Y/Z`, `xy = T/Z`.
class _Point {
  const _Point(this.x, this.y, this.z, this.t);

  final BigInt x, y, z, t;

  static final identity = _Point(BigInt.zero, BigInt.one, BigInt.one, BigInt.zero);

  // add-2008-hwcd-3 for a = -1: complete, since d isn't a square, so small
  // and mixed-order points add like any other.
  _Point operator +(_Point o) {
    final a = ((y - x) * (o.y - o.x)) % _p;
    final b = ((y + x) * (o.y + o.x)) % _p;
    final c = (t * _d2 % _p) * o.t % _p;
    final dd = (z * BigInt.two % _p) * o.z % _p;
    final e = b - a, f = dd - c, g = dd + c, h = b + a;
    return _Point(e * f % _p, g * h % _p, f * g % _p, e * h % _p);
  }

  // dbl-2008-hwcd for a = -1.
  _Point doubled() {
    final a = x * x % _p;
    final b = y * y % _p;
    final c = BigInt.two * (z * z % _p) % _p;
    final h = -a - b;
    final xy = x + y;
    final e = (xy * xy - a - b) % _p;
    final g = b - a;
    final f = g - c;
    return _Point(e * f % _p, g * h % _p, f * g % _p, e * h % _p);
  }

  _Point negated() => _Point((-x) % _p, y, z, (-t) % _p);

  bool get isIdentity => x % _p == BigInt.zero && (y - z) % _p == BigInt.zero;
}

/// The base point.
final _base = _decode(Uint8List.fromList([0x58, ...List.filled(31, 0x66)]))!;

BigInt _littleEndian(List<int> bytes) {
  var v = BigInt.zero;
  for (var i = bytes.length - 1; i >= 0; i--) {
    v = (v << 8) | BigInt.from(bytes[i]);
  }
  return v;
}

/// The point 32 bytes encode, or null if they encode none. Any `y` below
/// 2^255 is taken modulo `p`, and the sign bit of an `x` of 0 is ignored, as
/// ZIP 215 requires.
_Point? _decode(Uint8List bytes) {
  if (bytes.length != 32) return null;
  final sign = bytes[31] >> 7;
  final y = _littleEndian([...bytes.sublist(0, 31), bytes[31] & 0x7f]) % _p;
  final yy = y * y % _p;
  final u = (yy - BigInt.one) % _p;
  final v = (_d * yy + BigInt.one) % _p;
  // x = u v^3 (u v^7)^((p-5)/8), then fixed up by sqrt(-1) if need be.
  final v3 = v * v % _p * v % _p;
  final v7 = v3 * v3 % _p * v % _p;
  var x = u * v3 % _p * (u * v7 % _p).modPow((_p - BigInt.from(5)) ~/ BigInt.from(8), _p) % _p;
  final check = v * x % _p * x % _p;
  if (check == u) {
    // x is a root.
  } else if (check == (-u) % _p) {
    x = x * _sqrtM1 % _p;
  } else {
    return null;
  }
  if (x.isOdd != (sign == 1)) x = (-x) % _p;
  return _Point(x, y, BigInt.one, x * y % _p);
}

/// `[a]P + [b]Q`, one doubling per bit for both.
_Point _twoMultiples(BigInt a, _Point p, BigInt b, _Point q) {
  final pq = p + q;
  var r = _Point.identity;
  for (var i = (a.bitLength > b.bitLength ? a.bitLength : b.bitLength) - 1; i >= 0; i--) {
    r = r.doubled();
    final ai = (a >> i).isOdd, bi = (b >> i).isOdd;
    if (ai && bi) {
      r = r + pq;
    } else if (ai) {
      r = r + p;
    } else if (bi) {
      r = r + q;
    }
  }
  return r;
}

/// Whether `signature` (64 bytes, `R ‖ s`) is valid for `message` under
/// `publicKey` (32 bytes), by ZIP 215.
bool verifyZip215(Uint8List message, Uint8List signature, Uint8List publicKey) {
  if (signature.length != 64 || publicKey.length != 32) return false;
  final rBytes = Uint8List.sublistView(signature, 0, 32);
  final s = _littleEndian(Uint8List.sublistView(signature, 32, 64));
  if (s >= _l) return false;
  final a = _decode(publicKey);
  final r = _decode(rBytes);
  if (a == null || r == null) return false;
  final k = _littleEndian(crypto.sha512.convert([...rBytes, ...publicKey, ...message]).bytes) % _l;
  // [8]([s]B - [k]A - R) is the identity.
  final p = _twoMultiples(s, _base, k, a.negated()) + r.negated();
  return p.doubled().doubled().doubled().isIdentity;
}
