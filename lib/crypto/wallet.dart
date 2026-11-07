// A Murmur wallet: an Ed25519 key (RFC 8032) whose address is SHA-256 of
// the public key. The 32-byte seed is the same format as a key file made
// with `murmur-node keygen` (64 hex chars).

import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart' show DartEd25519;

import '../protocol/bytes.dart';
import '../protocol/models.dart';

/// A wallet's public side: its address and public key. What the app keeps
/// at hand; the key itself is decrypted only to sign (services/key_vault.dart).
class WalletId {
  const WalletId(this.address, this.publicKey);

  final Uint8List address;
  final Uint8List publicKey;

  String get addressHex => toHex(address);
}

class MurmurWallet {
  MurmurWallet._(this.seed, this.publicKey, this._keyPair)
      : address = sha256Bytes(publicKey);

  /// The signer on every platform: the package's own Dart Ed25519, never the
  /// browser's. `Ed25519()` signs with the browser's Web Crypto where there
  /// is one, and a transaction's signature is part of its one encoding
  /// (rule 6): it must be RFC 8032's on every flavour, as the node's vectors
  /// expect. In Safari the browser's signatures were never mined
  /// (2026-11-05, the acceptance tests' first Safari runs).
  static final Ed25519 signer = DartEd25519();

  final Uint8List seed;
  final Uint8List publicKey;
  final Uint8List address;
  final SimpleKeyPair _keyPair;

  String get addressHex => toHex(address);
  String get seedHex => toHex(seed);

  WalletId get id => WalletId(address, publicKey);

  static Future<MurmurWallet> fromSeed(Uint8List seed) async {
    if (seed.length != 32) {
      throw const FormatException('a wallet seed is 32 bytes (64 hex chars)');
    }
    final kp = await signer.newKeyPairFromSeed(seed);
    final pk = await kp.extractPublicKey();
    return MurmurWallet._(Uint8List.fromList(seed), Uint8List.fromList(pk.bytes), kp);
  }

  static Future<MurmurWallet> generate() {
    final rng = Random.secure();
    return fromSeed(Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256))));
  }

  /// Signs a transaction with the sender's next `nonce`: the nonce proven
  /// in the state, plus its own pending transactions (PROTOCOL.md Section 5).
  /// `networkTag` is the tag of the network it is for (`NetworkInfo.tag`):
  /// the signature covers it, so the transaction is valid nowhere else.
  Future<Transaction> sign({
    required Uint8List networkTag,
    required TxKind kind,
    required int nonce,
    required int fee,
    int amount = 0,
    Uint8List? to,
    Uint8List? messageHash,
    int contentSize = 0,
    Uint8List? reference,
    Uint8List? thread,
    Uint8List? answers,
    List<Uint8List> mentions = const [],
  }) async {
    final body = Transaction.bodyFor(
      kind: kind,
      pubkey: publicKey,
      nonce: nonce,
      fee: fee,
      amount: amount,
      to: to,
      messageHash: messageHash,
      contentSize: contentSize,
      reference: reference,
      thread: thread,
      answers: answers,
      mentions: mentions,
    );
    final sig = await signer.sign([...networkTag, ...body], keyPair: _keyPair);
    return Transaction(
      kind: kind,
      pubkey: publicKey,
      nonce: nonce,
      fee: fee,
      amount: amount,
      to: to,
      messageHash: messageHash,
      contentSize: contentSize,
      reference: reference,
      thread: thread,
      answers: answers,
      mentions: mentions,
      signature: Uint8List.fromList(sig.bytes),
    );
  }
}
