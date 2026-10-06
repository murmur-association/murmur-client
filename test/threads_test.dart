import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/threads.dart';

final _alice = Uint8List(32)..fillRange(0, 32, 1);
final _bob = Uint8List(32)..fillRange(0, 32, 2);
final _carol = Uint8List(32)..fillRange(0, 32, 3);
var _serial = 0;

Uint8List _utf(String s) => Uint8List.fromList(s.codeUnits);

/// A message mined at `height` (or pending with `height: null`). Signatures
/// aren't checked by the index, so a distinct dummy one per transaction gives
/// each a distinct txid.
TxView _tx(TxKind kind, int? height,
    {String? text, Uint8List? from, Uint8List? to, TxView? reference}) {
  final sig = Uint8List(64)..buffer.asByteData().setUint32(0, ++_serial);
  final content = text == null ? null : saltedContent(_utf(text));
  final tx = Transaction(
    kind: kind,
    from: from ?? _alice,
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

/// A reply from `from` to `parent`, paying its author unless `to` says otherwise.
TxView _reply(TxView parent, int? height, {Uint8List? from, Uint8List? to}) =>
    _tx(TxKind.reply, height, text: 'reply', from: from ?? _bob, to: to ?? parent.tx.from, reference: parent);

/// Newest first, as MurmurClient.transactions returns them.
MessageIndex _index(List<TxView> oldestFirst) => MessageIndex.build(oldestFirst.reversed.toList());

void main() {
  group('settled order', _settledOrder);

  test('a thread flagged by its own author is withdrawn; anyone else\'s flag is just a flag', () {
    final withdrawn = _tx(TxKind.orphan, 1, text: 'take this back');
    final flaggedByOthers = _tx(TxKind.orphan, 2, text: 'contested');
    final ix = _index([
      withdrawn,
      flaggedByOthers,
      _tx(TxKind.flag, 3, reference: withdrawn), // from its author, alice
      _tx(TxKind.flag, 4, from: _bob, reference: flaggedByOthers),
    ]);
    expect(ix.isSelfFlagged(withdrawn), isTrue);
    expect(ix.isSelfFlagged(flaggedByOthers), isFalse);
    expect(ix.flagCountOf(flaggedByOthers), 1);
  });

  test('a message whose first byte is 0x00 is no thread, and a reply to it is a payment (Section 2.4)', () {
    final alias = _tx(TxKind.orphan, 1, text: '\u0000alias:bob');
    final reply = _reply(alias, 2);
    final ix = _index([alias, reply]);
    expect(isNonTextMessage(alias), isTrue);
    expect(ix.threads, isEmpty);
    expect(ix.isThreadedReply(reply), isFalse);
  });

  test('threads with identical text are separate, and so are their replies', () {
    final first = _tx(TxKind.orphan, 1, text: 'hello');
    final second = _tx(TxKind.orphan, 2, text: 'hello');
    final reply = _reply(second, 3);
    final ix = _index([first, second, reply]);

    expect(ix.threads.map((t) => t.root.tx.id), [second.tx.id, first.tx.id]);
    expect((ix.replyCountOf(first), ix.replyCountOf(second)), (0, 1));
    expect(ix.threadRootOf(reply)!.tx.id, second.tx.id);
  });

  test('a reply counts only if it pays a mined parent message\'s author (Section 2.4)', () {
    final root = _tx(TxKind.orphan, 1, text: 'question');
    final good = _reply(root, 2);
    final wrongPayee = _reply(root, 3, to: _carol);
    final pendingRoot = _tx(TxKind.orphan, null, text: 'not mined yet');
    final toPending = _reply(pendingRoot, 4);
    final transfer = _tx(TxKind.raw, 5, to: _alice);
    final toTransfer = _reply(transfer, 6);
    final ix = _index([root, good, wrongPayee, transfer, toTransfer, pendingRoot, toPending]);

    expect(ix.isThreadedReply(good), isTrue);
    expect(ix.isThreadedReply(wrongPayee), isFalse, reason: 'pays someone other than the author');
    expect(ix.isThreadedReply(toPending), isFalse, reason: 'parent not on the chain');
    expect(ix.isThreadedReply(toTransfer), isFalse, reason: 'parent is not a message');
    expect(ix.repliesOf(root).map((v) => v.tx.id), [good.tx.id]);
  });

  test('replies nest and bump their thread', () {
    final older = _tx(TxKind.orphan, 1, text: 'older');
    final newer = _tx(TxKind.orphan, 2, text: 'newer');
    final reply = _reply(older, 3);
    final nested = _reply(reply, 4, from: _alice);
    final pendingReply = _reply(nested, null, from: _carol);
    final ix = _index([older, newer, reply, nested, pendingReply]);

    expect(ix.threads.first.root.tx.id, older.tx.id);
    expect(ix.threads.first.replies, 3, reason: 'a pending reply to a mined message counts');
    expect(ix.threadRootOf(pendingReply)!.tx.id, older.tx.id);
  });

  test('flags count per message by txid, once per address, and only on messages', () {
    final first = _tx(TxKind.orphan, 1, text: 'spam');
    final second = _tx(TxKind.orphan, 2, text: 'spam');
    final transfer = _tx(TxKind.raw, 3, to: _bob);
    final ix = _index([
      first,
      second,
      transfer,
      _tx(TxKind.flag, 4, reference: first),
      _tx(TxKind.flag, 5, reference: first, from: _bob),
      _tx(TxKind.flag, null, reference: first, from: _bob), // pending duplicate of a mined flag
      _tx(TxKind.flag, 6, reference: transfer),
    ]);

    expect((ix.flagCountOf(first), ix.flagCountOf(second)), (2, 0));
    expect(ix.threads.map((t) => t.flags), [0, 2]);
    expect(ix.threads, hasLength(2), reason: 'flags and transfers are not threads');
  });
}

/// The Threads tab's list while blocks arrive newest first: a thread never
/// shows before a more recently active one that's still on its way.
void _settledOrder() {
  /// Root txids, of threads or of their root messages.
  List<String> ids(Iterable<Object> threads) =>
      [for (final t in threads) t is ThreadSummary ? t.root.tx.id : (t as TxView).tx.id];

  test('threads less recent than a reply whose thread is still coming wait for it', () {
    final old = _tx(TxKind.orphan, 10, text: 'old, replied to lately');
    final newest = _tx(TxKind.orphan, 95, text: 'newest');
    final recent = _tx(TxKind.orphan, 80, text: 'recent');
    final older = _tx(TxKind.orphan, 70, text: 'older');
    final reply = _reply(old, 90);

    // Blocks 70 and up are in; the reply's thread, from block 10, isn't.
    final loading = _index([older, recent, reply, newest]);
    expect(loading.missingParents, {old.tx.id: activityTime(reply)});
    expect(ids(loading.threads), ids([newest, recent, older]));
    final waiting = loading.settledThreads((id) => id == old.tx.id);
    expect(ids(waiting.threads), ids([newest]), reason: 'only what is more recent than the reply');
    expect(waiting.held, isTrue);

    // It arrives (asked for by id): everything shows, the old thread second.
    final loaded = _index([old, older, recent, reply, newest]);
    expect(loaded.missingParents, isEmpty);
    final all = loaded.settledThreads((id) => fail('nothing is missing'));
    expect(ids(all.threads), ids([newest, old, recent, older]));
    expect(all.held, isFalse);
    // What showed before kept its place: nothing was pushed down.
    expect(ids(all.threads).take(waiting.threads.length), ids(waiting.threads));
  });

  test('a missing thread that is not coming holds nothing back', () {
    final thread = _tx(TxKind.orphan, 70, text: 'here');
    final unknown = _tx(TxKind.orphan, 10, text: 'the node does not have it');
    final ix = _index([thread, _reply(unknown, 90)]);
    expect(ix.missingParents, hasLength(1));
    final settled = ix.settledThreads((id) => false);
    expect(ids(settled.threads), ids([thread]));
    expect(settled.held, isFalse);
  });

  test('the wait is counted from the newest reply under the missing message, through nested replies', () {
    final root = _tx(TxKind.orphan, 10, text: 'root');
    final first = _reply(root, 60);
    final nested = _reply(first, 90, from: _carol);
    final between = _tx(TxKind.orphan, 75, text: 'between the two replies');
    final above = _tx(TxKind.orphan, 95, text: 'above both');
    final ix = _index([first, between, nested, above]);
    expect(ix.missingParents, {root.tx.id: activityTime(nested)});
    expect(ids(ix.settledThreads((id) => true).threads), ids([above]));

    // With the first reply missing too, its own parent can't be known yet:
    // the nested reply waits for the first.
    final deeper = _index([between, nested, above]);
    expect(deeper.missingParents, {first.tx.id: activityTime(nested)});
  });

  test('a reply that is a payment (Section 2.4) leads to no thread, and holds nothing', () {
    final root = _tx(TxKind.orphan, 10, text: 'root');
    final wrongPayee = _reply(root, 50, to: _carol); // known parent, not paid: a payment
    final under = _reply(wrongPayee, 90); // a reply to that payment
    final thread = _tx(TxKind.orphan, 70, text: 'thread');
    final ix = _index([root, wrongPayee, thread, under]);
    expect(ix.missingParents, isEmpty);
    expect(ids(ix.settledThreads((id) => true).threads), ids([thread, root]));

    // Flags and transfers that reference something missing don't either.
    final flagged = _index([thread, _tx(TxKind.flag, 90, from: _bob, reference: root)]);
    expect(flagged.missingParents, isEmpty);
  });

  test('a thread of the same time as the waiting reply waits too, and ties never depend on arrival order', () {
    final old = _tx(TxKind.orphan, 10, text: 'old');
    final sameBlock = _tx(TxKind.orphan, 90, text: 'in the reply\'s block');
    final reply = _reply(old, 90);
    final waiting = _index([sameBlock, reply]).settledThreads((id) => true);
    expect(waiting.threads, isEmpty, reason: 'the missing thread may sort before it');
    expect(waiting.held, isTrue);

    // Same activity time: the thread started later first, then by txid.
    // Whatever order they were loaded in (a thread fetched by id comes
    // after the blocks'), the list is the same.
    final twin = _tx(TxKind.orphan, 90, text: 'same block again');
    final twins = [sameBlock, twin]..sort((a, b) => a.tx.id.compareTo(b.tx.id));
    final expected = ids([...twins, old]);
    for (final arrival in [
      [old, sameBlock, twin, reply],
      [twin, reply, sameBlock, old],
      [reply, old, twin, sameBlock],
    ]) {
      expect(ids(MessageIndex.build(arrival).threads), expected);
    }
  });
}
