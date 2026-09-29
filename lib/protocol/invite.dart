// Invitations: a small wallet someone funds and hands over as a code (a
// printed card with a QR code, or a link), so a newcomer can join without
// buying anything. Claiming moves everything on the card to the newcomer's
// own wallet in one transfer, its fee paid from the card.
//
// A card has no expiry: the chain has no time locks, so any date would only
// be a promise apps could ignore. It stays valid until it's claimed, or
// until the inviter (who keeps its key) cancels it by taking the tokens back.
//
// A code is, in Crockford's base32 (no I, L, O or U; typing mistakes like
// O for 0 are forgiven):
//
//   version:1 ‖ network:4 ‖ seed:32 ‖ check:4
//
// - network: the first 4 bytes of the network's genesis hash, so a card
//   can't be claimed on the wrong network;
// - seed: the card's Ed25519 key (as `murmur-node keygen` writes them);
// - check: the first 4 bytes of SHA-256 over everything before it.
//
// Version 1 codes also carried an expiry day after the network (2 bytes);
// they're still read, and the day is ignored.
//
// A card is a bearer token: whoever claims it first gets it.

import 'dart:typed_data';

import 'bytes.dart';

const inviteVersion = 2;
const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// What an invitation code holds.
class Invite {
  const Invite({required this.network, required this.seed});

  /// The first 4 bytes of the network's genesis hash.
  final Uint8List network;

  /// The card's wallet seed.
  final Uint8List seed;

  /// Whether the card is for the network with this genesis hash.
  bool isFor(Uint8List genesis) => bytesEqual(network, genesis.sublist(0, 4));

  /// The code, in groups of five for typing.
  String get code {
    final body = Uint8List(1 + 4 + 32)
      ..[0] = inviteVersion
      ..setRange(1, 5, network)
      ..setRange(5, 37, seed);
    return _encode([...body, ...sha256Bytes(body).sublist(0, 4)]);
  }

  /// Reads a code (spaces, dashes and case don't matter) or a link ending
  /// in one; null if it isn't a valid invitation.
  static Invite? parse(String text) {
    var s = text.trim();
    final slash = s.lastIndexOf('/');
    if (slash >= 0) s = s.substring(slash + 1);
    final bytes = _decode(s);
    if (bytes == null || bytes.length < 5) return null;
    final body = bytes.sublist(0, bytes.length - 4);
    if (!bytesEqual(sha256Bytes(body).sublist(0, 4), bytes.sublist(bytes.length - 4))) return null;
    // Where the key starts: after the network, and in version 1 after the
    // expiry day too.
    final seedAt = switch ((body[0], body.length)) {
      (2, 37) => 5,
      (1, 39) => 7,
      _ => null,
    };
    if (seedAt == null) return null;
    return Invite(
      network: Uint8List.fromList(body.sublist(1, 5)),
      seed: Uint8List.fromList(body.sublist(seedAt, seedAt + 32)),
    );
  }

  static String _encode(List<int> bytes) {
    final out = StringBuffer();
    var buffer = 0, bits = 0, written = 0;
    void put(int v) {
      if (written > 0 && written % 5 == 0) out.write('-');
      out.write(_alphabet[v]);
      written++;
    }

    for (final b in bytes) {
      buffer = (buffer * 256 + b) % 65536; // at most 12 bits are pending: no overflow, no 32-bit shifts
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        put((buffer ~/ (1 << bits)) % 32);
      }
    }
    if (bits > 0) put((buffer * (1 << (5 - bits))) % 32);
    return out.toString();
  }

  static List<int>? _decode(String text) {
    final out = <int>[];
    var buffer = 0, bits = 0;
    for (final ch in text.toUpperCase().split('')) {
      if (ch == '-' || ch == ' ') continue;
      final c = switch (ch) { 'O' => '0', 'I' || 'L' => '1', _ => ch };
      final v = _alphabet.indexOf(c);
      if (v < 0) return null;
      buffer = (buffer * 32 + v) % 8192;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        out.add((buffer ~/ (1 << bits)) % 256);
      }
    }
    return out;
  }
}
