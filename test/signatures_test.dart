// The client checks every transaction's signature by ZIP 215 (PROTOCOL.md
// Section 1), against a node that breaks the rules (support/fake_node.dart):
// a relayed transaction with a forged signature is never shown, and a mined
// one stops the client.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/commitments.dart';
import 'package:murmur_client/protocol/consensus.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/protocol/wire.dart';
import 'package:murmur_client/services/node_client.dart';

import 'support/fake_node.dart';

const _net = NetworkInfo.demo;

/// `tx` with one bit of its signature changed.
Transaction _forged(Transaction tx) {
  final r = ByteReader(Uint8List.fromList(tx.bytes)..[tx.bytes.length - 5] ^= 1);
  return Transaction.read(r);
}

/// Block 1 of the demo network, holding `txs`, mined.
Block _blockOne(List<Transaction> txs) {
  final genesis = _net.genesisHeader();
  final history = HistoryPeaks()..pushHeader(genesis);
  final time = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60;
  for (var n = 0;; n++) {
    final header = BlockHeader(
      height: 1,
      prevHash: genesis.hash,
      merkleRoot: merkleRoot([for (final t in txs) t.hash]),
      stateRoot: Uint8List(32),
      filterHash: sha256Bytes(buildFilter(genesis.hash, blockFilterItems(txs))),
      historyRoot: history.root,
      timestamp: time,
      target: nextTarget(parent: genesis, grandparent: null, timestamp: time, net: _net),
      nonce: u64Bytes(n),
      miner: Uint8List(32),
    );
    if (header.meetsTarget) return Block(header, txs);
  }
}

Future<void> _until(bool Function() done, {Duration timeout = const Duration(seconds: 20)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) fail('timed out');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  late MurmurWallet alice;
  setUpAll(() async => alice = await MurmurWallet.generate());

  Future<Transaction> transfer(int nonce) =>
      alice.sign(networkTag: _net.tag, kind: TxKind.raw, nonce: nonce, to: Uint8List(32), amount: 5, fee: 500000);

  test('a relayed transaction is shown once its signature checks out, and a forged one never', () async {
    final good = await transfer(0);
    final forged = _forged(await transfer(1));
    expect(forged.id, isNot(good.id));
    final node = await FakeNode.bind(InternetAddress.loopbackIPv4, 0,
        relay: [NewTx(forged, null), NewTx(good, null)]);
    addTearDown(node.close);
    final client = MurmurClient();
    addTearDown(client.dispose);
    await client.connect('127.0.0.1', node.port);
    await _until(() => client.lookupTx(good.id) != null);
    await _until(() => client.relayedRefused == 1);
    expect(client.lookupTx(forged.id), isNull, reason: 'nothing proves it, and its signature is wrong');
    expect(client.error, isNull, reason: 'a relayed transaction proves nothing about the chain');
  });

  test('a block holding a transaction with a forged signature stops the client, which says which block', () async {
    final node = await FakeNode.bind(InternetAddress.loopbackIPv4, 0, chain: [_blockOne([_forged(await transfer(0))])]);
    addTearDown(node.close);
    final client = MurmurClient();
    addTearDown(client.dispose);
    await client.connect('127.0.0.1', node.port);
    await _until(() => client.error != null);
    final error = client.error!;
    final cause = error.kind == LinkErrorKind.syncFailed ? error.cause! : error;
    expect((cause.kind, cause.height), (LinkErrorKind.badSignature, 1));
    expect(client.retryAt, isNull, reason: 'retrying the same node can\'t fix its chain');
  });

  test('the same block with a valid signature is taken', () async {
    final tx = await transfer(0);
    final node = await FakeNode.bind(InternetAddress.loopbackIPv4, 0, chain: [_blockOne([tx])]);
    addTearDown(node.close);
    final client = MurmurClient();
    addTearDown(client.dispose);
    await client.connect('127.0.0.1', node.port);
    await _until(() => client.lookupTx(tx.id)?.confirmed ?? false);
    await _until(() => client.signaturesChecked >= 1);
    expect(client.error, isNull);
  });
}
