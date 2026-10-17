import 'dart:math';

import 'package:flutter/material.dart';

import '../protocol/models.dart';
import '../protocol/quote.dart';
import '../services/node_client.dart';
import 'common.dart';
import 'compose_page.dart';
import 'emoji.dart';
import 'glyphs.dart';

/// A thread: its first message, then its replies **oldest first**, as a
/// forum reads. Its replies are read a page at a time, each page proven on
/// its own: the first time from the first reply, later from where its
/// reader left off, which the page goes to. Others' replies newer than that
/// are highlighted for a moment as they come into view. "Earlier replies",
/// under the first message, reads the page before the ones at hand;
/// reaching the last of them reads the page after. Threads are flat; a
/// reply that answers another reply shows it quoted, and a tap on the quote
/// goes to that reply.
class ThreadPage extends StatefulWidget {
  const ThreadPage({super.key, required this.rootTxid, this.focusTxid});

  final String rootTxid;

  /// Message to go to and highlight (the one the user tapped to get here),
  /// in place of where the reader left off.
  final String? focusTxid;

  @override
  State<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  final _scroll = ScrollController();

  /// The list, to tell which cards are on screen.
  final _list = GlobalKey();

  /// Each message's card, to find where it is on the page.
  final _cards = <String, GlobalKey>{};

  /// Where the reader left off last time; null on a first visit, which
  /// marks nothing.
  ({String txid, int? place})? _left;

  /// The message to go to once it is here: the one the page was opened for,
  /// or where the reader left off. Cleared once gone to.
  String? _target;

  /// When each message was highlighted: a reply newer than where the
  /// reader left off, as it came into view, or one the page was opened for
  /// or a quote led to. The highlight fades.
  final _flashedAt = <String, DateTime>{};

  /// The furthest reply down that has been on screen: where the reader
  /// leaves off.
  String? _furthest;

  /// A quote of a reply older than the ones loaded, which the user asked
  /// for: earlier pages are read until it is there.
  String? _seeking;

  bool _started = false;

  /// Whether the thread was asked for already: the first time, what was
  /// read of it moves to where the page opens.
  bool _watched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final left = AppScope.of(context).prefs.threadsRead[widget.rootTxid];
    _left = left;
    final focus = widget.focusTxid;
    _target = focus != null && focus != widget.rootTxid ? focus : left?.txid;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Brings message `txid` into view, highlighting it (`flash`). It is above
  /// what is on screen when `up` (a quoted reply is older than its answer,
  /// so further up), else below: the page moves that way until its card is
  /// built.
  Future<void> _goTo(String txid, {bool up = true, bool flash = true}) async {
    for (var step = 0; step < 400 && mounted; step++) {
      final card = _cards[txid]?.currentContext;
      if (card != null && card.mounted) {
        await Scrollable.ensureVisible(card, duration: const Duration(milliseconds: 250), alignment: 0.1);
        if (flash && mounted) setState(() => _flashedAt[txid] = DateTime.now());
        return;
      }
      if (!_scroll.hasClients) return;
      final at = _scroll.position;
      final by = at.viewportDimension * 0.8;
      if (up ? at.pixels <= at.minScrollExtent : at.pixels >= at.maxScrollExtent) return;
      _scroll.jumpTo(up ? max(at.minScrollExtent, at.pixels - by) : min(at.maxScrollExtent, at.pixels + by));
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  /// Notes which replies are on screen: the furthest down is where the
  /// reader leaves off, and one newer than where they left off last time
  /// is highlighted as it comes into view.
  void _onScreen(MurmurClient client, List<String> order, bool Function(String txid) unread) {
    if (!mounted) return;
    final list = _list.currentContext?.findRenderObject() as RenderBox?;
    if (list == null || !list.attached || !list.hasSize) return;
    var furthest = _furthest == null ? -1 : order.indexOf(_furthest!);
    var changed = false;
    for (final MapEntry(key: txid, value: key) in _cards.entries) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero, ancestor: list).dy;
      if (top + box.size.height <= 0 || top >= list.size.height) continue;
      final at = order.indexOf(txid);
      if (at > furthest) furthest = at;
      if (unread(txid) && !_flashedAt.containsKey(txid)) {
        _flashedAt[txid] = DateTime.now();
        changed = true;
      }
    }
    if (furthest >= 0 && order[furthest] != _furthest) {
      _furthest = order[furthest];
      final place = client.threadPlace(widget.rootTxid, _furthest!);
      final left = _left;
      // Never back from where they had got to before.
      final behind = left != null && left.place != null && place != null && place < left.place!;
      if (!behind) AppScope.of(context).prefs.setThreadRead(widget.rootTxid, _furthest!, place);
    }
    if (changed) setState(() {});
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
      final me = wallets.wallet?.addressHex;
      // Oldest first, as the chain has them and the page shows them: what a
      // reply may quote is before it. Replies from muted addresses are left
      // out of the page.
      final replies = client.threadReplies(root);
      final ids = [for (final r in replies) r.tx.id];
      final shown = <(TxView, int)>[];
      var mutedReplies = 0;
      for (var i = 0; i < replies.length; i++) {
        if (muted.contains(replies[i].tx.fromAddress)) {
          mutedReplies++;
        } else {
          shown.add((replies[i], i));
        }
      }
      // From where the reader left off; opened for a message, from the
      // thread's newest end, where a reply just sent or received is. What
      // was read before is moved there when the page opens.
      final focus = widget.focusTxid;
      client.watchThread(root, [root, for (final (v, _) in shown) v],
          from: focus == null ? _left?.place : null, fromEnd: focus != null, move: !_watched);
      _watched = true;
      // There may be replies before the ones here, and after them: they
      // come when asked for, above and below.
      final earlier = client.threadHasEarlier(rootTxid);
      final later = client.threadHasLater(rootTxid);

      // Others' replies newer than where the reader left off: by place in
      // the thread where the node's index gave it, else by order.
      final left = _left;
      final leftAt = left == null ? -1 : ids.indexOf(left.txid);
      bool unread(String txid) {
        if (left == null) return false;
        final at = ids.indexOf(txid);
        if (at < 0 || replies[at].tx.fromAddress == me) return false;
        final place = client.threadPlace(rootTxid, txid);
        if (place != null && left.place != null) return place > left.place!;
        return leftAt >= 0 && at > leftAt;
      }

      // The message to go to, once it is here: there may be pages to read
      // down to it first.
      final target = _target;
      if (target != null) {
        if (ids.contains(target)) {
          _target = null;
          final flash = target == focus;
          WidgetsBinding.instance.addPostFrameCallback((_) => _goTo(target, up: false, flash: flash));
        } else if (target == focus && earlier) {
          // Read from the newest end: an older message is further back.
          if (!client.threadReading(rootTxid)) client.readEarlier(rootTxid);
        } else if (later) {
          if (!client.threadReading(rootTxid)) client.readLater(rootTxid);
        } else if (!client.threadReading(rootTxid) && client.threadComplete(rootTxid)) {
          // Not shown any more (withdrawn, or its author muted): where the
          // reader left off is then the reply before it that is.
          _target = null;
          final place = left?.place;
          final before = place == null
              ? null
              : shown.where((s) => (client.threadPlace(rootTxid, s.$1.tx.id) ?? 0) <= place).lastOrNull;
          if (before != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _goTo(before.$1.tx.id, up: false, flash: false));
          }
        }
      }

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
      final mine = root.tx.fromAddress == me;

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
            flashedAt: _flashedAt[view.tx.id],
            canAct: wallets.wallet != null,
            flagged: wallets.wallet != null && client.hasFlagged(wallets.wallet!.addressHex, view.tx.id),
          ),
        );
        return withdrawn ? Opacity(opacity: 0.55, child: card) : card;
      }

      Widget spinner() => const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()));

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
        if (earlier)
          () => Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 0, 12),
                child: client.threadReading(rootTxid, earlier: true)
                    ? spinner()
                    : OutlinedButton(
                        onPressed: () => client.readEarlier(rootTxid),
                        child: Text(l.earlierReplies),
                      ),
              ),
        for (final (view, place) in shown) () => card(view, place),
        if (mutedReplies > 0)
          () => Padding(
                padding: const EdgeInsets.all(12),
                child: Text(l.mutedRepliesHidden(mutedReplies),
                    textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              ),
        // Built only as the reader nears the end: the page after is read.
        if (later)
          () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) client.readLater(rootTxid);
            });
            return Padding(padding: const EdgeInsetsDirectional.only(start: 20), child: spinner());
          },
      ];

      // What is on screen, after each layout and whenever the page stops
      // scrolling.
      final order = [for (final (v, _) in shown) v.tx.id];
      WidgetsBinding.instance.addPostFrameCallback((_) => _onScreen(client, order, unread));

      return Scaffold(
        appBar: AppBar(
          // The count is of the replies at hand: not said while there are more.
          title: Text(earlier || later ? l.kindThread : '${l.kindThread} · ${l.replyCount(shown.length)}'),
          actions: [StarButton(rootTxid), ShareButton(threadLink(rootTxid), subject: 'Murmur', size: 24)],
        ),
        body: NotificationListener<ScrollEndNotification>(
          onNotification: (_) {
            _onScreen(client, order, unread);
            return false;
          },
          child: ListView.builder(
            key: _list,
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            itemCount: items.length,
            itemBuilder: (context, i) => items[i](),
          ),
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
    required this.flashedAt,
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

  /// When it was highlighted, if it was: the highlight fades.
  final DateTime? flashedAt;
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
    final base = theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow;
    final body = Padding(
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
                onPressed: !view.confirmed
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ComposePage(replyTo: view),
                        )),
              ),
            TextButton.icon(
              icon: const MurmurIcon(Glyph.flag, size: 18),
              label: Text(flagged ? l.flagged : l.actionFlag),
              onPressed: flagged
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ComposePage(flagTarget: view),
                      )),
            ),
          ],
          const Spacer(),
          TextButton(onPressed: () => openTx(context, tx.id), child: Text(l.details)),
        ]),
      ]),
    );
    // Highlighted for a moment, then as any other card.
    return FadingHighlight(
      since: flashedAt,
      builder: (context, strength) => Card(
        color: strength > 0 ? Color.alphaBlend(highlightTint(context, strength * 2)!, base) : null,
        margin: const EdgeInsets.only(bottom: 8),
        child: body,
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
