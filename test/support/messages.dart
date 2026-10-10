// Messages made by hand, for tests of what's built over them: threads, and
// what's starred. Signatures aren't checked there, so none is real.

import 'dart:typed_data';

import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/threads.dart';

final _keys = <String, Uint8List>{};

/// An address for tests: that of a made-up public key, `seed` repeated. A
/// transaction doesn't write its sender, which is the address of its key,
/// so the helpers below find the key again from the address.
Uint8List person(int seed) {
  final key = Uint8List(32)..fillRange(0, 32, seed);
  final address = sha256Bytes(key);
  _keys[toHex(address)] = key;
  return address;
}

final alice = person(1);
final bob = person(2);
final carol = person(3);
var _serial = 0;

Uint8List _utf(String s) => Uint8List.fromList(s.codeUnits);

/// A transaction mined at `height` (or pending with `height: null`), from
/// alice unless `from` says otherwise. A distinct dummy signature gives each
/// a distinct txid. A Reply's `reference` is any message of its thread: the
/// reply names the thread, as replies do. A Flag's is its target.
TxView txAt(TxKind kind, int? height, {String? text, Uint8List? from, Uint8List? to, TxView? reference}) {
  final sig = Uint8List(64)..buffer.asByteData().setUint32(0, ++_serial);
  final content = text == null ? null : saltedContent(_utf(text));
  final thread = reference?.tx.threadId;
  final tx = Transaction(
    kind: kind,
    pubkey: _keys[toHex(from ?? alice)]!,
    nonce: _serial,
    to: to,
    amount: 1000000,
    fee: 500000,
    messageHash: content == null ? null : sha256Bytes(content),
    contentSize: content?.length ?? 0,
    reference: kind == TxKind.reply ? fromHex(thread!) : reference?.tx.hash,
    thread: kind == TxKind.flag && thread != null && thread != reference!.tx.id ? fromHex(thread) : null,
    signature: sig,
  );
  final pending = height == null ? PendingTx(tx, content, mine: false) : null;
  return TxView(tx,
      height: height, blockTime: height == null ? null : 1790208000 + height * 2, content: content, pending: pending);
}

/// A reply from `from` (bob unless given) in the thread of `message`.
TxView replyTo(TxView message, int? height, {Uint8List? from, String text = 'reply'}) =>
    txAt(TxKind.reply, height, text: text, from: from ?? bob, reference: message);

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
  void watchAddress(String address, {bool mentions = false}) => watchedAddresses.add(address);

  @override
  void watchThread(TxView root, Iterable<TxView> messages) => watchedThreads.add(root.tx.id);

  /// Threads (txids) of which only the newest replies are at hand, and how
  /// often a page before them was asked for.
  final partly = <String>{};
  var earlierAsked = 0;

  @override
  bool threadHasEarlier(String root) => partly.contains(root);

  @override
  bool threadReading(String root) => false;

  @override
  void readEarlier(String root) => earlierAsked++;

  @override
  List<TxView> repliesOf(TxView v) => _index.repliesOf(v);

  @override
  int replyCountOf(TxView v) => _index.replyCountOf(v);

  @override
  int flagCountOf(TxView v) => _index.flagCountOf(v);

  @override
  TxView? threadRootOf(TxView v) => _index.threadRootOf(v);

  @override
  List<TxView> messagesBy(String address) => _index.messagesBy(address);

  @override
  bool selfFlagged(TxView v) => _index.isSelfFlagged(v);
}
