import 'dart:async';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/commitments.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/protocol/wire.dart';
import 'package:murmur_client/services/fees.dart';
import 'package:murmur_client/services/secure_channel.dart';
import 'package:murmur_client/services/transport.dart';

Uint8List _filled(int byte, [int n = 32]) => Uint8List(n)..fillRange(0, n, byte);

Uint8List _u32le(int i) => (ByteWriter()..u32(i, Endian.little)).take();

/// A transport the test plays the node's side of.
class _FakeTransport implements Transport {
  final fromNode = StreamController<Uint8List>();
  final toNode = <Uint8List>[];
  final sent = StreamController<Uint8List>.broadcast();

  @override
  Stream<Uint8List> get incoming => fromNode.stream;

  @override
  void add(Uint8List bytes) {
    toNode.add(bytes);
    sent.add(bytes);
  }

  @override
  void close() => fromNode.close();

  @override
  String get peer => 'test';
}

void main() {
  test('wallet derives keys and signatures per RFC 8032', () async {
    // RFC 8032 Section 7.1, TEST 1.
    final w = await MurmurWallet.fromSeed(
        fromHex('9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60'));
    expect(toHex(w.publicKey), 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a');
    expect(w.address, sha256Bytes(w.publicKey));
  });

  test('a reply signs its network and its nonce, and survives the wire', () async {
    final w = await MurmurWallet.generate();
    final content = saltedContent('hello murmur'.codeUnits);
    final thread = sha256Bytes([9]);
    final tag = NetworkInfo.demo.tag;
    Future<Transaction> reply(int nonce) => w.sign(
          networkTag: tag,
          kind: TxKind.reply,
          nonce: nonce,
          amount: 2000000,
          fee: 1000000,
          messageHash: sha256Bytes(content),
          contentSize: content.length,
          reference: thread,
        );
    final tx = await reply(5);
    Future<bool> signedFor(List<int> networkTag) => Ed25519().verify(
          [...networkTag, ...tx.body],
          signature: Signature(tx.signature, publicKey: SimplePublicKey(tx.pubkey, type: KeyPairType.ed25519)),
        );
    expect(await signedFor(tag), isTrue);
    expect(await signedFor(NetworkInfo.whitepaper.tag), isFalse, reason: 'valid on no other network');
    // The nonce comes right after the kind and the key, in one byte here.
    expect(tx.body[33], 5);
    expect((await reply(6)).id, isNot(tx.id), reason: 'another nonce, another transaction');
    expect(tx.weight, tx.bytes.length + content.length);
    expect(tx.weight, lessThanOrEqualTo(txWeight(content.length)));
    expect(tx.isContent(content), isTrue);
    expect(tx.to, isNull, reason: 'a reply names no recipient: the chain pays its thread\'s author');

    final msg = decodeMessage(encodePayload(NewTx(tx, content))) as NewTx;
    expect(msg.tx.id, tx.id);
    expect((msg.tx.nonce, msg.tx.amount, msg.tx.contentSize, msg.tx.referenceId),
        (5, 2000000, content.length, toHex(thread)));
    expect(msg.content, content);
  });

  test('content is a fresh 16-byte salt plus the message, and only the message is shown', () {
    final message = 'yes'.codeUnits;
    final a = saltedContent(message), b = saltedContent(message);
    expect(a.length, saltLength + message.length);
    expect(messageOf(a), message);
    expect(sha256Bytes(a), isNot(sha256Bytes(b)), reason: 'identical messages get different hashes');
    expect(messageOf(Uint8List(saltLength)), isEmpty);
    expect(maxContentSize, 1040);
  });

  test('compact block relay messages have the node layout (Section 7.9)', () async {
    // The vectors of NODE-PROTOCOL-10.md: SendCompact, and GetBlockTxs for
    // block 08 x 32, indexes 0 and 4096.
    expect(encodePayload(const SendCompact()), [0x18]);
    expect(decodeMessage(Uint8List.fromList([0x18])), isA<SendCompact>());
    final get = encodePayload(GetBlockTxs(_filled(8), const [0, 4096]));
    expect(toHex(get), '1a${'08' * 32}000000020000000000001000');
    final got = decodeMessage(get) as GetBlockTxs;
    expect(toHex(got.block), '08' * 32);
    expect(got.indexes, [0, 4096]);

    // CompactBlock: header, found_ms, short ids (the first 8 bytes of txids).
    final header = NetworkInfo.demo.genesisHeader();
    final compact =
        decodeMessage(encodePayload(CompactBlock(header, 1790208000123, [_filled(1, 8), _filled(2, 8)]))) as CompactBlock;
    expect((compact.header.id, compact.foundMs), (header.id, 1790208000123));
    expect(compact.shortIds.map(toHex), ['01' * 8, '02' * 8]);

    // BlockTxs: transactions as everywhere else.
    final w = await MurmurWallet.generate();
    final tx = await w.sign(
        networkTag: NetworkInfo.demo.tag, kind: TxKind.raw, nonce: 0, to: _filled(7), amount: 5000000, fee: 500000);
    final txs = decodeMessage(encodePayload(BlockTxs(_filled(9), [tx]))) as BlockTxs;
    expect((toHex(txs.block), txs.txs.single.id), ('09' * 32, tx.id));

    // Over the limit is malformed, like every other count.
    final tooMany = Uint8List.fromList([0x1a, ..._filled(8), 0, 0, 0x3e, 0x81]); // 16,001
    expect(() => decodeMessage(tooMany), throwsFormatException);
  });

  test('messages have the node layout', () async {
    final hello = encodePayload(Hello(
      version: protocolVersion,
      genesis: Uint8List(32),
      nonce: u64Bytes(1),
      listenPort: 0,
      height: 0,
      work: BigInt.zero,
    ));
    // tag(1) version(4) genesis(32) nonce(8) port(2) height(8) work(32)
    expect(hello.length, 87);
    expect(hello.sublist(0, 5), [0, 0, 0, 0, 14]);

    final w = await MurmurWallet.generate();
    final flag = await w.sign(
        networkTag: NetworkInfo.demo.tag, kind: TxKind.flag, nonce: 0, fee: 500000, reference: _filled(3));
    final submit = encodePayload(SubmitTx(flag, null));
    expect(submit[0], 16);
    expect((decodeMessage(submit) as SubmitTx).tx.id, flag.id);

    expect(encodePayload(const GetFees()), [12]);
    expect(encodePayload(const GetFilters(7, 3)), [20, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 3]);
    final getState = encodePayload(GetState(_filled(1), [_filled(2)]));
    expect((getState[0], getState.length), (18, 1 + 32 + 4 + 32));

    // Replies the client decodes.
    final fees = decodeMessage(encodePayload(const Fees(
            nextBlock: (fee: 10, weight: 1088), pending: 1200, recentLowest: 1, recentMedian: 2)))
        as Fees;
    expect((fees.nextBlock, fees.poolEntry, fees.pending, fees.recentLowest), ((fee: 10, weight: 1088), null, 1200, 1));
    final status = decodeMessage(encodePayload(TxStatus(flag.hash, TxStatusCode.refused, 'no balance'))) as TxStatus;
    expect((status.code, status.reason), (TxStatusCode.refused, 'no balance'));
    expect(() => decodeMessage(Uint8List.fromList([17, ...flag.hash, 4, 0, 0, 0, 0])), throwsFormatException,
        reason: 'unknown status byte');
    final txReply = decodeMessage(encodePayload(Tx([
      (flag.hash, TxOnChain(flag, _filled(4), 12, 1, [_filled(5)])),
      (_filled(6), const TxUnknown()),
    ]))) as Tx;
    final onChain = txReply.entries.first.$2 as TxOnChain;
    expect((onChain.tx.id, onChain.height, onChain.index, onChain.branch.length), (flag.id, 12, 1, 1));
    expect(txReply.entries.last.$2, isA<TxUnknown>());
  });

  test('a merkle branch leads a txid to its block root', () {
    final leaves = [for (var i = 0; i < 5; i++) sha256Bytes([i])];
    final root = merkleRoot(leaves);
    // Leaf 4 of 5: its sibling is itself (odd level), then the pair above.
    final l01 = sha256Bytes([...leaves[0], ...leaves[1]]);
    final l23 = sha256Bytes([...leaves[2], ...leaves[3]]);
    final l44 = sha256Bytes([...leaves[4], ...leaves[4]]);
    final left = sha256Bytes([...l01, ...l23]);
    expect(merkleRootFromBranch(leaves[4], 4, [leaves[4], l44, left]), root);
    expect(merkleRootFromBranch(leaves[2], 2, [leaves[3], l01, sha256Bytes([...l44, ...l44])]), root);
    expect(merkleRootFromBranch(leaves[2], 3, [leaves[3], l01, sha256Bytes([...l44, ...l44])]), isNot(root));
  });

  group('commitments (PROTOCOL.md Section 3.6 test vectors)', () {
    test('state tree root, and proofs of values and of absence', () {
      final entries = {
        for (var i = 0; i < 4; i++) toHex(sha256Bytes(_u32le(i))): Uint8List.fromList([i]),
      };
      expect(toHex(stateRootOf(entries)), '312aa0b64817314d3808c4830ce8d6b0fe54547f8b1e029099e3790ad820734b');
      expect(stateRootOf({}), Uint8List(32), reason: 'the empty tree');

      // Proofs built from the definition: a single entry is its leaf hash.
      final key = sha256Bytes(_u32le(0));
      final alone = stateRootOf({toHex(key): Uint8List.fromList([0])});
      expect(verifyStateProof(alone, key, StateProof([], ValueTerminal(Uint8List.fromList([0]))))?.value, [0]);
      expect(verifyStateProof(alone, key, StateProof([], ValueTerminal(Uint8List.fromList([1])))), isNull,
          reason: 'a different value');
      final other = sha256Bytes(_u32le(99));
      // `other` isn't in the tree; the lone entry sits where it would be.
      final absent = verifyStateProof(alone, other, StateProof([], OtherTerminal(key, sha256Bytes([0]))));
      expect(absent, isNotNull);
      expect(absent!.value, isNull);
      expect(verifyStateProof(Uint8List(32), other, const StateProof([], EmptyTerminal())), isNotNull);
      expect(verifyStateProof(alone, key, const StateProof([], EmptyTerminal())), isNull,
          reason: 'a present key claimed absent');
    });

    test('state proofs against a larger tree, one level down', () {
      // Two entries whose keys differ in the first bit: each is a leaf at depth 1.
      Uint8List keyWith(int first) => Uint8List(32)..[0] = first;
      final a = keyWith(0x00), b = keyWith(0x80);
      final root = stateRootOf({toHex(a): Uint8List.fromList([1]), toHex(b): Uint8List.fromList([2])});
      final leafA = stateLeafHash(a, sha256Bytes([1]));
      final leafB = stateLeafHash(b, sha256Bytes([2]));
      expect(verifyStateProof(root, a, StateProof([leafB], ValueTerminal(Uint8List.fromList([1]))))?.value, [1]);
      expect(verifyStateProof(root, b, StateProof([leafA], ValueTerminal(Uint8List.fromList([2]))))?.value, [2]);
      expect(verifyStateProof(root, a, StateProof([leafA], ValueTerminal(Uint8List.fromList([1])))), isNull,
          reason: 'wrong sibling');
    });

    test('block filter bytes, matches and false positives', () {
      final prev = _filled(7);
      final items = [_filled(1), _filled(2), _filled(3)];
      final filter = buildFilter(prev, items);
      expect(toHex(filter), '000000030101b1073186d9c0');
      for (final item in items) {
        expect(filterMatchesAny(filter, prev, [item]), isTrue);
      }
      expect(filterMatchesAny(filter, prev, [_filled(4)]), isFalse);
      expect(buildFilter(prev, []), [0, 0, 0, 0], reason: 'an empty block');
      expect(filterMatchesAny(Uint8List.fromList([0, 0, 0, 2]), prev, [_filled(1)]), isNull, reason: 'no bits');
      expect(sha256Bytes(buildFilter(prev, [])), NetworkInfo.demo.genesisHeader().filterHash);
    });

    test('header history root (ZIP 221 nodes) and proofs', () {
      final headers = [
        for (var i = 0; i < 11; i++)
          BlockHeader(
            height: i,
            prevHash: _filled(i),
            merkleRoot: Uint8List(32),
            stateRoot: Uint8List(32),
            filterHash: Uint8List(32),
            historyRoot: Uint8List(32),
            timestamp: 1000 + 30 * i,
            target: u256Bytes(u256Max >> (8 + i % 3)),
            nonce: u64Bytes(i),
            miner: Uint8List(32),
          ),
      ];
      final peaks = HistoryPeaks();
      headers.forEach(peaks.pushHeader);
      expect(toHex(peaks.root), '1e98e56fd83ec8c8927893a9e2ad7237368ba9ee2bc5c81854b6545cc82e6826');
      expect(HistoryPeaks().root, Uint8List(32));
      // The bagged node sums every block's work and spans their times.
      final bagged = bagPeaks(peaks.nodes)!;
      expect(bagged.work, headers.fold<BigInt>(BigInt.zero, (sum, h) => sum + blockWork(h.target)));
      expect((bagged.firstTime, bagged.lastTime), (1000, 1300));

      // 11 leaves: peaks of 8, 2 and 1. Prove header 9 (in the peak of 2)
      // and header 1 (in the peak of 8).
      HistoryNode leaf(int i) => HistoryNode.leaf(headers[i]);
      HistoryNode join(HistoryNode l, HistoryNode r) => joinHistory(0x01, l, r);
      final nodes = peaks.nodes;
      expect(
        verifyHistoryProof(root: peaks.root, n: 11, index: 9, header: headers[9], siblings: [leaf(8)], peaks: nodes),
        isTrue,
      );
      final right4 = join(join(leaf(4), leaf(5)), join(leaf(6), leaf(7)));
      expect(
        verifyHistoryProof(
            root: peaks.root,
            n: 11,
            index: 1,
            header: headers[1],
            siblings: [leaf(0), join(leaf(2), leaf(3)), right4],
            peaks: nodes),
        isTrue,
      );
      expect(
        verifyHistoryProof(root: peaks.root, n: 11, index: 9, header: headers[8], siblings: [leaf(8)], peaks: nodes),
        isFalse,
      );
      expect(
        verifyHistoryProof(root: peaks.root, n: 11, index: 10, header: headers[10], siblings: [], peaks: nodes),
        isTrue,
      );
      // Peaks from a HeaderProof rebuild the same history.
      final rebuilt = HistoryPeaks.fromPeaks(nodes, 11)!..pushHeader(headers[0]);
      final direct = peaks.copy()..pushHeader(headers[0]);
      expect(rebuilt.root, direct.root);
      expect(HistoryPeaks.fromPeaks(nodes, 12), isNull, reason: '12 leaves have two peaks, not three');
    });
  });

  group('encrypted transport (PROTOCOL.md Section 7.4)', () {
    test('matches the test vector', () async {
      final initiator = await X25519().newKeyPairFromSeed(_filled(1));
      final responder = await X25519().newKeyPairFromSeed(_filled(2));
      final iPub = (await initiator.extractPublicKey()).bytes;
      final rPub = (await responder.extractPublicKey()).bytes;
      expect(toHex(iPub), 'a4e09292b651c278b9772c569f5fa9bb13d906b46ab68c9df9dc2b4409f8a209');
      expect(toHex(rPub), 'ce8d3ad1ccb633ec7b70c17814a5c76ecd029685050d344745ba05870e587d59');
      final shared = await X25519().sharedSecretKey(
          keyPair: initiator, remotePublicKey: SimplePublicKey(rPub, type: KeyPairType.x25519));
      final keys =
          await TransportKeys.forInitiator(sharedSecret: await shared.extractBytes(), initiatorKey: iPub, responderKey: rPub);
      final ping = FrameCipher(keys.sending).sealFrame(encodePayload(const Ping()));
      expect(toHex(ping), '12b1d29b5e344c49576d62fc3db2c83d8e57a45a134536830881c63c69ad8a99694042e5f1');
      // The responder opens it with the initiator's sending key.
      final reader = FrameCipher(keys.sending);
      expect(reader.open(ping.sublist(0, 20)), [0, 0, 0, 1]);
      expect(reader.open(ping.sublist(20)), [7]);
      final tampered = Uint8List.fromList(ping)..[25] ^= 1;
      final again = FrameCipher(keys.sending)..open(tampered.sublist(0, 20));
      expect(() => again.open(tampered.sublist(20)), throwsA(isA<TamperedFrame>()));
    });

    test('a channel exchanges payloads with a node, whatever the chunking', () async {
      final raw = _FakeTransport();
      // The node's side: its key, then (once the client's key is in) frames.
      final nodeKeys = await X25519().newKeyPairFromSeed(_filled(2));
      final nodePub = (await nodeKeys.extractPublicKey()).bytes;
      final clientKey = raw.sent.stream.first;
      final channelFuture = SecureChannel.open(raw, secret: _filled(1));
      final clientPub = await clientKey;
      final shared = await X25519().sharedSecretKey(
          keyPair: nodeKeys, remotePublicKey: SimplePublicKey(clientPub, type: KeyPairType.x25519));
      final keys = await TransportKeys.forInitiator(
          sharedSecret: await shared.extractBytes(), initiatorKey: clientPub, responderKey: nodePub);
      final nodeSender = FrameCipher(keys.receiving);
      // The key and two frames in one stream, cut into 7-byte pieces.
      final stream = [
        ...nodePub,
        ...nodeSender.sealFrame(encodePayload(const Ping())),
        ...nodeSender.sealFrame(encodePayload(const GetFees())),
      ];
      for (var i = 0; i < stream.length; i += 7) {
        raw.fromNode.add(Uint8List.fromList(stream.sublist(i, i + 7 > stream.length ? stream.length : i + 7)));
      }
      final channel = await channelFuture;
      final payloads = await channel.payloads.take(2).toList();
      expect(payloads, [
        [7],
        [12],
      ]);
      // And the node reads what the client sends.
      channel.send(encodePayload(const Ping()));
      final nodeReader = FrameCipher(keys.sending);
      final frame = raw.toNode.last;
      expect(nodeReader.open(frame.sublist(0, 20)), [0, 0, 0, 1]);
      expect(nodeReader.open(frame.sublist(20)), [7]);
    });
  });

  test('headers and blocks survive their storage encoding', () async {
    final w = await MurmurWallet.generate();
    final content = saltedContent('stored'.codeUnits);
    final tx = await w.sign(
      networkTag: NetworkInfo.demo.tag,
      kind: TxKind.orphan,
      nonce: 0,
      fee: 500000,
      messageHash: sha256Bytes(content),
      contentSize: content.length,
    );
    final genesis = NetworkInfo.demo.genesisHeader();
    final block = Block(
      BlockHeader(
        height: 1,
        prevHash: genesis.hash,
        merkleRoot: merkleRoot([tx.hash]),
        stateRoot: _filled(8),
        filterHash: Uint8List(32),
        historyRoot: genesis.hash,
        timestamp: 1790208002,
        target: genesis.target,
        nonce: u64Bytes(42),
        miner: w.address,
      ),
      [tx],
    );
    final header = block.header;
    expect(encodeHeader(header).length, headerBytes);
    expect(headerBytes, 248);
    expect(decodeHeader(encodeHeader(header)).id, header.id);
    final back = decodeBlock(encodeBlock(block));
    expect((back.header.id, back.transactions.single.id), (header.id, tx.id));
    expect(() => decodeHeader(Uint8List(headerBytes + 1)), throwsFormatException, reason: 'trailing bytes');
    // The filter of a one-transaction block holds its sender only.
    expect(blockFilterItems(block.transactions).map(toHex), [w.addressHex]);
  });

  test('fees from the node beat its bars per byte, and never go below the minimum', () {
    final info = feeInfoFromNode(const Fees(nextBlock: (fee: 6000000, weight: 1088), pending: 1200));
    expect(info.source, FeeSource.node);
    expect((info.suggested(1088), info.suggested(264), info.congested), (6000001, 1455883, true));
    // A bar a small transaction beats with less than the minimum.
    expect(feeInfoFromNode(const Fees(nextBlock: (fee: 600000, weight: 1088), pending: 9)).suggested(196), minFee);
    final quiet = feeInfoFromNode(const Fees(pending: 0));
    expect((quiet.suggested(264), quiet.congested), (minFee, false));
    expect(minFee, NetworkInfo.whitepaper.minFee);
    expect(minFee, NetworkInfo.demo.minFee);
  });

  test('local fee estimate follows the node rules per byte', () {
    // Same case as mempool.rs `next_block_fee_reflects_congestion`, in
    // tokens: fees 1, 4, 7 pending at one weight, with room for two.
    const w = 269, t = unitsPerToken;
    final busy =
        estimateFees(pending: [(t, w), (4 * t, w), (7 * t, w)], maxBlockBytes: 2 * w, recentBlockMins: [3 * t, t, 2 * t]);
    expect((busy.nextBlockFee(w), busy.poolEntryFee(w), busy.suggested(w)), (4 * t + 1, minFee, 4 * t + 1));
    expect(busy.nextBlockFee(2 * w), 8 * t + 1, reason: 'twice the weight needs twice the fee');
    expect((busy.recentLowest, busy.recentMedian), (t, 2 * t));

    final quiet = estimateFees(pending: [(t, w), (4 * t, w), (7 * t, w)], maxBlockBytes: 10 * w, recentBlockMins: []);
    expect((quiet.suggested(w), quiet.congested, quiet.recentLowest, quiet.source), (minFee, false, null, FeeSource.local));

    final full = estimateFees(
        pending: [for (var i = 0; i < mempoolCapacity; i++) ((2 + i % 3) * t, 264)],
        maxBlockBytes: 1000000 * 264,
        recentBlockMins: []);
    expect(full.poolEntryFee(264), 2 * t + 1, reason: 'must beat the cheapest (2 for 264 bytes) in a full pool');
  });

  test('orphans burn 10x the fee, paid back as ceil(pool / K) per block', () {
    expect(orphanBurn(3 * unitsPerToken), 30 * unitsPerToken);
    const demo = NetworkInfo.demo; // K = 100
    expect(demo.burnPayoutBlocks, 100);
    expect(demo.burnPayout(0), 0);
    expect(demo.burnPayout(1), 1, reason: 'rounds up, so a small pool still drains');
    expect(demo.burnPayout(101), 2);
    var pool = 110, paid = 0, blocks = 0;
    while (pool > 0) {
      final p = demo.burnPayout(pool);
      pool -= p;
      paid += p;
      blocks++;
    }
    expect((paid, blocks), (110, 105));
    expect(NetworkInfo.whitepaper.burnPayoutBlocks, 2880);
  });

  test('the subsidy halves exactly and floors at the tail emission', () {
    const demo = NetworkInfo.demo; // halves every 2,000 blocks
    expect(
        [for (final h in [1999, 2000, 4000, 6000, 8000, 10000, 2000 * 1000]) demo.subsidyAt(h)],
        [25000000, 12500000, 6250000, 3125000, 1562500, 1000000, 1000000]);
  });
}
