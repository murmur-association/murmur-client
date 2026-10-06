// Thread rules (lib/services/threads.dart): which reply answers which
// message under PROTOCOL.md Section 2.4, counts, and the list's order.

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/threads.dart';

import 'support/messages.dart';

void main() {
  group('settled order', _settledOrder);

  test('a thread flagged by its own author is withdrawn; anyone else\'s flag is just a flag', () {
    final withdrawn = txAt(TxKind.orphan, 1, text: 'take this back');
    final flaggedByOthers = txAt(TxKind.orphan, 2, text: 'contested');
    final ix = indexOf([
      withdrawn,
      flaggedByOthers,
      txAt(TxKind.flag, 3, reference: withdrawn), // from its author, alice
      txAt(TxKind.flag, 4, from: bob, reference: flaggedByOthers),
    ]);
    expect(ix.isSelfFlagged(withdrawn), isTrue);
    expect(ix.isSelfFlagged(flaggedByOthers), isFalse);
    expect(ix.flagCountOf(flaggedByOthers), 1);
  });

  test('a message whose first byte is 0x00 is no thread, and a reply to it is a payment (Section 2.4)', () {
    final alias = txAt(TxKind.orphan, 1, text: '\u0000alias:bob');
    final reply = replyTo(alias, 2);
    final ix = indexOf([alias, reply]);
    expect(isNonTextMessage(alias), isTrue);
    expect(ix.threads, isEmpty);
    expect(ix.isThreadedReply(reply), isFalse);
  });

  test('threads with identical text are separate, and so are their replies', () {
    final first = txAt(TxKind.orphan, 1, text: 'hello');
    final second = txAt(TxKind.orphan, 2, text: 'hello');
    final reply = replyTo(second, 3);
    final ix = indexOf([first, second, reply]);

    expect(ix.threads.map((t) => t.root.tx.id), [second.tx.id, first.tx.id]);
    expect((ix.replyCountOf(first), ix.replyCountOf(second)), (0, 1));
    expect(ix.threadRootOf(reply)!.tx.id, second.tx.id);
  });

  test('a reply counts only if it pays a mined parent message\'s author (Section 2.4)', () {
    final root = txAt(TxKind.orphan, 1, text: 'question');
    final good = replyTo(root, 2);
    final wrongPayee = replyTo(root, 3, to: carol);
    final pendingRoot = txAt(TxKind.orphan, null, text: 'not mined yet');
    final toPending = replyTo(pendingRoot, 4);
    final transfer = txAt(TxKind.raw, 5, to: alice);
    final toTransfer = replyTo(transfer, 6);
    final ix = indexOf([root, good, wrongPayee, transfer, toTransfer, pendingRoot, toPending]);

    expect(ix.isThreadedReply(good), isTrue);
    expect(ix.isThreadedReply(wrongPayee), isFalse, reason: 'pays someone other than the author');
    expect(ix.isThreadedReply(toPending), isFalse, reason: 'parent not on the chain');
    expect(ix.isThreadedReply(toTransfer), isFalse, reason: 'parent is not a message');
    expect(ix.repliesOf(root).map((v) => v.tx.id), [good.tx.id]);
  });

  test('replies nest and bump their thread', () {
    final older = txAt(TxKind.orphan, 1, text: 'older');
    final newer = txAt(TxKind.orphan, 2, text: 'newer');
    final reply = replyTo(older, 3);
    final nested = replyTo(reply, 4, from: alice);
    final pendingReply = replyTo(nested, null, from: carol);
    final ix = indexOf([older, newer, reply, nested, pendingReply]);

    expect(ix.threads.first.root.tx.id, older.tx.id);
    expect(ix.threads.first.replies, 3, reason: 'a pending reply to a mined message counts');
    expect(ix.threadRootOf(pendingReply)!.tx.id, older.tx.id);
  });

  test('flags count per message by txid, once per address, and only on messages', () {
    final first = txAt(TxKind.orphan, 1, text: 'spam');
    final second = txAt(TxKind.orphan, 2, text: 'spam');
    final transfer = txAt(TxKind.raw, 3, to: bob);
    final ix = indexOf([
      first,
      second,
      transfer,
      txAt(TxKind.flag, 4, reference: first),
      txAt(TxKind.flag, 5, reference: first, from: bob),
      txAt(TxKind.flag, null, reference: first, from: bob), // pending duplicate of a mined flag
      txAt(TxKind.flag, 6, reference: transfer),
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
    final old = txAt(TxKind.orphan, 10, text: 'old, replied to lately');
    final newest = txAt(TxKind.orphan, 95, text: 'newest');
    final recent = txAt(TxKind.orphan, 80, text: 'recent');
    final older = txAt(TxKind.orphan, 70, text: 'older');
    final reply = replyTo(old, 90);

    // Blocks 70 and up are in; the reply's thread, from block 10, isn't.
    final loading = indexOf([older, recent, reply, newest]);
    expect(loading.missingParents, {old.tx.id: activityTime(reply)});
    expect(ids(loading.threads), ids([newest, recent, older]));
    final waiting = loading.settledThreads((id) => id == old.tx.id);
    expect(ids(waiting.threads), ids([newest]), reason: 'only what is more recent than the reply');
    expect(waiting.held, isTrue);

    // It arrives (asked for by id): everything shows, the old thread second.
    final loaded = indexOf([old, older, recent, reply, newest]);
    expect(loaded.missingParents, isEmpty);
    final all = loaded.settledThreads((id) => fail('nothing is missing'));
    expect(ids(all.threads), ids([newest, old, recent, older]));
    expect(all.held, isFalse);
    // What showed before kept its place: nothing was pushed down.
    expect(ids(all.threads).take(waiting.threads.length), ids(waiting.threads));
  });

  test('a missing thread that is not coming holds nothing back', () {
    final thread = txAt(TxKind.orphan, 70, text: 'here');
    final unknown = txAt(TxKind.orphan, 10, text: 'the node does not have it');
    final ix = indexOf([thread, replyTo(unknown, 90)]);
    expect(ix.missingParents, hasLength(1));
    final settled = ix.settledThreads((id) => false);
    expect(ids(settled.threads), ids([thread]));
    expect(settled.held, isFalse);
  });

  test('the wait is counted from the newest reply under the missing message, through nested replies', () {
    final root = txAt(TxKind.orphan, 10, text: 'root');
    final first = replyTo(root, 60);
    final nested = replyTo(first, 90, from: carol);
    final between = txAt(TxKind.orphan, 75, text: 'between the two replies');
    final above = txAt(TxKind.orphan, 95, text: 'above both');
    final ix = indexOf([first, between, nested, above]);
    expect(ix.missingParents, {root.tx.id: activityTime(nested)});
    expect(ids(ix.settledThreads((id) => true).threads), ids([above]));

    // With the first reply missing too, its own parent can't be known yet:
    // the nested reply waits for the first.
    final deeper = indexOf([between, nested, above]);
    expect(deeper.missingParents, {first.tx.id: activityTime(nested)});
  });

  test('a reply that is a payment (Section 2.4) leads to no thread, and holds nothing', () {
    final root = txAt(TxKind.orphan, 10, text: 'root');
    final wrongPayee = replyTo(root, 50, to: carol); // known parent, not paid: a payment
    final under = replyTo(wrongPayee, 90); // a reply to that payment
    final thread = txAt(TxKind.orphan, 70, text: 'thread');
    final ix = indexOf([root, wrongPayee, thread, under]);
    expect(ix.missingParents, isEmpty);
    expect(ids(ix.settledThreads((id) => true).threads), ids([thread, root]));

    // Flags and transfers that reference something missing don't either.
    final flagged = indexOf([thread, txAt(TxKind.flag, 90, from: bob, reference: root)]);
    expect(flagged.missingParents, isEmpty);
  });

  test('a thread of the same time as the waiting reply waits too, and ties never depend on arrival order', () {
    final old = txAt(TxKind.orphan, 10, text: 'old');
    final sameBlock = txAt(TxKind.orphan, 90, text: 'in the reply\'s block');
    final reply = replyTo(old, 90);
    final waiting = indexOf([sameBlock, reply]).settledThreads((id) => true);
    expect(waiting.threads, isEmpty, reason: 'the missing thread may sort before it');
    expect(waiting.held, isTrue);

    // Same activity time: the thread started later first, then by txid.
    // Whatever order they were loaded in (a thread fetched by id comes
    // after the blocks'), the list is the same.
    final twin = txAt(TxKind.orphan, 90, text: 'same block again');
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
