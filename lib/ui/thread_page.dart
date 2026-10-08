import 'package:flutter/material.dart';

import '../protocol/models.dart';
import '../protocol/quote.dart';
import '../services/node_client.dart';
import 'common.dart';
import 'compose_page.dart';
import 'emoji.dart';
import 'glyphs.dart';

/// A thread: its first message and its replies, oldest first. Threads are
/// flat; a reply that answers another reply shows it quoted.
class ThreadPage extends StatelessWidget {
  const ThreadPage({super.key, required this.rootTxid, this.focusTxid});

  final String rootTxid;

  /// Message to highlight (the one the user tapped to get here).
  final String? focusTxid;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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

      // The thread's first message, then its replies, oldest first: threads
      // are flat. Replies from muted addresses are left out.
      final muted = AppScope.of(context).prefs.muted;
      final replies = client.repliesOf(root);
      // Each with its place among the replies: what it may quote is before it.
      final entries = <(TxView, int)>[(root, 0)];
      var mutedReplies = 0;
      for (var i = 0; i < replies.length; i++) {
        if (muted.contains(replies[i].tx.fromAddress)) {
          mutedReplies++;
        } else {
          entries.add((replies[i], i + 1));
        }
      }
      // The replies a reply answers, as far as they're shown here.
      List<TxView> quoted(TxView reply, int place) {
        final earlier = [for (final r in replies.take(place - 1)) r.tx.id];
        return [
          for (final quote in quotesOf(client, reply))
            if (quotedReply(earlier, quote) case final id?)
              if (!muted.contains(replies[earlier.indexOf(id)].tx.fromAddress)) replies[earlier.indexOf(id)],
        ];
      }

      // Every block referencing the thread or its replies is found by its
      // filter and fetched, so the thread is complete wherever its replies are.
      client.watchThread(root, [for (final (v, _) in entries) v]);
      // Withdrawn by its author: said first, and the thread shown faded.
      final withdrawn = client.selfFlagged(root);
      final mine = root.tx.fromAddress == wallets.wallet?.addressHex;
      final lead = withdrawn ? 1 : 0;

      return Scaffold(
        appBar: AppBar(
          title: Text('${l.kindThread} · ${l.replyCount(entries.length - 1)}'),
          actions: [StarButton(rootTxid), ShareButton(threadLink(rootTxid), subject: 'Murmur', size: 24)],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          itemCount: lead + entries.length + (mutedReplies > 0 ? 1 : 0),
          itemBuilder: (context, i) {
            if (withdrawn && i == 0) {
              return Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const MurmurIcon(Glyph.flag),
                  title: Text(mine ? l.threadWithdrawnMineNote : l.threadWithdrawnNote),
                ),
              );
            }
            i -= lead;
            if (i == entries.length) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text(l.mutedRepliesHidden(mutedReplies),
                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              );
            }
            final (view, place) = entries[i];
            final card = Padding(
              padding: EdgeInsetsDirectional.only(start: place == 0 ? 0 : 20),
              child: _MessageCard(
                view: view,
                client: client,
                quoted: place == 0 ? const [] : quoted(view, place),
                isRoot: place == 0,
                highlighted: view.tx.id == focusTxid,
                canAct: wallets.wallet != null,
                flagged: wallets.wallet != null && client.hasFlagged(wallets.wallet!.addressHex, view.tx.id),
              ),
            );
            return withdrawn ? Opacity(opacity: 0.55, child: card) : card;
          },
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
    required this.isRoot,
    required this.highlighted,
    required this.canAct,
    required this.flagged,
  });

  final TxView view;
  final MurmurClient client;

  /// The replies this one answers.
  final List<TxView> quoted;
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
          for (final q in quoted) _Quote(q),
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
/// starts. A tap shows all of it.
class _Quote extends StatelessWidget {
  const _Quote(this.view);

  final TxView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final copper = theme.colorScheme.primary;
    final author = Row(mainAxisSize: MainAxisSize.min, children: [
      AddressAvatar(view.tx.fromAddress, size: 16),
      const SizedBox(width: 6),
      Flexible(
        child: Text(nameOf(context, view.tx.fromAddress),
            overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: copper)),
      ),
    ]);
    final text = messageOrUnavailable(context, view);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => showAppDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            title: author,
            content: MessageText(text, selectable: true),
            actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l10n.done))],
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsetsDirectional.only(start: 10, top: 2, bottom: 2),
          decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: copper, width: 3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            author,
            const SizedBox(height: 2),
            MessageText(text.replaceAll('\n', ' '),
                maxLines: 2, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}
