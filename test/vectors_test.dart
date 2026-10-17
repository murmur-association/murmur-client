// The node's test vectors for protocol 13: those PROTOCOL.md gives without a
// chain (Sections 2.2, 3.1, 3.2, 3.6, 4 and 6), and `vectors/demo-12.txt`,
// a nine-block chain on the demo network that the node's own tests rebuild
// byte for byte (copied here as test/vectors/demo-12.txt). The chain is
// rebuilt here from its transactions and nonces: every header's target,
// commitments and hash, the state entries, a filter, and the node's answers
// to GetThread and GetAddress with their proofs.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/commitments.dart';
import 'package:murmur_client/protocol/consensus.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/protocol/quote.dart';
import 'package:murmur_client/protocol/wire.dart';

Uint8List _filled(int byte, [int n = 32]) => Uint8List(n)..fillRange(0, n, byte);

BlockHeader _header(int height, int time, Uint8List target, {BlockHeader? parent}) => BlockHeader(
      height: height,
      prevHash: parent?.hash ?? _filled(height),
      merkleRoot: Uint8List(32),
      stateRoot: Uint8List(32),
      filterHash: Uint8List(32),
      historyRoot: Uint8List(32),
      timestamp: time,
      target: target,
      nonce: u64Bytes(height),
      miner: Uint8List(32),
    );

/// The vector file's blocks: `name = value` lines under `## block n`.
class _Vectors {
  _Vectors(String text) {
    var block = 0;
    for (final line in const LineSplitter().convert(text)) {
      if (line.startsWith('## block ')) {
        block = int.parse(line.substring(9).split(':').first);
      } else if (line.startsWith('## ')) {
        block = -1;
      }
      if (line.startsWith('#') || !line.contains(' = ')) continue;
      final at = line.indexOf(' = ');
      (blocks[block] ??= []).add((line.substring(0, at), line.substring(at + 3)));
    }
  }

  /// Block number (0 before the first, -1 for the answers) to its lines.
  final blocks = <int, List<(String, String)>>{};

  String one(int block, String name) => blocks[block]!.firstWhere((l) => l.$1 == name).$2;
  List<String> all(int block, String name) => [for (final l in blocks[block]!) if (l.$1 == name) l.$2];
}

void main() {
  test('genesis hashes match PROTOCOL.md Section 6', () {
    expect(NetworkInfo.whitepaper.genesisHeader().id,
        '1910d5ee9865e593f0b4b4141f715f958163ec36bb76f039262cfc8c1feb71db');
    expect(NetworkInfo.demo.genesisHeader().id, '3312c98658403c230452ed20da787b5cd1e43ae0d1b95dbf394487761d5ad68e');
    expect(NetworkInfo.forGenesis(NetworkInfo.demo.genesisHeader().hash).id, 'murmur-demo-12');
    expect(NetworkInfo.forGenesis(Uint8List(32)).known, isFalse);
  });

  group('numbers in as few bytes as they need (Section 2.2)', () {
    Uint8List enc(int v) => (ByteWriter()..varint(v)).take();
    int dec(List<int> bytes) {
      final r = ByteReader(Uint8List.fromList(bytes));
      final v = r.varint();
      r.finish();
      return v;
    }

    test('round trips, least significant group first', () {
      expect(enc(0), [0]);
      expect(enc(127), [0x7f]);
      expect(enc(128), [0x80, 0x01]);
      expect(toHex(enc(500000)), 'a0c21e');
      expect(toHex(enc(750000)), 'b0e32d');
      for (final v in [0, 1, 127, 128, 16383, 16384, 500000, 0xffffffff, 0x100000000, 9007199254740991]) {
        expect(dec(enc(v)), v);
      }
    });

    test('only the shortest form is a number, and nothing a browser would round', () {
      expect(() => dec([0x80, 0x00]), throwsFormatException, reason: 'padded');
      expect(() => dec([0xa0, 0xc2, 0x9e, 0x00]), throwsFormatException, reason: 'padded');
      expect(() => dec([0x80]), throwsFormatException, reason: 'cut short');
      // 2^53, then 2^64 - 1, then eleven bytes.
      expect(() => dec([0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x10]), throwsFormatException);
      expect(() => dec([...List.filled(9, 0xff), 0x01]), throwsFormatException);
      expect(() => dec([...List.filled(10, 0x80), 0x01]), throwsFormatException);
      expect(() => enc(9007199254740992), throwsArgumentError);
    });
  });

  test('transactions of every kind, signed for the testnet (Section 2.2)', () async {
    final w = await MurmurWallet.fromSeed(_filled(7));
    final tag = NetworkInfo.whitepaper.tag;
    final content = Uint8List.fromList([..._filled(1, 16), ...utf8.encode('hello')]);
    final hash = sha256Bytes(content);
    const fee = 500000;
    final txs = [
      await w.sign(networkTag: tag, kind: TxKind.orphan, nonce: 0, fee: fee, messageHash: hash, contentSize: 21),
      await w.sign(
          networkTag: tag,
          kind: TxKind.reply,
          nonce: 1,
          fee: fee,
          amount: 750000,
          messageHash: hash,
          contentSize: 21,
          reference: _filled(0xaa)),
      await w.sign(networkTag: tag, kind: TxKind.raw, nonce: 2, fee: fee, amount: 12345678, to: _filled(0xbb)),
      await w.sign(networkTag: tag, kind: TxKind.flag, nonce: 3, fee: fee, reference: _filled(0xaa)),
      await w.sign(
          networkTag: tag, kind: TxKind.flag, nonce: 4, fee: fee, reference: _filled(0xcc), thread: _filled(0xaa)),
      await w.sign(networkTag: tag, kind: TxKind.name, nonce: 5, fee: fee, messageHash: hash, contentSize: 21),
      // An Answer: a reply that names the reply it answers by 4 bytes.
      await w.sign(
          networkTag: tag,
          kind: TxKind.reply,
          nonce: 6,
          fee: fee,
          amount: 750000,
          messageHash: hash,
          contentSize: 21,
          reference: _filled(0xaa),
          answers: fromHex('3fa9c21e')),
    ];
    expect([for (final tx in txs) tx.bytes.length], [134, 169, 137, 134, 166, 134, 173]);
    expect([for (final tx in txs) tx.id], [
      '199a39f5af78082d686760bf7e352f481e152374e1273ef3b5febe71ad94fc47',
      '4d9839706d3537f8d9d2f7827e88b2504e8e7bae3c04994c2061b4d06ba0a29a',
      '86ded0aeda2be59149239163ab69ec8939013543d25aad913ecb89237e141915',
      '57afa15407a26cb1e6a6973812d3fd39a32d07ad381a53e327c14e0abe474910',
      '267ba2ac8f2f3044630f33360cd977f3606fcf6c76cf74e855b77dad18188d50',
      '45b2a019bdac4afe9238e0c7eb8ffeba413983408d79c392fdd4f7bf29401a88',
      '9dc72fd28c22dff4d61fa380bf7ed7097a6a39270f10659d9852999e6117186c',
    ]);
    expect(
        toHex(txs[0].bytes),
        '00ea4a6c63e29c520abef5507b132ec5f9954776aebebe7b92421eea691446d22c00a0c21e06c343731700ca16797f96e987'
        '180093e28b4c653e08efccb4f5fbb91313f56c15c6f40cd9dbef82d4c10b838faeef45b5c57c494119cd75bf3d5f75665cd9'
        '0cc7410e6958148e328305f8406f833bdbee26382d672b2767344b475e3c7fbb5f0e');
    // An Answer is a Reply on every count but its tag and its last 4 bytes.
    expect(txs[6].bytes.first, 5);
    expect(txs[6].kind, TxKind.reply);
    expect(txs[6].answersHex, '3fa9c21e');
    expect(txs[1].answers, isNull);
    expect(txs[6].weight, txs[1].weight + 4);
    expect(txs[6].weight, lessThanOrEqualTo(txWeight(21)));
    expect(txs[6].threadId, txs[1].threadId);
    // What isn't written follows from the rest.
    expect(txs[0].from, w.address);
    expect(txs[0].amount, 5000000, reason: 'a thread burns ten times its fee');
    expect(txs[5].burned, 5000000);
    expect(txs[3].amount, 0);
    expect([for (final tx in txs) tx.threadId], [
      txs[0].id, toHex(_filled(0xaa)), null, toHex(_filled(0xaa)), toHex(_filled(0xaa)), txs[5].id, //
      toHex(_filled(0xaa)),
    ]);
    // Each survives the wire, and is the only reading of its bytes.
    for (final tx in txs) {
      final r = ByteReader(tx.bytes);
      final back = Transaction.read(r);
      r.finish();
      expect(back.id, tx.id);
      expect(back.weight, tx.bytes.length + tx.contentSize);
    }
    // A transaction signed for another network has another signature.
    final demo = await w.sign(
        networkTag: NetworkInfo.demo.tag, kind: TxKind.orphan, nonce: 0, fee: fee, messageHash: hash, contentSize: 21);
    expect(demo.body, txs[0].body);
    expect(demo.signature, isNot(txs[0].signature));
    // An unknown kind, and a flag marker that is neither 0 nor 1.
    expect(() => Transaction.read(ByteReader(Uint8List.fromList([6, ...txs[0].bytes.sublist(1)]))),
        throwsFormatException);
    // Only a reply answers, and with 4 bytes.
    expect(
        () => Transaction.bodyFor(
            kind: TxKind.orphan, pubkey: w.publicKey, nonce: 0, fee: fee, messageHash: hash, answers: Uint8List(4)),
        throwsArgumentError);
    expect(
        () => Transaction.bodyFor(
            kind: TxKind.reply,
            pubkey: w.publicKey,
            nonce: 0,
            fee: fee,
            messageHash: hash,
            reference: _filled(0xaa),
            answers: Uint8List(3)),
        throwsArgumentError);
    const marker = 1 + 32 + 1 + 3 + 32;
    expect(txs[3].bytes[marker], 0);
    expect(() => Transaction.read(ByteReader(Uint8List.fromList(txs[3].bytes)..[marker] = 2)), throwsFormatException);
  });

  test('a header keeps every bit of its nonce and of its target (Section 3.1)', () {
    final wire = fromHex('0000000000006c9a0000003fbddd247dcc70a4a380e4d961de600da963d41c611400d4720bb0f10b'
        '0000000000000000000000000000000000000000000000000000000000000000'
        'f34c0e6bf382756779500d39a00a7821af4cc162825b1de8b3de4a3b1e69ea98'
        'df3f619804a92fdb4057192dc43dd748ea778adc52bc498ce80524c014b81119'
        '04717153a74686397cb63948d8a5f406af099169adaee20b435347433f4fead3'
        '000000006ac64dd6000001c0c0490469817b48c4f6d1a867ffffffffffffffff'
        'ffffffffffffffff55e96d778ea4c7617c2d9aee91b740ba61aa4ef61e0f853f'
        '67c3a292b065f1b3b77b6068066fee28');
    expect(wire.length, headerBytes);
    final h = decodeHeader(wire);
    expect(h.height, 27802);
    expect(BigInt.parse(toHex(h.nonce), radix: 16), BigInt.parse('6190599523059156833'));
    expect(h.id, 'c4281183b93686debedc6f05c86c7c609707fd43cf1ec1d27d62f08602e79116');
    expect(encodeHeader(h), wire);
    BlockHeader withNonce(BigInt nonce) => decodeHeader(
        Uint8List.fromList(wire)..setRange(208, 216, fromHex(nonce.toRadixString(16).padLeft(16, '0'))));
    expect(withNonce((BigInt.one << 63) + BigInt.from(12345)).id,
        'b7b4c3b69bc837a374d7a1c8ab6685b7b2e8f751b718286328c42e90dad06881');
    expect(withNonce((BigInt.one << 64) - BigInt.one).id,
        '6745c5eed4a53f7df3a51644e83ad33151de91539a0a6f1b60f068d2e894aad7');
    expect(h.meetsTarget, isFalse);
  });

  test('proof of work compares the whole hash, and work is 2^256 / (target + 1) (Section 3.2)', () {
    expect(blockWork(u256Bytes(u256Max)), BigInt.one);
    expect(blockWork(u256Bytes(u256Max >> 8)), BigInt.from(256));
    expect(blockWork(u256Bytes(BigInt.from(0xffff))), BigInt.one << 240);
    expect(blockWork(Uint8List(32)), u256Max);
    final h = _header(1, 0, _filled(0xff));
    expect(h.meetsTarget, isTrue);
    // Exactly the hash is enough; one less in the last byte is not.
    final same = BlockHeader(
        height: 1,
        prevHash: _filled(1),
        merkleRoot: Uint8List(32),
        stateRoot: Uint8List(32),
        filterHash: Uint8List(32),
        historyRoot: Uint8List(32),
        timestamp: 0,
        target: Uint8List(32),
        nonce: u64Bytes(1),
        miner: Uint8List(32),
        hash: _filled(0));
    expect(same.meetsTarget, isTrue);
    expect(_header(1, 0, Uint8List(32)).meetsTarget, isFalse);
  });

  group('difficulty (Section 4)', () {
    const net = NetworkInfo.whitepaper;
    final two200 = u256Bytes(BigInt.one << 200);

    test('the fixed-point factor', () {
      expect([for (final f in [1, 16384, 32768, 49152, 65535]) difficultyFactor(f).toInt()],
          [65537, 77938, 92674, 110225, 131071]);
      expect(difficultyFactor(0).toInt(), 65536);
    });

    test('the pinned targets', () {
      String target(int grandparentTime, int blockTime) {
        final grandparent = _header(98, grandparentTime, two200);
        final parent = _header(99, 10000, two200, parent: grandparent);
        return toHex(nextTarget(parent: parent, grandparent: grandparent, timestamp: blockTime, net: net));
      }

      String padded(String start) => start.padRight(64, '0');
      expect(target(9999, 10030), padded('00000000000000fa5b80'));
      expect(target(9940, 10030), padded('0000000000000106'));
      expect(target(10020, 10030), padded('00000000000000f659'));
      expect(target(9970, 11237), padded('0000000000000116e'));
      expect(target(9000, 13000), padded('000000000000871a8'));
    });

    test('on time leaves the target, the first block keeps genesis\'s, and the limits hold', () {
      final grandparent = _header(98, 9970, two200);
      final parent = _header(99, 10000, two200, parent: grandparent);
      expect(nextTarget(parent: parent, grandparent: grandparent, timestamp: 10030, net: net), two200);
      expect(nextTarget(parent: parent, grandparent: grandparent, timestamp: 11200, net: net), two200,
          reason: 'within the slack, a block\'s own time doesn\'t count');
      expect(nextTarget(parent: net.genesisHeader(), grandparent: null, timestamp: 1 << 40, net: net),
          net.genesisTarget);
      // Years of silence ease it to the limit, never past it.
      expect(nextTarget(parent: parent, grandparent: grandparent, timestamp: 10000 + 400000000, net: net),
          u256Bytes(u256Max));
      final hard = _header(99, 10000, u256Bytes(BigInt.one), parent: grandparent);
      expect(nextTarget(parent: hard, grandparent: _header(98, 10000, two200), timestamp: 10030, net: net),
          u256Bytes(BigInt.one), reason: 'never below 1');
    });

    test('median time past is the upper median of the last 11', () {
      final t = u256Bytes(u256Max);
      expect(medianTimePast([for (final ts in [5, 1, 9, 3]) _header(1, ts, t)]), 5);
      expect(medianTimePast([for (var i = 0; i < 11; i++) _header(1, 100 - i, t)]), 95);
    });
  });

  test('header history root with 256-bit work and targets (Section 3.6)', () {
    final peaks = HistoryPeaks();
    final headers = <BlockHeader>[];
    for (var i = 0; i < 11; i++) {
      final h = BlockHeader(
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
      );
      headers.add(h);
      peaks.pushHeader(h);
    }
    expect(toHex(peaks.root), '1e98e56fd83ec8c8927893a9e2ad7237368ba9ee2bc5c81854b6545cc82e6826');
    final bagged = bagPeaks(peaks.nodes)!;
    expect(bagged.work, headers.fold<BigInt>(BigInt.zero, (sum, h) => sum + h.work));
    expect(bagged.data.length, 112);
  });

  group('the demo chain of vectors/demo-12.txt', () {
    final v = _Vectors(File('test/vectors/demo-12.txt').readAsStringSync());
    const net = NetworkInfo.demo;
    final alice = fromHex(v.one(0, 'alice')), bob = fromHex(v.one(0, 'bob'));

    Transaction tx(String hex) {
      final r = ByteReader(fromHex(hex));
      final t = Transaction.read(r);
      r.finish();
      return t;
    }

    // Each block's transactions, in the order the file gives them.
    List<Transaction> txsOf(int block) => [
          for (final (name, value) in v.blocks[block]!)
            if (!name.contains('.') &&
                !name.contains('[') &&
                !const {'target', 'nonce', 'merkle_root', 'state_root', 'filter_hash', 'history_root', 'hash', 'filter'}
                    .contains(name))
              tx(value),
        ];

    // The chain, rebuilt: every header from its transactions, its parent
    // and the nonce the file gives.
    final chain = <BlockHeader>[net.genesisHeader()];
    final blocks = <Block>[Block(chain.first, const [])];
    final history = HistoryPeaks();
    for (var n = 1; n <= 11; n++) {
      history.pushHeader(chain.last);
      final txs = txsOf(n);
      final time = 1000000 + 2 * n;
      final header = BlockHeader(
        height: n,
        prevHash: chain.last.hash,
        merkleRoot: merkleRoot([for (final t in txs) t.hash]),
        stateRoot: fromHex(v.one(n, 'state_root')),
        filterHash: sha256Bytes(buildFilter(chain.last.hash, blockFilterItems(txs))),
        historyRoot: history.root,
        timestamp: time,
        target: nextTarget(
            parent: chain.last, grandparent: n >= 2 ? chain[n - 2] : null, timestamp: time, net: net),
        nonce: u64Bytes(int.parse(v.one(n, 'nonce'))),
        miner: n == 1 ? alice : (n == 2 ? bob : _filled(7)),
      );
      chain.add(header);
      blocks.add(Block(header, txs));
    }

    test('keys, and every transaction\'s id', () async {
      expect((await MurmurWallet.fromSeed(_filled(1))).address, alice);
      expect((await MurmurWallet.fromSeed(_filled(2))).address, bob);
      expect(toHex(net.genesisHeader().hash), v.one(0, 'genesis'));
      var seen = 0;
      for (var n = 1; n <= 11; n++) {
        for (final (name, value) in v.blocks[n]!) {
          if (!name.endsWith('.txid')) continue;
          expect(tx(v.one(n, name.substring(0, name.length - 5))).id, value, reason: name);
          seen++;
        }
      }
      expect(seen, 16);
    });

    test('every block: target, merkle root, filter hash, history root, proof of work and hash', () {
      final peaks = HistoryPeaks();
      for (var n = 1; n <= 11; n++) {
        final h = chain[n];
        expect(toHex(h.target), v.one(n, 'target'), reason: 'target of block $n');
        expect(toHex(h.merkleRoot), v.one(n, 'merkle_root'), reason: 'merkle root of block $n');
        expect(toHex(h.filterHash), v.one(n, 'filter_hash'), reason: 'filter hash of block $n');
        expect(toHex(h.historyRoot), v.one(n, 'history_root'), reason: 'history root of block $n');
        expect(h.id, v.one(n, 'hash'), reason: 'hash of block $n');
        expect(h.meetsTarget, isTrue);
        // And as the client checks a header it is sent.
        peaks.pushHeader(chain[n - 1]);
        checkHeaderRules(h, (height) => height >= 0 && height < n ? chain[height] : null, peaks, net);
      }
      // The second block is eased once: the first came long after genesis.
      expect(chain[1].target, net.genesisTarget);
      expect(chain[2].target, isNot(net.genesisTarget));
    });

    test('the filter of block 9 and its items', () {
      final items = blockFilterItems(blocks[9].transactions);
      expect({for (final i in items) toHex(i)}, v.all(9, 'filter.item').toSet());
      final filter = buildFilter(chain[8].hash, items);
      expect(toHex(filter), v.one(9, 'filter'));
      // A reply's thread and its sender are items; who it pays is not.
      final thread2 = blocks[9].transactions.first;
      expect(filterMatchesAny(filter, chain[8].hash, [thread2.hash]), isTrue);
      expect(filterMatchesAny(filter, chain[8].hash, [_filled(0x55)]), isFalse);
    });

    test('state entries: accounts, threads and names, and the list roots they commit to', () {
      final thread = blocks[3].transactions.single;
      String entry(int block, String label) => v.blocks[block]!.firstWhere((l) => l.$1.startsWith('state[$label]')).$2;
      String keyOf(int block, String label) =>
          v.blocks[block]!.firstWhere((l) => l.$1.startsWith('state[$label]')).$1.split(' ').last;

      expect(toHex(accountKey(alice)), keyOf(2, 'account alice'));
      expect(toHex(threadKey(thread.hash)), keyOf(3, 'thread'));
      expect(toHex(nameKey(alice)), keyOf(7, 'name alice'));
      expect(entry(8, 'name bob'), 'absent');

      // Block 2: both were paid a block's reward, which is in no list.
      final paid = AccountEntry.parse(fromHex(entry(2, 'account alice')))!;
      expect(paid.balance, 25 * unitsPerToken);
      expect(paid.nonce, 0);
      expect(paid.credits, 0);
      expect(paid.creditRoot, Uint8List(32));

      // Block 5: the thread has three events, and alice was credited by each
      // (her own reply there included).
      final events = [
        blocks[4].transactions[0].hash,
        blocks[5].transactions[0].hash,
        blocks[5].transactions[1].hash,
      ];
      final t5 = ThreadEntry.parse(fromHex(entry(5, 'thread')))!;
      expect(t5.author, alice);
      expect(t5.events, 3);
      expect(t5.eventsRoot, listRoot(events));
      final a5 = AccountEntry.parse(fromHex(entry(5, 'account alice')))!;
      expect(a5.nonce, 2);
      expect(a5.sentRoot, listRoot([thread.hash, blocks[5].transactions[1].hash]));
      expect(a5.credits, 3);
      expect(a5.creditRoot, t5.eventsRoot);
      // 25 − 5.5 for the thread, + 0.75 twice from bob, − 0.5 for her own reply's fee.
      expect(a5.balance, 25000000 - 5500000 + 2 * 750000 - 500000);

      // Block 6: a flag is an event of the thread it names, and credits nobody.
      final t6 = ThreadEntry.parse(fromHex(entry(6, 'thread')))!;
      expect(t6.events, 4);
      expect(t6.eventsRoot, listRoot([...events, blocks[6].transactions.single.hash]));
      expect(AccountEntry.parse(fromHex(entry(6, 'account alice')))!.credits, 3);

      // Blocks 7 and 8: a name is its message's hash, replaced by the next;
      // it is a thread's first message, whose flag is that thread's event.
      expect(entry(7, 'name alice'), toHex(blocks[7].transactions.single.messageHash!));
      expect(entry(8, 'name alice'), toHex(blocks[8].transactions.first.messageHash!));
      final ofName = ThreadEntry.parse(fromHex(entry(8, 'thread of name1')))!;
      expect(ofName.author, alice);
      expect(ofName.events, 1);
      expect(ofName.eventsRoot, listRoot([blocks[8].transactions[1].hash]));
      expect(toHex(threadKey(blocks[7].transactions.single.hash)), keyOf(7, 'thread of name1'));

      expect(AccountEntry.parse(Uint8List(16)), isNull);
      expect(ThreadEntry.parse(Uint8List(88)), isNull);
    });

    // A page's entries are on the chain: each merkle branch leads to its
    // block's root, and the block is the one this chain has at that height.
    void expectOnChain(ListPage page) {
      for (final e in page.entries) {
        expect(e.blockHash, chain[e.height].hash);
        expect(merkleRootFromBranch(e.tx.hash, e.index, e.branch), chain[e.height].merkleRoot);
      }
    }

    bool proven(ListPage page, Uint8List root) => verifyListRange(
        total: page.total,
        start: page.start,
        txids: [for (final e in page.entries) e.tx.hash],
        peaks: page.peaks,
        siblings: page.siblings,
        root: root);

    test('list roots and range proofs (Section 3.6)', () {
      List<Uint8List> txids(int n) => [for (var i = 0; i < n; i++) _filled(i)];
      for (final n in [0, 1, 2, 3, 4, 11, 1024]) {
        expect(toHex(listRoot(txids(n))), v.one(-1, 'list.root[$n]'), reason: 'root of $n');
      }
      final list = txids(11), root = listRoot(list);
      for (final (name, start, count) in [('4..8', 3, 5), ('last', 10, 1), ('first', 0, 1)]) {
        final peaks = [for (final p in v.all(-1, 'list.proof[$name].peak')) fromHex(p)];
        final siblings = [for (final s in v.all(-1, 'list.proof[$name].sibling')) fromHex(s)];
        final entries = list.sublist(start, start + count);
        bool check({int? at, List<Uint8List>? with_, List<Uint8List>? peaksIn, List<Uint8List>? siblingsIn, int n = 11}) =>
            verifyListRange(
                total: n,
                start: at ?? start,
                txids: with_ ?? entries,
                peaks: peaksIn ?? peaks,
                siblings: siblingsIn ?? siblings,
                root: root);
        expect(check(), isTrue, reason: name);
        // Anything changed fails: a sibling, a peak, an entry, the place, a
        // sibling left out or one too many, the list's length.
        for (var i = 0; i < siblings.length; i++) {
          expect(check(siblingsIn: [...siblings]..[i] = _filled(0x77)), isFalse);
          expect(check(siblingsIn: [...siblings]..removeAt(i)), isFalse);
        }
        expect(check(siblingsIn: [...siblings, _filled(0x77)]), isFalse);
        expect(check(peaksIn: [...peaks]..[0] = _filled(0x77)), isFalse);
        expect(check(with_: [_filled(0x77), ...entries.skip(1)]), isFalse);
        if (start > 0) expect(check(at: start - 1), isFalse);
        expect(check(n: 12), isFalse);
      }
      // No entries: the peaks alone prove the count and the root.
      final peaks = [for (final p in v.all(-1, 'list.proof[first].peak')) fromHex(p)];
      expect(verifyListRange(total: 11, start: 11, txids: const [], peaks: peaks, siblings: const [], root: root), isTrue);
      expect(verifyListRange(total: 12, start: 11, txids: const [], peaks: peaks, siblings: const [], root: root), isFalse);
      // Every range of short lists, with proofs made as the node makes them.
      for (var n = 1; n <= 9; n++) {
        final all = txids(n);
        for (var a = 0; a < n; a++) {
          for (var b = a; b < n; b++) {
            final (p, s) = _rangeProof(all, a, b);
            expect(
                verifyListRange(
                    total: n, start: a, txids: all.sublist(a, b + 1), peaks: p, siblings: s, root: listRoot(all)),
                isTrue,
                reason: '$n: $a..$b');
          }
        }
      }
    });

    test('a node\'s answers to GetThread, each page proven on its own against the thread\'s entry', () {
      final thread = blocks[3].transactions.single;
      final entry = ThreadEntry.parse(fromHex(
          v.blocks[11]!.firstWhere((l) => l.$1.startsWith('state[thread]')).$2))!;
      for (final name in ['thread', 'thread_first', 'thread_middle']) {
        final bytes = fromHex(v.one(-1, '$name.answer'));
        final msg = decodeMessage(bytes) as Thread;
        expect(encodePayload(msg), bytes);
        expect(msg.root, thread.hash);
        final page = msg.page;
        expect(page.available, isTrue);
        expect(page.at, chain[11].hash);
        expect(page.total, int.parse(v.one(-1, '$name.total')));
        expect(page.start, int.parse(v.one(-1, '$name.start')));
        expect(page.entries.length, int.parse(v.one(-1, '$name.count')));
        expect([for (final p in page.peaks) toHex(p)], v.all(-1, '$name.peak'));
        expect([for (final s in page.siblings) toHex(s)], v.all(-1, '$name.sibling'));
        expectOnChain(page);
        expect(page.total, entry.events);
        expect(proven(page, entry.eventsRoot), isTrue, reason: name);
        // An entry left out doesn't prove.
        if (page.entries.length > 1) {
          expect(
              verifyListRange(
                  total: page.total,
                  start: page.start,
                  txids: [page.entries.last.tx.hash],
                  peaks: page.peaks,
                  siblings: page.siblings,
                  root: entry.eventsRoot),
              isFalse);
        }
      }
      // The newest page: its last two events are Answers, events like any reply.
      final newest = (decodeMessage(fromHex(v.one(-1, 'thread.answer'))) as Thread).page;
      expect([for (final e in newest.entries) e.tx.answers != null], [true, true]);
      expect([for (final e in newest.entries) e.tx.kind], everyElement(TxKind.reply));
      // The first page is the thread's first reply, though the thread goes on.
      final first = (decodeMessage(fromHex(v.one(-1, 'thread_first.answer'))) as Thread).page;
      expect(first.entries.single.tx.id, blocks[4].transactions.single.id);
    });

    test('a node\'s answers to GetAddress: sent and credited proven, flags against as the node knows them', () {
      final account = AccountEntry.parse(fromHex(
          v.blocks[11]!.firstWhere((l) => l.$1.startsWith('state[account alice]')).$2))!;
      Address answer(String name, [Uint8List? of]) {
        final bytes = fromHex(v.one(-1, '$name.answer'));
        final msg = decodeMessage(bytes) as Address;
        expect(encodePayload(msg), bytes);
        expect(msg.address, of ?? alice);
        expect(msg.page.total, int.parse(v.one(-1, '$name.total')));
        expect(msg.page.start, 0);
        expectOnChain(msg.page);
        return msg;
      }

      // What she sent is her nonce's worth, Answers among them.
      final sent = answer('alice.sent');
      expect(sent.list, AddressList.sent);
      expect(sent.page.entries.every((e) => bytesEqual(e.tx.from, alice)), isTrue);
      expect(sent.page.entries.where((e) => e.tx.answers != null).length, 2);
      expect(proven(sent.page, account.sentRoot), isTrue);
      expect(listRoot([for (final e in sent.page.entries) e.tx.hash]), account.sentRoot);
      expect(account.nonce, sent.page.total);

      // Her first transaction alone, proven though the list goes on.
      final first = answer('alice.sent_first');
      expect(first.page.entries.single.tx.id, sent.page.entries.first.tx.id);
      expect([for (final p in first.page.peaks) toHex(p)], v.all(-1, 'alice.sent_first.peak'));
      expect([for (final s in first.page.siblings) toHex(s)], v.all(-1, 'alice.sent_first.sibling'));
      expect(proven(first.page, account.sentRoot), isTrue);
      expect(proven(first.page, account.creditRoot), isFalse);

      final credited = answer('alice.credited');
      expect(credited.list, AddressList.credited);
      expect(credited.page.total, account.credits);
      expect(proven(credited.page, account.creditRoot), isTrue);

      final flags = answer('alice.flags');
      expect(flags.list, AddressList.flagsAgainst);
      expect([for (final e in flags.page.entries) e.tx.kind], everyElement(TxKind.flag));
    });

    test('the answers to an address (GetAddress, list 3), and which reply each answers (Section 2.4)', () {
      final thread = blocks[3].transactions.single;
      // The thread's replies, oldest first, as the chain has them.
      final replies = [
        for (final b in blocks)
          for (final t in b.transactions)
            if (t.kind == TxKind.reply && t.threadId == thread.id) t,
      ];
      String? answered(Transaction answer) =>
          quotedReply([for (final r in replies.takeWhile((r) => r.id != answer.id)) r.id], answer.answersHex!);
      final [answer1, answer2, answer3] = blocks[11].transactions;
      final alike1 = tx(v.one(10, 'alike1')), alike2 = tx(v.one(10, 'alike2'));
      expect(alike1.id.substring(0, 8), alike2.id.substring(0, 8));
      // Alice answers bob's first reply; bob answers nothing that exists;
      // alice answers the bytes two replies share, and so the older, bob's.
      expect(answered(answer1), blocks[4].transactions.single.id);
      expect(answered(answer2), isNull);
      expect(answered(answer3), alike1.id);
      expect(bytesEqual(alike1.from, bob), isTrue);

      // So bob was answered twice, and the node lists exactly those.
      final bytes = fromHex(v.one(-1, 'bob.answers.answer'));
      final msg = decodeMessage(bytes) as Address;
      expect(encodePayload(msg), bytes);
      expect(msg.address, bob);
      expect(msg.list, AddressList.answers);
      expect(msg.page.total, 2);
      expect(msg.page.peaks, isEmpty, reason: 'no state entry holds this list');
      expect(msg.page.siblings, isEmpty);
      expectOnChain(msg.page);
      expect([for (final e in msg.page.entries) e.tx.id], [answer1.id, answer3.id]);
      // Each proves itself: it names a reply of bob's, in a thread of his reply.
      for (final e in msg.page.entries) {
        final reply = replies.firstWhere((r) => r.id == answered(e.tx));
        expect(reply.from, bob);
        expect(reply.threadId, e.tx.threadId);
      }
    });
  });

  test('the new messages have the node layout, with their limits', () {
    final root = _filled(9);
    expect(toHex(encodePayload(GetThread(root, 0, 2))), '1c${toHex(root)}000000000000000000000002');
    expect(toHex(encodePayload(GetAddress(Uint8List(32), AddressList.credited, 7, 500)).sublist(33)),
        '01000000000000000700' '0001f4');
    for (final Message m in [
      GetThread(root, 12, 500),
      GetAddress(root, AddressList.flagsAgainst, 0, 0),
      GetAddress(root, AddressList.answers, 0, 500),
    ]) {
      expect(encodePayload(decodeMessage(encodePayload(m))), encodePayload(m));
    }
    expect(() => decodeMessage(encodePayload(GetThread(root, 0, 501))), throwsFormatException);
    final bad = encodePayload(GetAddress(root, AddressList.sent, 0, 1))..[33] = 4;
    expect(() => decodeMessage(bad), throwsFormatException);
    // A state value may be 96 bytes, no more.
    State state(int n) => State(root, true, [(root, StateProof(const [], ValueTerminal(Uint8List(n))))]);
    expect(decodeMessage(encodePayload(state(96))), isA<State>());
    expect(() => decodeMessage(encodePayload(state(97))), throwsFormatException);
  });
}

/// The range proof of entries `a` to `b` (from 0) of `txids`, made the way
/// the node makes it (PROTOCOL.md Section 3.6): every peak, and the
/// siblings of the walk over the peaks the range meets, left to right.
(List<Uint8List>, List<Uint8List>) _rangeProof(List<Uint8List> txids, int a, int b) {
  Uint8List subtree(int first, int height) => height == 0
      ? listLeaf(txids[first])
      : listJoin(subtree(first, height - 1), subtree(first + (1 << (height - 1)), height - 1));
  final peaks = <Uint8List>[], siblings = <Uint8List>[];
  void walk(int first, int height) {
    final last = first + (1 << height) - 1;
    if (last < a || first > b) {
      siblings.add(subtree(first, height));
    } else if (first < a || last > b) {
      walk(first, height - 1);
      walk(first + (1 << (height - 1)), height - 1);
    }
  }

  for (final (first, height) in listLayout(txids.length)) {
    peaks.add(subtree(first, height));
    final last = first + (1 << height) - 1;
    if (last >= a && first <= b) walk(first, height);
  }
  return (peaks, siblings);
}
