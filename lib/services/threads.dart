// Thread structure over messages: which reply answers which message, reply
// and flag counts, and each thread's latest activity.
//
// Replies and flags name their target by txid (`reference`). Consensus never
// looks it up, so clients apply PROTOCOL.md Section 2.4:
// - a Reply is a reply to its reference only if that transaction is on the
//   chain, is an Orphan or a Reply, and its `from` equals the Reply's `to`.
//   Otherwise the Reply is just a payment, outside any thread;
// - a Flag counts against its reference only if that is an Orphan or Reply.
// Every client applying these rules to the same chain gets the same threads.

import 'dart:math';

import '../protocol/alias.dart';
import '../protocol/models.dart';
import 'node_client.dart' show TxView;

/// When a message happened, for ordering: block time once mined, signing
/// time while pending.
int activityTime(TxView v) => v.blockTime ?? v.tx.timestamp;

bool _isMessage(TxView v) => v.tx.kind == TxKind.orphan || v.tx.kind == TxKind.reply;

/// Whether a message is known not to be text (Section 2.4: its first byte
/// is 0x00, as in aliases). Content not at hand yet counts as text until it
/// arrives.
bool isNonTextMessage(TxView v) => v.content != null && isNonText(messageOf(v.content!));

/// A thread (an Orphan) with its activity summary.
class ThreadSummary {
  ThreadSummary(this.root, {required this.lastActivity, required this.replies, required this.flags});

  final TxView root;

  /// Newest time among the root and all its replies.
  final int lastActivity;

  /// Replies anywhere in the thread, at any depth.
  final int replies;

  /// Flags on the root message.
  final int flags;
}

class MessageIndex {
  MessageIndex._();

  /// Every Orphan and Reply, chain and pending.
  final _byTxid = <String, TxView>{};

  /// Reply txid -> parent txid, for replies that pass the Section 2.4 check.
  final _parentOf = <String, String>{};

  /// Parent txid -> its valid direct replies, oldest first.
  final _children = <String, List<TxView>>{};

  /// Flagged txid -> distinct flagging addresses.
  final _flaggers = <String, Set<String>>{};

  /// Sender -> its mined Orphans of the alias length, latest first.
  final _aliasCandidates = <String, List<TxView>>{};

  /// Author -> their Orphans and Replies, newest first.
  final _byAuthor = <String, List<TxView>>{};

  /// Most recently active first.
  final threads = <ThreadSummary>[];

  /// Messages that replies point to (directly, or up a chain of replies)
  /// and that aren't known: each with the time of the newest reply under
  /// it. One of these may be an older thread that such a reply has just
  /// made the most recently active; where it belongs in [threads] isn't
  /// known until it's fetched.
  final missingParents = <String, int>{};

  /// `address`'s possible alias transactions (Section 7.8) among what's
  /// known, latest first: mined Orphans with `content_size` 87.
  List<TxView> aliasCandidatesOf(String address) => _aliasCandidates[address] ?? const [];

  /// Builds the index from every known transaction, newest first (the order
  /// `MurmurClient.transactions` returns: pending, then the chain from the
  /// tip down).
  factory MessageIndex.build(List<TxView> newestFirst) {
    final ix = MessageIndex._();
    final oldestFirst = newestFirst.reversed.toList();
    for (final v in oldestFirst) {
      if (_isMessage(v)) ix._byTxid[v.tx.id] = v;
    }
    for (final v in newestFirst) {
      if (_isMessage(v)) ix._byAuthor.putIfAbsent(v.tx.fromAddress, () => []).add(v);
    }

    for (final v in oldestFirst) {
      final ref = v.tx.referenceId;
      if (ref == null) continue;
      final target = ix._byTxid[ref];
      if (target == null) continue;
      switch (v.tx.kind) {
        case TxKind.reply:
          // Nothing replies to a non-text message: that's a payment.
          if (target.confirmed && target.tx.fromAddress == v.tx.toAddress && !isNonTextMessage(target)) {
            ix._parentOf[v.tx.id] = ref;
            ix._children.putIfAbsent(ref, () => []).add(v);
          }
        case TxKind.flag:
          // A pending flag may duplicate a mined one; count each address once.
          ix._flaggers.putIfAbsent(ref, () => {}).add(v.tx.fromAddress);
        case TxKind.orphan || TxKind.raw:
          break;
      }
    }
    for (final list in ix._children.values) {
      list.sort((a, b) => activityTime(a).compareTo(activityTime(b)));
    }

    // Replies whose thread isn't known yet: up each chain of valid replies
    // to a message that's missing. (A reply that isn't part of a thread, a
    // payment under Section 2.4, leads nowhere.)
    for (final v in ix._byTxid.values) {
      if (v.tx.kind != TxKind.reply) continue;
      var cur = v;
      for (var depth = 0; depth < 10000 && cur.tx.kind == TxKind.reply; depth++) {
        final ref = cur.tx.referenceId;
        if (ref == null) break;
        final target = ix._byTxid[ref];
        if (target == null) {
          final t = activityTime(v);
          if (t > (ix.missingParents[ref] ?? -1)) ix.missingParents[ref] = t;
          break;
        }
        if (!ix._parentOf.containsKey(cur.tx.id)) break;
        cur = target;
      }
    }

    // Alias candidates (Section 7.8): mined Orphans of the alias length, by
    // sender, latest first (the input's order).
    for (final v in newestFirst) {
      if (v.tx.kind == TxKind.orphan && v.confirmed && v.tx.contentSize == aliasContentSize) {
        ix._aliasCandidates.putIfAbsent(v.tx.fromAddress, () => []).add(v);
      }
    }

    for (final v in ix._byTxid.values) {
      if (v.tx.kind != TxKind.orphan || isNonTextMessage(v)) continue;
      var last = activityTime(v);
      var replies = 0;
      final stack = [...ix.repliesOf(v)];
      final seen = <String>{v.tx.id};
      while (stack.isNotEmpty) {
        final r = stack.removeLast();
        if (!seen.add(r.tx.id)) continue;
        replies++;
        last = max(last, activityTime(r));
        stack.addAll(ix.repliesOf(r));
      }
      ix.threads.add(ThreadSummary(v, lastActivity: last, replies: replies, flags: ix.flagCountOf(v)));
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

  /// Valid direct replies to this message, oldest first.
  List<TxView> repliesOf(TxView v) => _children[v.tx.id] ?? const [];

  int replyCountOf(TxView v) => repliesOf(v).length;

  /// Every valid reply under this message, at any depth.
  Iterable<TxView> repliesUnder(TxView v) sync* {
    final seen = <String>{v.tx.id};
    final stack = [...repliesOf(v)];
    while (stack.isNotEmpty) {
      final r = stack.removeLast();
      if (!seen.add(r.tx.id)) continue;
      yield r;
      stack.addAll(repliesOf(r));
    }
  }

  /// The threads and replies `address` wrote, among what's known, newest
  /// first.
  List<TxView> messagesBy(String address) => _byAuthor[address] ?? const [];

  int flagCountOf(TxView v) => _flaggers[v.tx.id]?.length ?? 0;

  /// Whether the message's own author flagged it: withdrawn.
  bool isSelfFlagged(TxView v) => _flaggers[v.tx.id]?.contains(v.tx.fromAddress) ?? false;

  /// The message a reply validly answers, if any.
  TxView? parentOf(TxView v) {
    final p = _parentOf[v.tx.id];
    return p == null ? null : _byTxid[p];
  }

  /// Whether a Reply counts as part of a thread under Section 2.4.
  bool isThreadedReply(TxView v) => _parentOf.containsKey(v.tx.id);

  /// The thread (Orphan) at the top of a message's reply chain, or null if
  /// the chain doesn't lead to a known Orphan.
  TxView? threadRootOf(TxView v) {
    var cur = v;
    for (var depth = 0; depth < 10000; depth++) {
      if (cur.tx.kind == TxKind.orphan) return cur;
      final p = parentOf(cur);
      if (p == null) return null;
      cur = p;
    }
    return null;
  }
}
