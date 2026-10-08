// Thread structure over messages: which thread a reply is in, reply and
// flag counts, and each thread's latest activity.
//
// Threads are flat (PROTOCOL.md Section 2.4): a thread is an Orphan and
// every Reply whose `reference` is that Orphan's txid. A Reply names its
// thread, not the message it answers, and consensus refuses one whose thread
// isn't on the chain. What is left to clients:
// - a Flag counts against its target only if the target is a message of the
//   thread the Flag names;
// - a Name is a thread's first message only so that it can be flagged: it's
//   never shown as a thread, and a Reply that names it is just a payment;
// - a message whose first byte is 0x00 isn't text, and starts no thread.
// Every client applying these rules to the same chain gets the same threads.

import 'dart:math';

import '../protocol/alias.dart';
import '../protocol/models.dart';
import 'node_client.dart' show TxView;

/// When a message happened, for ordering: its block's time once mined (a
/// transaction carries none of its own), and when this client first saw it
/// while pending.
int activityTime(TxView v) => v.blockTime ?? (v.pending?.seenAt.millisecondsSinceEpoch ?? 0) ~/ 1000;

/// Whether a message is known not to be text (Section 2.4: its first byte
/// is 0x00, as in a name's). Content not at hand yet counts as text until it
/// arrives.
bool isNonTextMessage(TxView v) => v.content != null && isNonText(messageOf(v.content!));

/// A thread (an Orphan) with its activity summary.
class ThreadSummary {
  ThreadSummary(this.root, {required this.lastActivity, required this.replies, required this.flags});

  final TxView root;

  /// Newest time among the root and all its replies.
  final int lastActivity;

  /// Replies in the thread.
  final int replies;

  /// Flags on the root message.
  final int flags;
}

class MessageIndex {
  MessageIndex._();

  /// Every Orphan, Reply and Name, chain and pending.
  final _byTxid = <String, TxView>{};

  /// Reply txid -> its thread's txid, for replies in a thread that shows.
  final _threadOf = <String, String>{};

  /// Thread txid -> its replies, oldest first.
  final _replies = <String, List<TxView>>{};

  /// Flagged txid -> distinct flagging addresses.
  final _flaggers = <String, Set<String>>{};

  /// Author -> their Orphans and Replies, newest first.
  final _byAuthor = <String, List<TxView>>{};

  /// Most recently active first.
  final threads = <ThreadSummary>[];

  /// Threads that replies name and that aren't known: each with the time of
  /// the newest such reply. One of these may be an older thread that a reply
  /// has just made the most recently active; where it belongs in [threads]
  /// isn't known until it's fetched.
  final missingParents = <String, int>{};

  /// Builds the index from every known transaction, newest first (the order
  /// `MurmurClient.transactions` returns: pending, then the chain from the
  /// tip down).
  factory MessageIndex.build(List<TxView> newestFirst) {
    final ix = MessageIndex._();
    final oldestFirst = newestFirst.reversed.toList();
    for (final v in oldestFirst) {
      if (v.tx.kind.hasMessage) ix._byTxid[v.tx.id] = v;
    }
    for (final v in newestFirst) {
      if (v.tx.kind == TxKind.orphan || v.tx.kind == TxKind.reply) {
        ix._byAuthor.putIfAbsent(v.tx.fromAddress, () => []).add(v);
      }
    }

    // In the order given, so a block's replies keep their order in it when
    // sorted by time below.
    final position = <String, int>{};
    for (final v in oldestFirst) {
      final ref = v.tx.referenceId;
      if (ref == null) continue;
      final target = ix._byTxid[ref];
      switch (v.tx.kind) {
        case TxKind.reply:
          if (target == null) {
            final t = activityTime(v);
            if (t > (ix.missingParents[ref] ?? -1)) ix.missingParents[ref] = t;
          } else if (target.tx.kind == TxKind.orphan && target.confirmed && !isNonTextMessage(target)) {
            // Anything else it names (a Name, a message that isn't text) is
            // no conversation: the reply is a payment.
            ix._threadOf[v.tx.id] = ref;
            position[v.tx.id] = position.length;
            ix._replies.putIfAbsent(ref, () => []).add(v);
          }
        case TxKind.flag:
          // Only against a message of the thread the flag names. A pending
          // flag may duplicate a mined one; count each address once.
          if (target != null && target.tx.threadId == v.tx.threadId) {
            ix._flaggers.putIfAbsent(ref, () => {}).add(v.tx.fromAddress);
          }
        case TxKind.orphan || TxKind.raw || TxKind.name:
          break;
      }
    }
    for (final list in ix._replies.values) {
      list.sort((a, b) {
        final byTime = activityTime(a).compareTo(activityTime(b));
        return byTime != 0 ? byTime : position[a.tx.id]!.compareTo(position[b.tx.id]!);
      });
    }

    for (final v in ix._byTxid.values) {
      if (v.tx.kind != TxKind.orphan || isNonTextMessage(v)) continue;
      final replies = ix.repliesOf(v);
      var last = activityTime(v);
      for (final r in replies) {
        last = max(last, activityTime(r));
      }
      ix.threads.add(ThreadSummary(v, lastActivity: last, replies: replies.length, flags: ix.flagCountOf(v)));
    }
    // Ties (a block's messages share its time) are settled by the threads
    // themselves, never by the order they arrived in: the list must come
    // out the same however it was loaded.
    ix.threads.sort((a, b) {
      final byActivity = b.lastActivity.compareTo(a.lastActivity);
      if (byActivity != 0) return byActivity;
      final byStart = activityTime(b.root).compareTo(activityTime(a.root));
      return byStart != 0 ? byStart : a.root.tx.id.compareTo(b.root.tx.id);
    });
    return ix;
  }

  /// [threads] as far as their order is settled: most recently active
  /// first, stopping where something not at hand yet could still take a
  /// place. Two things reserve one:
  /// - a reply whose thread is missing but `stillComing` (asked of the node,
  ///   not answered yet): that thread belongs at the reply's time;
  /// - `floor`, the time of the newest block not fetched yet, if any: its
  ///   threads belong there, and so may a thread already at hand that a
  ///   reply in it will bump.
  ///
  /// Showing anything less recent now would only have it pushed down, or
  /// moved up, later. `held` says whether any threads are held back.
  ({List<ThreadSummary> threads, bool held}) settledThreads(bool Function(String txid) stillComing, {int? floor}) {
    var hold = floor ?? -1;
    missingParents.forEach((txid, time) {
      if (time > hold && stillComing(txid)) hold = time;
    });
    if (hold < 0) return (threads: threads, held: false);
    // Threads more recent than that are in their place already. (One of the
    // same time isn't: what's missing may sort before it.)
    final settled = [
      for (final t in threads)
        if (t.lastActivity > hold) t,
    ];
    return (threads: settled, held: settled.length < threads.length);
  }

  /// A thread's replies, oldest first. A reply has none of its own: threads
  /// are flat.
  List<TxView> repliesOf(TxView v) => _replies[v.tx.id] ?? const [];

  int replyCountOf(TxView v) => repliesOf(v).length;

  /// The threads and replies `address` wrote, among what's known, newest
  /// first.
  List<TxView> messagesBy(String address) => _byAuthor[address] ?? const [];

  int flagCountOf(TxView v) => _flaggers[v.tx.id]?.length ?? 0;

  /// Whether the message's own author flagged it: withdrawn.
  bool isSelfFlagged(TxView v) => _flaggers[v.tx.id]?.contains(v.tx.fromAddress) ?? false;

  /// Whether a Reply is in a thread that shows; if not, it's a payment.
  bool isThreadedReply(TxView v) => _threadOf.containsKey(v.tx.id);

  /// The thread a message is in: itself for an Orphan, a Reply's thread
  /// when it shows, or null.
  TxView? threadRootOf(TxView v) {
    if (v.tx.kind == TxKind.orphan) return v;
    final thread = _threadOf[v.tx.id];
    return thread == null ? null : _byTxid[thread];
  }
}
