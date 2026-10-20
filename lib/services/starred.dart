// What's new on what the user starred: replies under a starred thread or
// message, and messages written by a starred person. Read from what the
// client has fetched; following a star (below) is what gets it fetched.

import 'dart:math';

import '../protocol/models.dart';
import 'node_client.dart';

/// The newest activity on each starred thing that has any.
class StarredActivity {
  const StarredActivity({this.messages = const {}, this.people = const {}});

  /// Starred txid -> time of the newest reply under it.
  final Map<String, int> messages;

  /// Starred address -> time of the newest message they wrote.
  final Map<String, int> people;

  /// The newest of all, or null with no activity known.
  int? get newest => [...messages.values, ...people.values].fold<int?>(null, (a, b) => a == null ? b : max(a, b));

  /// The starred txids and addresses with activity after `since`.
  Set<String> newSince(int since) => {
        for (final MapEntry(:key, :value) in messages.entries)
          if (value > since) key,
        for (final MapEntry(:key, :value) in people.entries)
          if (value > since) key,
      };
}

/// Follows what's starred, and says what's the newest activity on each.
///
/// Following: a starred thread's blocks are found through their filters
/// (`watchThread`), and so are a starred person's (`watchAddress`), so
/// replies and messages are found wherever they are on the chain. That costs
/// a filter scan and the matching blocks: for a person who mines, every
/// block they mined. It's the user's own choice, one star at a time.
///
/// What counts: mined messages that are text and not withdrawn, from others
/// than `me` and than the `muted`.
StarredActivity starredActivity(
  MurmurClient client, {
  required Set<String> starred,
  required Set<String> people,
  String? me,
  Set<String> muted = const {},
}) {
  final messages = <String, int>{};
  final byPeople = <String, int>{};
  for (final (key, v, person) in starredMessages(client, starred: starred, people: people, me: me, muted: muted)) {
    final into = person ? byPeople : messages;
    into[key] = max(into[key] ?? 0, activityTime(v));
  }
  return StarredActivity(messages: messages, people: byPeople);
}

/// The messages that are activity on what's starred, following it (as
/// [starredActivity] says): each with the starred txid or address it's
/// under, and whether that is a person. Under a starred thread or message,
/// every reply that counts; of a starred person, their messages newest
/// first, down to the first at or before `since` (only the newest without
/// it).
Iterable<(String, TxView, bool)> starredMessages(
  MurmurClient client, {
  required Set<String> starred,
  required Set<String> people,
  String? me,
  Set<String> muted = const {},
  int? since,
}) sync* {
  bool counts(TxView v) =>
      v.confirmed &&
      v.tx.fromAddress != me &&
      !muted.contains(v.tx.fromAddress) &&
      !client.selfFlagged(v) &&
      !client.isNonText(v);

  for (final txid in starred) {
    final view = client.lookupTx(txid);
    if (view == null) {
      client.requestTx(txid);
      continue;
    }
    if (view.tx.kind != TxKind.orphan && view.tx.kind != TxKind.reply) continue;
    final under = client.repliesOf(view);
    final root = client.threadRootOf(view);
    if (root != null && root.confirmed) client.watchThread(root, [view, ...under], followEnd: true);
    for (final reply in under) {
      if (counts(reply)) yield (txid, reply, false);
    }
  }

  for (final address in people) {
    client.watchAddress(address);
    if (address == me || muted.contains(address)) continue;
    for (final v in client.messagesBy(address)) {
      if (since != null && v.confirmed && activityTime(v) <= since) break; // newest first
      if (!counts(v)) continue;
      yield (address, v, true);
      if (since == null) break;
    }
  }
}
