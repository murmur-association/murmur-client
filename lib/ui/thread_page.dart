import 'dart:math';

import 'package:flutter/material.dart';

import '../protocol/models.dart';
import '../protocol/quote.dart';
import '../services/node_client.dart';
import 'common.dart';
import 'compose_page.dart';
import 'emoji.dart';
import 'glyphs.dart';

/// A thread: its first message, then its replies **from the newest down**,
/// which is the end the node can prove first. However long the thread, it
/// opens with its newest page; "Earlier replies" reads the one before.
/// Threads are flat; a reply that answers another reply shows it quoted, and
/// a tap on the quote goes to that reply.
class ThreadPage extends StatefulWidget {
  const ThreadPage({super.key, required this.rootTxid, this.focusTxid});

  final String rootTxid;

  /// Message to highlight (the one the user tapped to get here).
  final String? focusTxid;

  @override
  State<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  final _scroll = ScrollController();

  /// Each message's card, to find where it is on the page.
  final _cards = <String, GlobalKey>{};

  /// The message highlighted: the one the page was opened for, then the
  /// last one a quote led to.
  late String? _focus = widget.focusTxid;

  /// A quote of a reply older than the ones loaded, which the user asked
  /// for: earlier pages are read until it is there.
  String? _seeking;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Highlights the message `txid` and brings it into view. It is at or
  /// below what is on screen (a quoted reply is older than its answer, so
  /// further down): the page moves down until its card is built.
  Future<void> _goTo(String txid) async {
    setState(() => _focus = txid);
    for (var step = 0; step < 400 && mounted; step++) {
      final card = _cards[txid]?.currentContext;
      if (card != null && card.mounted) {
        await Scrollable.ensureVisible(card, duration: const Duration(milliseconds: 250), alignment: 0.1);
        return;
      }
      if (!_scroll.hasClients) return;
      final at = _scroll.position;
      if (at.pixels >= at.maxScrollExtent) return;
      _scroll.jumpTo(min(at.maxScrollExtent, at.pixels + at.viewportDimension * 0.8));
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rootTxid = widget.rootTxid;
    return AppBuilder(builder: (context, client, wallets) {
      final root = client.lookupTx(rootTxid);
      if (root == null) {
        // Opened from a link, the thread may not be fetched yet: asked of the
        // node by id, with a merkle branch to its block.
        client.requestTx(rootTxid);
        final searching = !client.isUnknownTx(rootTxid) && client.state != LinkState.disconnected;
        return Scaffold(
          appBar: AppBar(title: Text(l.kindThread)),
          body: searching
              ? EmptyState(icon: Glyph.search, text: l.txSearching)
              : EmptyState(icon: Glyph.unknown, text: l.threadGone),
        );
      }

      final theme = Theme.of(context);
      final muted = AppScope.of(context).prefs.muted;
      // Oldest first, as the chain has them: what a reply may quote is
      // before it. Replies from muted addresses are left out of the page.
      final replies = client.repliesOf(root);
      final ids = [for (final r in replies) r.tx.id];
      final shown = <(TxView, int)>[];
      var mutedReplies = 0;
      for (var i = replies.length - 1; i >= 0; i--) {
        if (muted.contains(replies[i].tx.fromAddress)) {
          mutedReplies++;
        } else {
          shown.add((replies[i], i));
        }
      }
      client.watchThread(root, [root, for (final (v, _) in shown) v]);
      // Only the newest replies are here: the rest come when asked for.
      final earlier = client.threadHasEarlier(rootTxid);

      // The replies a reply answers: those shown here, and how many are
      // older than the replies loaded.
      (List<TxView>, List<String>) quotes(TxView reply, int place) {
        final found = <TxView>[];
        final notLoaded = <String>[];
        for (final quote in quotesOf(client, reply)) {
          final id = quotedReply(ids.take(place), quote);
          if (id == null) {
            if (earlier) notLoaded.add(quote);
          } else if (!muted.contains(replies[ids.indexOf(id)].tx.fromAddress)) {
            found.add(replies[ids.indexOf(id)]);
          }
        }
        return (found, notLoaded);
      }

      // A quote the user asked to see, older than what was loaded: there
      // now, or a page further back.
      final seeking = _seeking;
      if (seeking != null) {
        final id = quotedReply(ids, seeking);
        if (id != null || !earlier) {
          _seeking = null;
          if (id != null) WidgetsBinding.instance.addPostFrameCallback((_) => _goTo(id));
        } else {
          client.readEarlier(rootTxid);
        }
      }

      // Withdrawn by its author: said first, and the thread shown faded.
      final withdrawn = client.selfFlagged(root);
      final mine = root.tx.fromAddress == wallets.wallet?.addressHex;

      Widget card(TxView view, int? place) {
        final (quoted, notLoaded) = place == null ? (const <TxView>[], const <String>[]) : quotes(view, place);
        final card = Padding(
          key: _cards.putIfAbsent(view.tx.id, GlobalKey.new),
          padding: EdgeInsetsDirectional.only(start: place == null ? 0 : 20),
          child: _MessageCard(
            view: view,
            client: client,
            quoted: quoted,
            notLoaded: notLoaded,
            onQuote: _goTo,
            onNotLoaded: (quote) => setState(() => _seeking = quote),
            isRoot: place == null,
            highlighted: view.tx.id == _focus,
            canAct: wallets.wallet != null,
            flagged: wallets.wallet != null && client.hasFlagged(wallets.wallet!.addressHex, view.tx.id),
          ),
        );
        return withdrawn ? Opacity(opacity: 0.55, child: card) : card;
      }

      final items = <Widget Function()>[
        if (withdrawn)
          () => Card(
                color: theme.colorScheme.tertiaryContainer,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const MurmurIcon(Glyph.flag),
                  title: Text(mine ? l.threadWithdrawnMineNote : l.threadWithdrawnNote),
                ),
              ),
        () => card(root, null),
        // Said outright: a forum's replies usually run the other way.
        if (shown.length > 1 || earlier)
          () => Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 0, 12),
                child: Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(l.repliesNewestFirst, style: theme.textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ]),
              ),
        for (final (view, place) in shown) () => card(view, place),
        if (mutedReplies > 0)
          () => Padding(
                padding: const EdgeInsets.all(12),
                child: Text(l.mutedRepliesHidden(mutedReplies),
                    textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              ),
        if (earlier)
          () => Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 0, 0),
                child: client.threadReading(rootTxid)
                    ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                    : OutlinedButton(
                        onPressed: () => client.readEarlier(rootTxid),
                        child: Text(l.earlierReplies),
                      ),
              ),
      ];

      return Scaffold(
        appBar: AppBar(
          // The count is of the replies at hand: not said while there are more.
          title: Text(earlier ? l.kindThread : '${l.kindThread} · ${l.replyCount(shown.length)}'),
          actions: [StarButton(rootTxid), ShareButton(threadLink(rootTxid), subject: 'Murmur', size: 24)],
        ),
        body: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          itemCount: items.length,
          itemBuilder: (context, i) => items[i](),
        ),
      );
    });
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.view,
    required this.client,
    required this.quoted,
    required this.notLoaded,
    required this.onQuote,
    required this.onNotLoaded,
    required this.isRoot,
    required this.highlighted,
    required this.canAct,
    required this.flagged,
  });

  final TxView view;
  final MurmurClient client;

  /// The replies this one answers: those at hand, and the quotes of ones
  /// older than the replies loaded.
  final List<TxView> quoted;
  final List<String> notLoaded;

  /// A tap on a quote: go to that reply (by txid), or load back to it.
  final void Function(String txid) onQuote;
  final void Function(String quote) onNotLoaded;
  final bool isRoot;
  final bool highlighted;
  final bool canAct;

  /// Whether the current wallet has already flagged this message.
  final bool flagged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final tx = view.tx;
    final text = liveMessageText(context, view);
    final when = whenOf(context, view);
    return Card(
      color: highlighted ? theme.colorScheme.secondaryContainer : null,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            InkWell(
              onTap: () => openAddress(context, tx.fromAddress),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AddressAvatar(tx.fromAddress, size: 22),
                const SizedBox(width: 6),
                Text(nameOf(context, tx.fromAddress), style: TextStyle(color: theme.colorScheme.primary)),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tx.kind == TxKind.reply ? '$when · ${l.paidToThreadAuthor(formatAmount(context, tx.amount))}' : when,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            CountBadges(replies: client.replyCountOf(view), flags: client.flagCountOf(view)),
          ]),
          const SizedBox(height: 8),
          for (final q in quoted) _Quote(q, onTap: () => onQuote(q.tx.id)),
          for (final q in notLoaded) _Quote(null, onTap: () => onNotLoaded(q)),
          MessageText(
            text ?? messageOrUnavailable(context, view),
            selectable: true,
            style: text == null
                ? TextStyle(color: theme.colorScheme.outline)
                : (isRoot ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge),
          ),
          Row(children: [
            if (canAct) ...[
              // Nothing replies to a message that isn't text (Section 2.4).
              if (!client.isNonText(view))
              TextButton.icon(
                icon: const MurmurIcon(Glyph.reply, size: 18),
                label: Text(l.actionReply),
                // Only mined messages can be replied to (Section 2.4).
                onPressed: !view.confirmed ? null : () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ComposePage(replyTo: view),
                )),
              ),
              TextButton.icon(
                icon: const MurmurIcon(Glyph.flag, size: 18),
                label: Text(flagged ? l.flagged : l.actionFlag),
                onPressed: flagged ? null : () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ComposePage(flagTarget: view),
                )),
              ),
            ],
            const Spacer(),
            TextButton(onPressed: () => openTx(context, tx.id), child: Text(l.details)),
          ]),
        ]),
      ),
    );
  }
}

/// A reply another one answers, above the answer: who wrote it and how it
/// starts. A tap goes to it. Without a `view` it is older than the replies
/// loaded, and a tap loads back to it.
class _Quote extends StatelessWidget {
  const _Quote(this.view, {required this.onTap});

  final TxView? view;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final copper = theme.colorScheme.primary;
    final view = this.view;
    final faint = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsetsDirectional.only(start: 10, top: 2, bottom: 2),
          decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: copper, width: 3))),
          child: view == null
              ? Text(context.l10n.quoteNotLoaded, style: faint)
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    AddressAvatar(view.tx.fromAddress, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(nameOf(context, view.tx.fromAddress),
                          overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: copper)),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  MessageText(messageOrUnavailable(context, view).replaceAll('\n', ' '), maxLines: 2, style: faint),
                ]),
        ),
      ),
    );
  }
}
