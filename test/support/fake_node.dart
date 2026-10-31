// A stand-in for a node, for what a real one can't be made to do: answer on
// another protocol version, on any address a test picks, serve a chain that
// breaks the rules, or relay forged transactions. It does only the
// responder's side of the key exchange, a Hello for the demo network, the
// headers and blocks of `chain` (none by default: a chain of genesis only),
// and once the client's Hello is in, the `relay` messages. Tests of the
// chain itself run against the real node (test_node.dart).

import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/protocol/wire.dart';
import 'package:murmur_client/services/secure_channel.dart';

class FakeNode {
  FakeNode._(this.server, this.version, this.chain, this.relay);

  static Future<FakeNode> bind(InternetAddress address, int port,
      {int version = protocolVersion, List<Block> chain = const [], List<Message> relay = const []}) async {
    final node = FakeNode._(await ServerSocket.bind(address, port), version, chain, relay);
    node.server.listen(node._serve);
    return node;
  }

  final ServerSocket server;
  final int version;

  /// The blocks after genesis, in order.
  final List<Block> chain;

  /// Sent once the client's Hello is in.
  final List<Message> relay;

  int get port => server.port;

  Future<void> close() => server.close();

  /// What it answers `request` with, if anything.
  Message? _answer(Message request) => switch (request) {
        // From genesis: the whole chain; from a known tip, nothing new.
        GetHeaders(:final locator) =>
          Headers(locator.isNotEmpty && bytesEqual(locator.first, NetworkInfo.demo.genesisHeader().hash)
              ? [for (final b in chain) b.header]
              : const []),
        GetBlocks(:final hashes) => Blocks([
            for (final h in hashes)
              for (final b in chain)
                if (bytesEqual(b.header.hash, h)) BlockRecord(b, const []),
          ]),
        GetContent() => const Content([]),
        _ => null,
      };

  Future<void> _serve(Socket socket) async {
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
            nonce: u64Bytes(42),
            listenPort: 7878,
            height: chain.length,
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
          final message = decodeMessage(plain);
          if (message is Hello) {
            for (final m in relay) {
              socket.add(sender!.sealFrame(encodePayload(m)));
            }
          }
          final answer = _answer(message);
          if (answer != null) socket.add(sender!.sealFrame(encodePayload(answer)));
        }
      }
    } on SocketException {
      // The client went away.
    }
  }
}
