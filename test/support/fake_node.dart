// A node for offline tests: the responder's side of the key exchange, a
// Hello for the demo network, and a generated demo chain served the way a
// node serves it (headers, blocks, header proofs for a checkpoint start,
// filters). Every header is valid: proof of work, retarget, median time,
// history root, and a state root that agrees with counting the chain.
// With no chain it's a node of genesis only.

import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/commitments.dart';
import 'package:murmur_client/protocol/consensus.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/protocol/wire.dart';
import 'package:murmur_client/services/chain_cache.dart';
import 'package:murmur_client/services/secure_channel.dart';

/// Empty demo blocks after genesis up to height `count`, a block every
/// target interval, mined to an address made from `miner`. With `after`, a
/// fork: its headers up to `forkAt`, then new ones (another `miner` makes
/// them differ). Fast: the demo target needs about 16 hashes a header.
List<BlockHeader> demoChain(int count, {int miner = 1, List<BlockHeader> after = const [], int forkAt = 0}) {
  const net = NetworkInfo.demo;
  final genesis = net.genesisHeader();
  final chain = <BlockHeader>[genesis, ...after.take(forkAt)];
  final history = HistoryPeaks();
  chain.forEach(history.pushHeader);
  final minerAddress = sha256Bytes([miner]);
  // Balances by miner: no transactions, so no burn pool and no fees.
  final balances = <String, int>{};
  var issued = 0;
  for (final h in chain.skip(1)) {
    balances.update(toHex(h.miner), (b) => b + net.subsidyAt(h.height), ifAbsent: () => net.subsidyAt(h.height));
    issued += net.subsidyAt(h.height);
  }
  for (var height = chain.length; height <= count; height++) {
    final from = height - 1 - net.lwmaWindow < 0 ? 0 : height - 1 - net.lwmaWindow;
    final target = nextTarget(chain.sublist(from, height), net);
    // The state after this block, as the client counts it.
    balances.update(toHex(minerAddress), (b) => b + net.subsidyAt(height), ifAbsent: () => net.subsidyAt(height));
    issued += net.subsidyAt(height);
    final state = stateRootOf({
      for (final MapEntry(:key, :value) in balances.entries)
        toHex(accountKey(fromHex(key))): Uint8List.fromList([...u64le(value), ...u64le(0)]),
      toHex(issuedKey): u64le(issued),
    });
    final prev = chain.last.hash;
    final root = history.root;
    final filterHash = sha256Bytes(buildFilter(prev, const []));
    BlockHeader header;
    for (var nonce = 0;; nonce++) {
      header = BlockHeader(
        height: height,
        prevHash: prev,
        merkleRoot: Uint8List(32),
        stateRoot: state,
        filterHash: filterHash,
        historyRoot: root,
        timestamp: net.genesisTimestamp + height * net.targetBlockSecs,
        target: target,
        nonce: nonce,
        miner: minerAddress,
      );
      if (header.meetsTarget) break;
    }
    chain.add(header);
    history.pushHeader(header);
  }
  return chain.sublist(1);
}

class FakeNode {
  FakeNode._(this.server, this.version, this.chain);

  /// Listens on `address:port` (port 0 for a free one), serving `chain`
  /// (heights 1 up; empty for genesis only).
  static Future<FakeNode> bind(InternetAddress address, int port,
      {int version = protocolVersion, List<BlockHeader> chain = const []}) async {
    final node = FakeNode._(await ServerSocket.bind(address, port), version, chain);
    node.server.listen(node._serve);
    return node;
  }

  final ServerSocket server;
  final int version;
  List<BlockHeader> chain;

  /// The first height of every non-empty Headers reply sent, in order: which
  /// stretches of the chain clients asked for.
  final headersServedFrom = <int>[];

  /// Each connected client's socket and sending cipher.
  final _sessions = <(Socket, FrameCipher)>[];

  int get port => server.port;

  Future<void> close() => server.close();

  late final Uint8List _genesis = NetworkInfo.demo.genesisHeader().hash;
  late Map<String, int> _heightOf = _index();

  /// Every block of every chain served, as a node keeps side branches.
  late final Map<String, BlockHeader> _everServed = {for (final h in chain) h.id: h};

  Map<String, int> _index() => {
        toHex(_genesis): 0,
        for (final h in chain) h.id: h.height,
      };

  /// Moves to `newChain` (a heavier fork) and announces its tip to every
  /// client, as a node does after a reorganization.
  void switchTo(List<BlockHeader> newChain) {
    chain = newChain;
    _heightOf = _index();
    for (final h in newChain) {
      _everServed[h.id] = h;
    }
    final announce = encodePayload(NewBlock(Block(chain.last, const []), 0));
    for (final (socket, sender) in _sessions) {
      socket.add(sender.sealFrame(announce));
    }
  }

  Message? _answer(Message message) {
    switch (message) {
      case GetHeaders(:final locator):
        // After the highest locator hash on this chain.
        var from = 0;
        for (final hash in locator) {
          final h = _heightOf[toHex(hash)];
          if (h != null && h > from) from = h;
        }
        final headers = chain.skip(from).take(maxHeaders).toList();
        if (headers.isNotEmpty) headersServedFrom.add(from + 1);
        return Headers(headers);
      case GetBlocks(:final hashes):
        return Blocks([
          for (final hash in hashes)
            if (_everServed[toHex(hash)] case final h?) BlockRecord(Block(h, const []), const []),
        ]);
      case GetHeaderProof(:final at, :final heights):
        final h = _heightOf[toHex(at)];
        if (h == null || h == 0) return HeaderProof(at, false, const [], const []);
        // The history `at` commits to: genesis through its parent.
        final history = HistoryPeaks()..pushHeader(NetworkInfo.demo.genesisHeader());
        for (var i = 1; i < h; i++) {
          history.pushHeader(chain[i - 1]);
        }
        return HeaderProof(at, true, history.nodes, [
          for (final x in heights)
            if (x >= 1 && x < h) (chain[x - 1], const <HistoryNode>[]),
        ]);
      case GetFilters(:final start, :final count):
        return Filters(start, [
          for (var h = start; h < start + count && h <= chain.length; h++) buildFilter(chain[h - 1].prevHash, const []),
        ]);
      case GetState(:final block):
        return State(block, false, const []);
      default:
        return null;
    }
  }

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
          _sessions.add((socket, sender));
          socket.add(sender.sealFrame(encodePayload(Hello(
            version: version,
            genesis: _genesis,
            nonce: 42,
            listenPort: 7878,
            height: chain.length,
            work: chain.fold(BigInt.zero, (sum, h) => sum + h.work),
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
          final reply = _answer(decodeMessage(plain));
          if (reply != null) socket.add(sender!.sealFrame(encodePayload(reply)));
        }
      }
    } on SocketException {
      // The client went away.
    }
    _sessions.removeWhere((s) => s.$1 == socket);
  }
}

/// A local copy in memory: headers only, as a test needs them.
class MemoryCache implements ChainCache {
  MemoryCache([List<BlockHeader>? headers]) : headers = headers ?? [];

  List<BlockHeader> headers;

  /// Every header save: (changed from, length).
  final saves = <(int, int)>[];

  @override
  Future<CachedChain?> load(String genesis) async => headers.isEmpty ? null : CachedChain(List.of(headers), {}, {});

  @override
  Future<void> saveHeaders(String genesis, List<BlockHeader> headers, int changedFrom) async {
    saves.add((changedFrom, headers.length));
    this.headers = List.of(headers);
  }

  @override
  Future<void> saveBlocks(List<Block> blocks) async {}

  @override
  Future<void> saveContents(Map<String, Uint8List> contents) async {}

  @override
  Future<void> removeContents(Set<String> hashes) async {}

  @override
  Future<void> dropBlocksAbove(int height) async {}

  @override
  Future<void> clear() async => headers = [];
}
