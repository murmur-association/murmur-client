// A stand-in for a node, for what a real one can't be made to do: answer on
// another protocol version, on any address a test picks. It does only the
// responder's side of the key exchange, a Hello for the demo network, and
// an empty answer to GetHeaders (a chain of genesis only). Tests of the
// chain itself run against the real node (test_node.dart).

import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/protocol/wire.dart';
import 'package:murmur_client/services/secure_channel.dart';

class FakeNode {
  FakeNode._(this.server, this.version);

  static Future<FakeNode> bind(InternetAddress address, int port, {int version = protocolVersion}) async =>
      FakeNode._(await ServerSocket.bind(address, port), version)..server.listen((s) => FakeNode._serve(s, version));

  final ServerSocket server;
  final int version;

  int get port => server.port;

  Future<void> close() => server.close();

  static Future<void> _serve(Socket socket, int version) async {
    final keyPair = await X25519().newKeyPair();
    final ours = (await keyPair.extractPublicKey()).bytes;
    socket.add(ours);
    final buffer = BytesBuilder();
    TransportKeys? keys;
    FrameCipher? reader, sender;
    int? payloadLength;
    try {
      await for (final chunk in socket) {
        buffer.add(chunk);
        if (keys == null) {
          if (buffer.length < 32) continue;
          final all = buffer.takeBytes();
          final theirs = all.sublist(0, 32);
          buffer.add(all.sublist(32));
          final shared = await X25519()
              .sharedSecretKey(keyPair: keyPair, remotePublicKey: SimplePublicKey(theirs, type: KeyPairType.x25519));
          keys = await TransportKeys.forInitiator(
              sharedSecret: await shared.extractBytes(), initiatorKey: theirs, responderKey: ours);
          reader = FrameCipher(keys.sending);
          sender = FrameCipher(keys.receiving);
          socket.add(sender.sealFrame(encodePayload(Hello(
            version: version,
            genesis: NetworkInfo.demo.genesisHeader().hash,
            nonce: 42,
            listenPort: 7878,
            height: 0,
            work: BigInt.zero,
          ))));
        }
        while (true) {
          final need = payloadLength == null ? 20 : payloadLength + 16;
          if (buffer.length < need) break;
          final all = buffer.takeBytes();
          buffer.add(all.sublist(need));
          final plain = reader!.open(Uint8List.fromList(all.sublist(0, need)));
          if (payloadLength == null) {
            payloadLength = ByteData.sublistView(plain).getUint32(0);
            continue;
          }
          payloadLength = null;
          if (decodeMessage(plain) is GetHeaders) socket.add(sender!.sealFrame(encodePayload(const Headers([]))));
        }
      }
    } on SocketException {
      // The client went away.
    }
  }
}
