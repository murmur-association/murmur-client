// What's new for the user: replies to the wallet's threads, answers to its
// replies, messages that mention it, and activity on what's starred. The
// Messages and Starred badges count it, and notifications tell of it.
// Everything is read from what the client has fetched and proven.

import '../protocol/models.dart';
import 'node_client.dart';
import 'starred.dart';

/// Why a message is news.
enum NewsKind {
  /// A reply in one of the wallet's threads (it pays the wallet).
  reply,

  /// An answer to one of the wallet's replies, in someone else's thread.
  answer,

  /// A thread or a reply that mentions the wallet.
  mention,

  /// A reply under a starred thread or message.
  starredThread,

  /// A message by a starred person.
  starredPerson,
}

/// What the user may be notified of, each switched on apart.
enum NotifyTopic {
  /// Replies and answers to the wallet.
  replies,

  /// Mentions of the wallet.
  mentions,

  /// Activity on what's starred.
  starred;

  /// The topic a kind of news belongs to.
  static NotifyTopic of(NewsKind kind) => switch (kind) {
        NewsKind.reply || NewsKind.answer => replies,
        NewsKind.mention => mentions,
        NewsKind.starredThread || NewsKind.starredPerson => starred,
      };
}

/// One message that is news, and why.
class News {
  const News(this.kind, this.view, {this.starred});

  final NewsKind kind;
  final TxView view;

  /// For starred news, what's starred: a txid, or a person's address.
  final String? starred;

  String get txid => view.tx.id;
  String get from => view.tx.fromAddress;
  int get time => activityTime(view);
}

/// Why `tx`, by someone else, is news for the wallet `me`: a reply in its
/// thread, an answer to its reply, a mention of it; null if it isn't.
NewsKind? walletNewsKind(MurmurClient client, Transaction tx, String me) {
  if (tx.fromAddress == me) return null;
  if (tx.kind == TxKind.reply && client.creditedBy(tx) == me) return NewsKind.reply;
  if (tx.kind == TxKind.reply && client.answersTo(tx, me)) return NewsKind.answer;
  if (client.mentions(tx, me)) return NewsKind.mention;
  return null;
}

/// What's news for the wallet `me` in its history, newest first, down to
/// the first mined message at or before `since` (Unix seconds): what's older
/// was seen. Others' pending messages newer than that come too. Muted
/// senders are left out.
Iterable<News> walletNews(MurmurClient client, String me, {required int since, Set<String> muted = const {}}) sync* {
  for (final v in client.activityOf(me)) {
    if (v.confirmed && activityTime(v) <= since) return; // newest first: the rest were seen
    final kind = walletNewsKind(client, v.tx, me);
    if (kind == null || muted.contains(v.tx.fromAddress)) continue;
    yield News(kind, v);
  }
}

/// Mined messages that are news since `since`, for notifications: the
/// wallet's (`walletSince`, `me`) and the starred things' (`starredSince`),
/// on the `topics` asked for, newest first, each message once. A message
/// that is both (a reply in the wallet's thread that is also starred) counts
/// as the wallet's.
List<News> newsSince(
  MurmurClient client, {
  required Set<NotifyTopic> topics,
  String? me,
  int walletSince = 0,
  int starredSince = 0,
  Set<String> starred = const {},
  Set<String> people = const {},
  Set<String> muted = const {},
}) {
  final found = <String, News>{};
  if (me != null && (topics.contains(NotifyTopic.replies) || topics.contains(NotifyTopic.mentions))) {
    for (final news in walletNews(client, me, since: walletSince, muted: muted)) {
      if (!news.view.confirmed || news.time <= walletSince) continue;
      if (!topics.contains(NotifyTopic.of(news.kind))) continue;
      found.putIfAbsent(news.txid, () => news);
    }
  }
  if (topics.contains(NotifyTopic.starred)) {
    for (final (key, v, person)
        in starredMessages(client, starred: starred, people: people, me: me, muted: muted, since: starredSince)) {
      if (activityTime(v) <= starredSince) continue;
      found.putIfAbsent(
          v.tx.id, () => News(person ? NewsKind.starredPerson : NewsKind.starredThread, v, starred: key));
    }
  }
  return found.values.toList()..sort((a, b) => b.time.compareTo(a.time));
}
