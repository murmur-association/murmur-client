import 'package:flutter/material.dart';

import '../protocol/models.dart';
import '../services/node_client.dart';
import '../services/starred.dart';
import 'common.dart';
import 'glyphs.dart';
import 'thread_page.dart';

/// Everything the user starred, newest star first: people, then whole
/// threads (starred by their root) and single messages. A tap opens the
/// person's page, or the message in its thread. What has activity the user
/// hasn't seen is marked: a reply under a starred thread or message, a
/// message written by a starred person.
///
/// The list is the one at the time the tab came into view, so unstarring a
/// row leaves it in place with an empty star, ready to be starred again.
class StarredTab extends StatefulWidget {
  const StarredTab({super.key, this.refreshToken = 0, this.activity = const StarredActivity(), this.since});

  /// Changes each time the tab comes into view: the list is taken again.
  final int refreshToken;

  /// The newest activity on each starred thing (`starredActivity`).
  final StarredActivity activity;

  /// What had been seen when the tab came into view: activity after it is
  /// marked as new for as long as the tab stays open. Null marks nothing.
  final int? since;

  @override
  State<StarredTab> createState() => _StarredTabState();
}

class _StarredTabState extends State<StarredTab> {
  List<String>? _txids;
  late List<String> _people;

  void _take() {
    // Stars are kept in the order they were given: newest last.
    final prefs = AppScope.of(context).prefs;
    _txids = prefs.starred.toList().reversed.toList();
    _people = prefs.starredPeople.toList().reversed.toList();
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
  Widget build(BuildContext context) {
    final l = context.l10n;
    final txids = _txids!;
    if (txids.isEmpty && _people.isEmpty) return EmptyState(icon: Glyph.star, text: l.noStarred);
    final since = widget.since;
    final fresh = since == null ? const <String>{} : widget.activity.newSince(since);
    return AppBuilder(builder: (context, client, _) {
      final rows = <Widget>[
        if (_people.isNotEmpty) _Heading(l.starredPeople),
        for (final address in _people) _PersonTile(address: address, client: client, fresh: fresh.contains(address)),
        if (txids.isNotEmpty) _Heading(l.starredThreads),
        for (final txid in txids) _StarredTile(txid: txid, client: client, fresh: fresh.contains(txid)),
      ];
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: rows.length,
        itemBuilder: (context, i) => rows[i],
      );
    });
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
      child: Text(text, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}

/// A row's picture, with a dot when the row has activity not seen yet.
class _Marked extends StatelessWidget {
  const _Marked({required this.fresh, required this.child});

  final bool fresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!fresh) return child;
    return Tooltip(
      message: context.l10n.newActivity,
      child: Badge(smallSize: 10, child: child),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.address, required this.client, required this.fresh});

  final String address;
  final MurmurClient client;
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    // Their newest message that can be shown, if any is known.
    final latest = client
        .messagesBy(address)
        .where((v) => v.confirmed && !client.selfFlagged(v) && !client.isNonText(v))
        .firstOrNull;
    return ListTile(
      leading: _Marked(fresh: fresh, child: AddressAvatar(address)),
      title: Text(nameOf(context, address), maxLines: 1, overflow: TextOverflow.ellipsis),
      // Until one of their messages is found, the name says it all.
      subtitle: latest == null
          ? null
          : Text(
              '${firstLine(messageOrUnavailable(context, latest))} · ${whenOf(context, latest)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: StarButton.person(address),
      onTap: () => openAddress(context, address),
    );
  }
}

class _StarredTile extends StatelessWidget {
  const _StarredTile({required this.txid, required this.client, required this.fresh});

  final String txid;
  final MurmurClient client;
  final bool fresh;

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
    return ListTile(
      leading: _Marked(
        fresh: fresh,
        child: Opacity(opacity: view.confirmed ? 1 : 0.5, child: AddressAvatar(tx.fromAddress)),
      ),
      title: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: PersonLine(tx.fromAddress, '$kind · ${whenOf(context, view)}'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (isRoot) CountBadges(replies: client.replyCountOf(view), flags: client.flagCountOf(view)),
        StarButton(txid),
      ]),
      // A thread opens at its top; a message in its thread, highlighted.
      onTap: () => isRoot
          ? Navigator.of(context).push(MaterialPageRoute(builder: (_) => ThreadPage(rootTxid: txid)))
          : openMessage(context, view),
    );
  }
}
