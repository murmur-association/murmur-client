// Ed25519 under ZIP 215 (lib/crypto/zip215.dart, PROTOCOL.md Section 1):
// the spec's vectors, real signatures, and their edge cases.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/crypto/zip215.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/network.dart';

/// `s + L`, little-endian, in a copy of `signature`.
Uint8List _withLAdded(Uint8List signature) {
  const l = [
    0xed, 0xd3, 0xf5, 0x5c, 0x1a, 0x63, 0x12, 0x58, 0xd6, 0x9c, 0xf7, 0xa2, 0xde, 0xf9, 0xde, 0x14, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x10,
  ];
  final out = Uint8List.fromList(signature);
  var carry = 0;
  for (var i = 0; i < 32; i++) {
    final sum = out[32 + i] + l[i] + carry;
    out[32 + i] = sum & 0xff;
    carry = sum >> 8;
  }
  return out;
}

void main() {
  test('the spec\'s vectors: the identity key, in either encoding, signs anything', () {
    final identity = Uint8List(32)..[0] = 1;
    final pPlus1 = Uint8List.fromList([0xee, ...List.filled(30, 0xff), 0x7f]);
    final sig = Uint8List(64)..[0] = 1;
    for (final key in [identity, pPlus1]) {
      for (final message in [Uint8List(0), Uint8List.fromList('anything at all'.codeUnits)]) {
        expect(verifyZip215(message, sig, key), isTrue, reason: 'key ${toHex(key)}');
      }
    }
  });

  test('a real signature is valid; a changed one, another message, s + L or a key off the curve are not', () async {
    final w = await MurmurWallet.generate();
    final tx = await w.sign(
        networkTag: NetworkInfo.demo.tag, kind: TxKind.raw, nonce: 0, to: Uint8List(32), amount: 5, fee: 500000);
    final message = Uint8List.fromList([...NetworkInfo.demo.tag, ...tx.body]);
    expect(verifyZip215(message, tx.signature, tx.pubkey), isTrue);
    final changed = Uint8List.fromList(tx.signature)..[3] ^= 1;
    expect(verifyZip215(message, changed, tx.pubkey), isFalse);
    expect(verifyZip215(Uint8List.fromList([...NetworkInfo.whitepaper.tag, ...tx.body]), tx.signature, tx.pubkey),
        isFalse, reason: 'signed for another network');
    expect(verifyZip215(message, _withLAdded(tx.signature), tx.pubkey), isFalse, reason: 's must be below L');
    // y = 2 is on no point of the curve.
    expect(verifyZip215(message, tx.signature, Uint8List(32)..[0] = 2), isFalse);
    expect(verifyZip215(message, tx.signature.sublist(0, 63), tx.pubkey), isFalse);
  });

  test('every transaction of the node\'s demo chain verifies, and how long one takes', () {
    final txs = <Transaction>[];
    for (final line in File('test/vectors/demo-15.txt').readAsLinesSync()) {
      final at = line.indexOf(' = ');
      if (at < 0 || line.startsWith('#')) continue;
      final name = line.substring(0, at);
      if (!RegExp(r'^tx\d+$|^[a-z_]+\d*$').hasMatch(name)) continue;
      final value = line.substring(at + 3);
      if (value.length < 200 || !RegExp(r'^[0-9a-f]+$').hasMatch(value)) continue;
      try {
        final r = ByteReader(fromHex(value));
        txs.add(Transaction.read(r));
        r.finish();
      } on FormatException {
        // Not a transaction (a filter, a page).
      } on RangeError {
        // Likewise.
      }
    }
    expect(txs.length, greaterThanOrEqualTo(20));
    final watch = Stopwatch()..start();
    for (final tx in txs) {
      expect(verifyZip215(Uint8List.fromList([...NetworkInfo.demo.tag, ...tx.body]), tx.signature, tx.pubkey), isTrue,
          reason: tx.id);
    }
    // ignore: avoid_print
    print('${txs.length} signatures in ${watch.elapsedMilliseconds} ms');
  });
}
