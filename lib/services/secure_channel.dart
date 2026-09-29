// The encrypted transport every connection uses (PROTOCOL.md Section 7.4):
//
// 1. Each side sends a fresh X25519 public key (32 bytes) and reads the
//    other's. The client always opens the connection, so it's the initiator.
// 2. okm = HKDF-SHA256(salt "murmur-transport-v1", ikm = shared secret,
//    info = initiator key ‖ responder key, 64 bytes): the first half is the
//    initiator's sending key, the second the responder's.
// 3. Each message travels as seal(length:u32be) ‖ seal(payload), sealed with
//    ChaCha20-Poly1305 under the sender's key, nonce 0^4 ‖ n:u64le, where n
//    counts the sender's seals from 0.
//
// A frame that fails to open ends the connection: someone on the path may
// have altered it.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

import '../protocol/bytes.dart';
import '../protocol/wire.dart';
import 'transport.dart';

/// A frame failed to open: altered or corrupted on the way.
class TamperedFrame implements Exception {
  @override
  String toString() => 'a frame failed its integrity check';
}

/// Both directions' keys for one connection.
class TransportKeys {
  TransportKeys(this.sending, this.receiving);

  final Uint8List sending;
  final Uint8List receiving;

  /// Derives the keys from the X25519 shared secret, as the initiator.
  static Future<TransportKeys> forInitiator({
    required List<int> sharedSecret,
    required List<int> initiatorKey,
    required List<int> responderKey,
  }) async {
    final okm = await Hkdf(hmac: Hmac.sha256(), outputLength: 64).deriveKey(
      secretKey: SecretKeyData(sharedSecret),
      nonce: utf8.encode('murmur-transport-v1'),
      info: [...initiatorKey, ...responderKey],
    );
    final bytes = Uint8List.fromList(await okm.extractBytes());
    return TransportKeys(bytes.sublist(0, 32), bytes.sublist(32, 64));
  }
}

/// Seals or opens one direction's messages, counting nonces.
class FrameCipher {
  FrameCipher(Uint8List key) : _key = SecretKeyData(key);

  final SecretKeyData _key;
  static const _aead = DartChacha20.poly1305Aead();
  int _count = 0;

  List<int> _nonce() {
    final n = Uint8List(12);
    ByteData.sublistView(n).setUint32(4, _count % 4294967296, Endian.little);
    ByteData.sublistView(n).setUint32(8, _count ~/ 4294967296, Endian.little);
    _count++;
    return n;
  }

  Uint8List seal(List<int> plain) {
    final box = _aead.encryptSync(plain, secretKey: _key, nonce: _nonce());
    return Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
  }

  Uint8List open(Uint8List sealed) {
    if (sealed.length < 16) throw TamperedFrame();
    final box = SecretBox(
      sealed.sublist(0, sealed.length - 16),
      nonce: _nonce(),
      mac: Mac(sealed.sublist(sealed.length - 16)),
    );
    try {
      return Uint8List.fromList(_aead.decryptSync(box, secretKey: _key));
    } on SecretBoxAuthenticationError {
      throw TamperedFrame();
    }
  }

  /// One message: seal(length:u32be) ‖ seal(payload).
  Uint8List sealFrame(Uint8List payload) {
    final length = (ByteWriter()..u32(payload.length)).take();
    return Uint8List.fromList([...seal(length), ...seal(payload)]);
  }
}

/// An encrypted connection over a raw [Transport]: payloads in, payloads out.
class SecureChannel {
  SecureChannel._(this._raw);

  final Transport _raw;
  final _payloads = StreamController<Uint8List>();
  late FrameCipher _sender;
  late FrameCipher _receiver;
  bool _ready = false;
  final _buffer = BytesBuilder(copy: false);
  int? _payloadLength;

  /// Decrypted payloads, in order. Errors: [TamperedFrame], or a
  /// FormatException for a length over the limit.
  Stream<Uint8List> get payloads => _payloads.stream;

  /// Runs the key exchange as the initiator. `secret` fixes the X25519 key
  /// (tests only); normally it's fresh and random for every connection.
  static Future<SecureChannel> open(Transport raw, {List<int>? secret}) async {
    final channel = SecureChannel._(raw);
    final rng = Random.secure();
    final keyPair = await X25519().newKeyPairFromSeed(secret ?? List.generate(32, (_) => rng.nextInt(256)));
    final ours = (await keyPair.extractPublicKey()).bytes;
    raw.add(Uint8List.fromList(ours));

    final theirs = Completer<Uint8List>();
    late StreamSubscription<Uint8List> sub;
    sub = raw.incoming.listen(
      (chunk) {
        if (!theirs.isCompleted) {
          channel._buffer.add(chunk);
          if (channel._buffer.length < 32) return;
          final all = channel._buffer.takeBytes();
          channel._buffer.add(Uint8List.sublistView(all, 32));
          theirs.complete(Uint8List.sublistView(all, 0, 32));
        } else if (!channel._ready) {
          // Frames can arrive while the keys are still being derived.
          channel._buffer.add(chunk);
        } else {
          channel._receive(chunk);
        }
      },
      onError: (Object e) {
        if (!theirs.isCompleted) theirs.completeError(e);
        channel._payloads.addError(e);
      },
      onDone: () {
        if (!theirs.isCompleted) theirs.completeError(const FormatException('closed during the key exchange'));
        channel._payloads.close();
      },
      cancelOnError: true,
    );
    try {
      final peerKey = await theirs.future;
      final shared = await X25519().sharedSecretKey(
        keyPair: keyPair,
        remotePublicKey: SimplePublicKey(peerKey, type: KeyPairType.x25519),
      );
      final secretBytes = await shared.extractBytes();
      if (secretBytes.every((b) => b == 0)) {
        throw const FormatException('the node sent a low-order key');
      }
      final keys = await TransportKeys.forInitiator(
        sharedSecret: secretBytes,
        initiatorKey: ours,
        responderKey: peerKey,
      );
      channel._sender = FrameCipher(keys.sending);
      channel._receiver = FrameCipher(keys.receiving);
      channel._ready = true;
    } catch (_) {
      await sub.cancel();
      rethrow;
    }
    // Bytes that came with the key, or while the keys were derived.
    channel._receive(Uint8List(0));
    return channel;
  }

  void send(Uint8List payload) => _raw.add(_sender.sealFrame(payload));

  void _receive(Uint8List chunk) {
    if (_payloads.isClosed) return;
    _buffer.add(chunk);
    try {
      while (true) {
        final need = _payloadLength == null ? 4 + 16 : _payloadLength! + 16;
        if (_buffer.length < need) return;
        final all = _buffer.takeBytes();
        final sealed = Uint8List.sublistView(all, 0, need);
        _buffer.add(Uint8List.sublistView(all, need));
        final plain = _receiver.open(Uint8List.fromList(sealed));
        if (_payloadLength == null) {
          final length = ByteData.sublistView(plain).getUint32(0);
          if (length > maxPayloadBytes) throw FormatException('a payload of $length bytes exceeds the limit');
          _payloadLength = length;
        } else {
          _payloadLength = null;
          _payloads.add(plain);
        }
      }
    } catch (e) {
      _payloads.addError(e);
      _payloads.close();
    }
  }

  void close() {
    _raw.close();
    if (!_payloads.isClosed) _payloads.close();
  }
}
