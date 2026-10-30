import 'package:flutter/material.dart';

import '../protocol/models.dart';
import '../services/node_client.dart';
import '../services/starred.dart';
import 'common.dart';
import 'emoji.dart';
import 'glyphs.dart';
import 'notifications.dart';
import 'thread_page.dart';

/// Everything the user starred, newest star first, in two lists of their own:
/// whole threads (starred by their root) and single messages, then people. A
/// tap opens the message in its thread, or the person's page. What has
/// activity the user hasn't opened is marked until opened: a reply under a
/// starred thread or message, a message written by a starred person. A list
/// with such a row has a dot on its tab.
///
/// The lists are the ones at the time the tab came into view, so unstarring a
/// row leaves it in place with an empty star, ready to be starred again.
class StarredTab extends StatefulWidget {
  const StarredTab({super.key, this.refreshToken = 0, this.activity = const StarredActivity()});

  /// Changes each time the tab comes into view: the lists are taken again.
  final int refreshToken;

  /// The newest activity on each starred thing (`starredActivity`).
  final StarredActivity activity;

  @override
  State<StarredTab> createState() => _StarredTabState();
}

class _StarredTabState extends State<StarredTab> with SingleTickerProviderStateMixin {
  List<String>? _txids;
  late List<String> _people;
  late final TabController _lists = TabController(length: 2, vsync: this);

  /// The people's list, after the threads' (0).
  static const _peopleList = 1;

  void _take() {
    // Stars are kept in the order they were given: newest last.
    final prefs = AppScope.of(context).prefs;
    _txids = prefs.starred.toList().reversed.toList();
    _people = prefs.starredPeople.toList().reversed.toList();
    // With only people starred, their list is the one to see.
    if (_txids!.isEmpty && _people.isNotEmpty) _lists.index = _peopleList;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_txids == null) _take();
  }

  @override
  void didUpdateWidget(StarredTab old) {
    super.didUpdateWidget(old);
    if (old.refreshToken != widget.refreshToken) _take();
  }

  @override
  void dispose() {
    _lists.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final txids = _txids!;
    if (txids.isEmpty && _people.isEmpty) return EmptyState(icon: Glyph.star, text: l.noStarred);
    final prefs = AppScope.of(context).prefs;
    final activity = widget.activity;
    return AppBuilder(builder: (context, client, _) {
      // Activity newer than when a row was last opened marks it until it is
      // opened again: that activity's time, or null.
      int? unread(String key) {
        final time = activity.messages[key] ?? activity.people[key];
        return time != null && prefs.isUnread(key, time) ? time : null;
      }

      Widget list(List<Widget> rows, String empty) => rows.isEmpty
          ? EmptyState(icon: Glyph.star, text: empty)
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: rows.length,
              itemBuilder: (context, i) => rows[i],
            );

      return ListenableBuilder(
        listenable: prefs,
        builder: (context, _) => Column(children: [
          Row(children: [
            Expanded(
              child: TabBar(controller: _lists, tabs: [
                _ListTab(l.starredThreads, unread: txids.any((t) => unread(t) != null)),
                _ListTab(l.starredPeople, unread: _people.any((a) => unread(a) != null)),
              ]),
            ),
            const NotificationsButton(),
          ]),
          Expanded(
            child: TabBarView(controller: _lists, children: [
              list([for (final txid in txids) _StarredTile(txid: txid, client: client, unread: unread(txid))],
                  l.noStarredThreads),
              list([for (final address in _people) _PersonTile(address: address, client: client, unread: unread(address))],
                  l.noStarredPeople),
            ]),
          ),
        ]),
      );
    });
  }
}

/// One list's tab, with a dot while the list has a row not opened yet.
class _ListTab extends StatelessWidget {
  const _ListTab(this.text, {required this.unread});

  final String text;
  final bool unread;

  @override
  Widget build(BuildContext context) => Tab(
        child: Badge(
          isLabelVisible: unread,
          smallSize: 8,
          // Room for the dot after the text, on whichever side that is. Only
          // with the dot: the tab's underline spans this padding too.
          child: Padding(
            padding: EdgeInsetsDirectional.only(end: unread ? 10 : 0),
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      );
}

/// A row's picture, with a dot when the row has activity not opened yet.
class _Marked extends StatelessWidget {
  const _Marked({required this.unread, required this.child});

  final bool unread;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!unread) return child;
    return Tooltip(
      message: context.l10n.newActivity,
      child: Badge(smallSize: 10, child: child),
    );
  }
}

/// Marks a row's activity, up to `time`, as read: it was opened.
void _opened(BuildContext context, String key, int? time) {
  if (time != null) AppScope.of(context).prefs.markOpened(key, time);
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.address, required this.client, required this.unread});

  final String address;
  final MurmurClient client;

  /// The time of activity not opened yet, if any: the row is marked.
  final int? unread;

  @override
  Widget build(BuildContext context) {
    // Their newest message that can be shown, if any is known.
    final latest = client
        .messagesBy(address)
        .where((v) => v.confirmed && !client.selfFlagged(v) && !client.isNonText(v))
        .firstOrNull;
    final marked = unread != null;
    return ListTile(
      leading: _Marked(unread: marked, child: AddressAvatar(address)),
      tileColor: marked ? highlightTint(context, 1) : null,
      title: Text(nameOf(context, address),
          maxLines: 1, overflow: TextOverflow.ellipsis, style: marked ? const TextStyle(fontWeight: FontWeight.w700) : null),
      // Until one of their messages is found, the name says it all.
      subtitle: latest == null
          ? null
          : MessageText(
              '${firstLine(messageOrUnavailable(context, latest))} · ${whenOf(context, latest)}',
              maxLines: 1,
            ),
      trailing: StarButton.person(address),
      onTap: () {
        _opened(context, address, unread);
        openAddress(context, address);
      },
    );
  }
}

class _StarredTile extends StatelessWidget {
  const _StarredTile({required this.txid, required this.client, required this.unread});

  final String txid;
  final MurmurClient client;

  /// The time of activity not opened yet, if any: the row is marked.
  final int? unread;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final view = client.lookupTx(txid);
    if (view == null) {
      // Not loaded yet: asked of the node by id, with a merkle branch to
      // its block.
      client.requestTx(txid);
      final gone = client.isUnknownTx(txid) || !client.isOnline;
      return ListTile(
        leading: const SizedBox.square(dimension: 40, child: Center(child: MurmurIcon(Glyph.star))),
        title: Text(gone ? l.starredGone : l.contentLoading,
            style: TextStyle(color: theme.colorScheme.outline)),
        subtitle: Text(shortHex(txid), style: mono),
        trailing: StarButton(txid),
      );
    }
    final tx = view.tx;
    final text = firstLine(messageOrUnavailable(context, view));
    final kind = tx.kind == TxKind.orphan ? l.kindThread : l.kindReply;
    final isRoot = tx.kind == TxKind.orphan;
    final marked = unread != null;
    return ListTile(
      // The author's picture opens their page.
      leading: _Marked(unread: marked, child: AvatarLink(tx.fromAddress, faded: !view.confirmed)),
      tileColor: marked ? highlightTint(context, 1) : null,
      title: MessageText(text, maxLines: 1, style: marked ? const TextStyle(fontWeight: FontWeight.w700) : null),
      subtitle: PersonLine(tx.fromAddress, '$kind · ${whenOf(context, view)}'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (isRoot) CountBadges(replies: client.replyCountOf(view), flags: client.flagCountOf(view)),
        StarButton(txid),
      ]),
      // A thread opens where its reader left off; a message in its thread,
      // highlighted.
      onTap: () {
        _opened(context, txid, unread);
        isRoot
            ? Navigator.of(context).push(MaterialPageRoute(builder: (_) => ThreadPage(rootTxid: txid)))
            : openMessage(context, view);
      },
    );
  }
}
