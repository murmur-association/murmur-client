// Messages made by hand, for tests of what's built over them: threads, and
// what's starred. Signatures aren't checked there, so none is real.

import 'dart:typed_data';

import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/threads.dart';

final alice = Uint8List(32)..fillRange(0, 32, 1);
final bob = Uint8List(32)..fillRange(0, 32, 2);
final carol = Uint8List(32)..fillRange(0, 32, 3);
var _serial = 0;

Uint8List _utf(String s) => Uint8List.fromList(s.codeUnits);

/// A transaction mined at `height` (or pending with `height: null`), from
/// alice unless `from` says otherwise. A distinct dummy signature gives each
/// a distinct txid.
TxView txAt(TxKind kind, int? height, {String? text, Uint8List? from, Uint8List? to, TxView? reference}) {
  final sig = Uint8List(64)..buffer.asByteData().setUint32(0, ++_serial);
  final content = text == null ? null : saltedContent(_utf(text));
  final tx = Transaction(
    kind: kind,
    from: from ?? alice,
    nonce: _serial,
    to: to,
    amount: kind == TxKind.orphan ? 10 : (kind == TxKind.reply ? 1 : 0),
    fee: 1,
    messageHash: content == null ? null : sha256Bytes(content),
    contentSize: content?.length ?? 0,
    reference: reference?.tx.hash,
    timestamp: 1790208000 + (height ?? 1000),
    pubkey: Uint8List(32),
    signature: sig,
  );
  return TxView(tx, height: height, blockTime: height == null ? null : 1790208000 + height * 2, content: content);
}

/// A reply from `from` (bob unless given) to `parent`, paying its author
/// unless `to` says otherwise.
TxView replyTo(TxView parent, int? height, {Uint8List? from, Uint8List? to, String text = 'reply'}) =>
    txAt(TxKind.reply, height, text: text, from: from ?? bob, to: to ?? parent.tx.from, reference: parent);

/// The index of these, given oldest first (`MessageIndex.build` takes them
/// newest first, as the client has them).
MessageIndex indexOf(List<TxView> oldestFirst) => MessageIndex.build(oldestFirst.reversed.toList());

/// A client that knows exactly the transactions it's given, without a node:
/// what the views read of threads and messages comes from them. It records
/// what it was asked to follow or fetch.
class FakeChain extends MurmurClient {
  FakeChain([List<TxView> oldestFirst = const []]) {
    _set(oldestFirst);
  }

  late MessageIndex _index;
  var _all = <String, TxView>{};

  /// Addresses and thread roots (txids) the views asked to follow, and
  /// transactions they asked the node for.
  final watchedAddresses = <String>{}, watchedThreads = <String>{}, requested = <String>{};

  void _set(List<TxView> oldestFirst) {
    _all = {for (final v in oldestFirst) v.tx.id: v};
    _index = indexOf(oldestFirst);
  }

  /// New blocks arrived: these are known too.
  void add(List<TxView> more) {
    _set([..._all.values, ...more]);
    notifyListeners();
  }

  @override
  Future<void> connect(String host, int port) async {}

  @override
  TxView? lookupTx(String txid) => _all[txid];

  @override
  void requestTx(String txid) => requested.add(txid);

  @override
  void watchAddress(String address) => watchedAddresses.add(address);

  @override
  void watchThread(TxView root, Iterable<TxView> messages) => watchedThreads.add(root.tx.id);

  @override
  List<TxView> repliesOf(TxView v) => _index.repliesOf(v);

  @override
  Iterable<TxView> repliesUnder(TxView v) => _index.repliesUnder(v);

  @override
  int replyCountOf(TxView v) => _index.replyCountOf(v);

  @override
  int flagCountOf(TxView v) => _index.flagCountOf(v);

  @override
  TxView? parentOf(TxView v) => _index.parentOf(v);

  @override
  TxView? threadRootOf(TxView v) => _index.threadRootOf(v);

  @override
  List<TxView> messagesBy(String address) => _index.messagesBy(address);

  @override
  bool selfFlagged(TxView v) => _index.isSelfFlagged(v);
}
