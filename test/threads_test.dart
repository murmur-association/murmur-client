import 'dart:typed_data';

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

  test('a reply is in a thread only if that thread is mined and is a conversation (Section 2.4)', () {
    final root = txAt(TxKind.orphan, 1, text: 'question');
    final good = replyTo(root, 2);
    final pendingRoot = txAt(TxKind.orphan, null, text: 'not mined yet');
    final toPending = replyTo(pendingRoot, 4);
    final name = txAt(TxKind.name, 5, text: '\u0000alias:alice');
    final toName = replyTo(name, 6);
    final ix = indexOf([root, good, name, toName, pendingRoot, toPending]);

    expect(ix.isThreadedReply(good), isTrue);
    expect(ix.isThreadedReply(toPending), isFalse, reason: 'its thread is not on the chain');
    expect(ix.isThreadedReply(toName), isFalse, reason: 'a name is no conversation: the reply is a payment');
    expect(ix.repliesOf(root).map((v) => v.tx.id), [good.tx.id]);
    expect(ix.threads.map((t) => t.root.tx.id), {root.tx.id, pendingRoot.tx.id}, reason: 'a name is never a thread');
  });

  test('threads are flat: a reply to a reply is in the same thread, and bumps it', () {
    final older = txAt(TxKind.orphan, 1, text: 'older');
    final newer = txAt(TxKind.orphan, 2, text: 'newer');
    final reply = replyTo(older, 3);
    final toReply = replyTo(reply, 4, from: alice);
    final pendingReply = replyTo(toReply, null, from: carol);
    final ix = indexOf([older, newer, reply, toReply, pendingReply]);

    // Each names the thread, whichever message it answers.
    expect([reply, toReply, pendingReply].map((v) => v.tx.referenceId), everyElement(older.tx.id));
    expect(ix.threads.first.root.tx.id, older.tx.id);
    expect(ix.threads.first.replies, 3, reason: 'a pending reply in a mined thread counts');
    expect(ix.repliesOf(older).map((v) => v.tx.id), [reply.tx.id, toReply.tx.id, pendingReply.tx.id]);
    expect(ix.repliesOf(reply), isEmpty, reason: 'a reply has none of its own');
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

  test('a flag counts only against a message of the thread it names', () {
    final thread = txAt(TxKind.orphan, 1, text: 'thread');
    final other = txAt(TxKind.orphan, 2, text: 'another thread');
    final reply = replyTo(thread, 3);
    final right = txAt(TxKind.flag, 4, from: carol, reference: reply);
    expect(right.tx.threadId, thread.tx.id, reason: 'a flag of a reply names the reply\'s thread');
    expect(txAt(TxKind.flag, 4, reference: thread).tx.thread, isNull, reason: 'none to name for a first message');
    // The chain takes a flag that names any thread on it: one that names
    // another thread than its target's is valid there, and ignored here.
    final wrong = TxView(
      Transaction(
        kind: TxKind.flag,
        pubkey: Uint8List(32)..fillRange(0, 32, 1),
        nonce: 9,
        fee: 500000,
        reference: reply.tx.hash,
        thread: other.tx.hash,
        signature: Uint8List(64),
      ),
      height: 5,
      blockTime: 1790208010,
    );
    final ix = indexOf([thread, other, reply, right, wrong]);
    expect(ix.flagCountOf(reply), 1);
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

  test('nothing shows that is as old as a block still missing', () {
    // Fetched out of order: the newest blocks, and an old one (a filter
    // match, or the local copy from genesis up). Block 50 isn't in yet.
    final old = txAt(TxKind.orphan, 10, text: 'old, fetched early');
    final recent = txAt(TxKind.orphan, 80, text: 'recent');
    final newest = txAt(TxKind.orphan, 95, text: 'newest');
    final missingBlock = activityTime(txAt(TxKind.orphan, 50));
    final loading = indexOf([old, recent, newest]);
    expect(loading.missingParents, isEmpty);
    final waiting = loading.settledThreads((id) => fail('nothing is missing'), floor: missingBlock);
    expect(ids(waiting.threads), ids([newest, recent]), reason: 'block 50 may hold a reply to the old thread');
    expect(waiting.held, isTrue);

    // It does: the old thread goes above `recent`'s neighbours below, and
    // what showed keeps its place.
    final between = txAt(TxKind.orphan, 50, text: 'in the missing block');
    final loaded = indexOf([old, between, replyTo(old, 50), recent, newest]);
    final all = loaded.settledThreads((id) => fail('nothing is missing'));
    expect(ids(all.threads).take(2), ids(waiting.threads));
    expect(ids(all.threads).skip(2), unorderedEquals(ids([old, between])));
    expect(all.held, isFalse);

    // The later of the two, a waiting reply and a missing block, decides.
    final reply = replyTo(txAt(TxKind.orphan, 5, text: 'not at hand'), 90);
    final both = indexOf([old, recent, reply, newest]).settledThreads((id) => true, floor: missingBlock);
    expect(ids(both.threads), ids([newest]));
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

  test('the wait is counted from the newest reply in the missing thread', () {
    final root = txAt(TxKind.orphan, 10, text: 'root');
    final first = replyTo(root, 60);
    final later = replyTo(first, 90, from: carol);
    final between = txAt(TxKind.orphan, 75, text: 'between the two replies');
    final above = txAt(TxKind.orphan, 95, text: 'above both');
    final ix = indexOf([first, between, later, above]);
    expect(ix.missingParents, {root.tx.id: activityTime(later)});
    expect(ids(ix.settledThreads((id) => true).threads), ids([above]));

    // With the first reply missing too, the later one still names its
    // thread: a reply never waits for another reply.
    final without = indexOf([between, later, above]);
    expect(without.missingParents, {root.tx.id: activityTime(later)});
  });

  test('a reply that is a payment (Section 2.4) leads to no thread, and holds nothing', () {
    final name = txAt(TxKind.name, 10, text: '\u0000alias:alice');
    final payment = replyTo(name, 90);
    final thread = txAt(TxKind.orphan, 70, text: 'thread');
    final ix = indexOf([name, thread, payment]);
    expect(ix.missingParents, isEmpty);
    expect(ids(ix.settledThreads((id) => true).threads), ids([thread]));

    // Flags and transfers that reference something missing don't either.
    final root = txAt(TxKind.orphan, 10, text: 'root');
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

  test('a thread and its reply in one block, beside a reply to an old thread: the old one waits its turn', () {
    final old = txAt(TxKind.orphan, 10, text: 'old');
    final fresh = txAt(TxKind.orphan, 90, text: 'new, answered in its own block');
    final toFresh = replyTo(fresh, 90);
    final toOld = replyTo(old, 90);
    final below = txAt(TxKind.orphan, 80, text: 'below');

    // Block 90 alone: all three threads are active at its time, so even the
    // new one, complete with its reply, can't show before the old one.
    final waiting = indexOf([below, fresh, toFresh, toOld]).settledThreads((id) => true);
    expect(waiting.threads, isEmpty);
    expect(waiting.held, isTrue);

    // Same time: the one started later first.
    final all = indexOf([old, below, fresh, toFresh, toOld]);
    expect(ids(all.settledThreads((id) => true).threads), ids([fresh, old, below]));
    expect(all.threads.first.replies, 1);
  });

  test('however the chain is loaded, the list only grows at its end, and ends the same', () {
    // Threads answered in their own block, replies to older threads beside
    // new threads in one block, and a reply to a reply.
    final a = txAt(TxKind.orphan, 5, text: 'a');
    final b = txAt(TxKind.orphan, 10, text: 'b');
    final c = txAt(TxKind.orphan, 20, text: 'c, answered in its block');
    final toC = replyTo(c, 20);
    final d = txAt(TxKind.orphan, 30, text: 'd');
    final toA = replyTo(a, 40);
    final e = txAt(TxKind.orphan, 50, text: 'e, answered in its block');
    final toE = replyTo(e, 50);
    final toB = replyTo(b, 50);
    final f = txAt(TxKind.orphan, 60, text: 'f');
    final underC = replyTo(toC, 70, from: carol);
    final g = txAt(TxKind.orphan, 80, text: 'g');
    final toD = replyTo(d, 80);
    final h = txAt(TxKind.orphan, 90, text: 'h');
    final chain = [a, b, c, toC, d, toA, e, toE, toB, f, underC, g, toD, h];
    final heights = {for (final v in chain) v.height!}.toList()..sort();
    final timeOf = {for (final v in chain) v.height!: v.blockTime!};
    final byId = {for (final v in chain) v.tx.id: v};
    final expected = ids(indexOf(chain).threads);

    /// Loads blocks in `order`. With `askById`, each missing parent arrives
    /// alone (GetTx) one step after the reply that names it; otherwise only
    /// with its block.
    void load(List<int> order, {required bool askById}) {
      final blocks = <int>{}, loose = <String>{};
      var listed = <String>[];
      void check(String step) {
        final known = [
          for (final v in chain)
            if (blocks.contains(v.height) || loose.contains(v.tx.id)) v,
        ];
        final ix = indexOf(known);
        final missing = heights.where((at) => !blocks.contains(at));
        final floor = missing.isEmpty ? null : timeOf[missing.last];
        final now = ids(ix.settledThreads((id) => true, floor: floor).threads);
        expect(now.take(listed.length), listed, reason: 'a listed thread moved after $step ($order)');
        listed = now;
        if (askById) loose.addAll(ix.missingParents.keys.where(byId.containsKey));
      }

      for (final height in order) {
        blocks.add(height);
        check('block $height');
        check('what block $height referenced');
        check('what that referenced');
      }
      expect(listed, expected, reason: 'loaded as $order');
    }

    for (final askById in [true, false]) {
      load(heights.reversed.toList(), askById: askById); // newest first, as the list asks
      load(heights, askById: askById); // oldest first, as the local copy fills
      load([90, 5, 80, 20, 50, 10, 70, 40, 60, 30], askById: askById); // newest first with filter matches between
      load([50, 90, 20, 80, 70, 5, 60, 10, 40, 30], askById: askById);
    }
  });

  test('a pending reply comes after the mined ones, even when a block is dated ahead of the clock', () {
    final thread = txAt(TxKind.orphan, 1, text: 'thread');
    // Mined in a block dated far ahead of now, as a fast chain's can be.
    final mined = replyTo(thread, 400000000, text: 'mined');
    final pending = replyTo(thread, null, text: 'pending');
    final ix = indexOf([thread, pending, mined]);
    expect([for (final r in ix.repliesOf(ix.threads.single.root)) r.tx.id], [mined.tx.id, pending.tx.id]);
  });
}
