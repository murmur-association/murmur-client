import 'package:flutter/material.dart';

import '../protocol/alias.dart';
import '../protocol/bytes.dart';
import '../protocol/models.dart';
import '../services/node_client.dart';
import 'common.dart';
import 'brand.dart';
import 'chain_tab.dart';
import 'compose_page.dart';
import 'emoji.dart';
import 'glyphs.dart';

class TxPage extends StatelessWidget {
  const TxPage({super.key, required this.txid});

  final String txid;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppBuilder(builder: (context, client, wallets) {
      final view = client.lookupTx(txid);
      if (view == null) {
        // Asked of the node by id, with a merkle branch to its block.
        client.requestTx(txid);
        return Scaffold(
          appBar: AppBar(title: Text(l.txTitle)),
          body: client.isUnknownTx(txid) || !client.isOnline
              ? EmptyState(icon: Glyph.unknown, text: l.txNotFound)
              : EmptyState(icon: Glyph.search, text: l.txSearching),
        );
      }
      final tx = view.tx;
      final theme = Theme.of(context);
      final text = liveMessageText(context, view);
      final isMessage = tx.kind == TxKind.orphan || tx.kind == TxKind.reply;
      // A public name (PROTOCOL.md Section 7.8) is an Orphan underneath,
      // but no thread: called what it is, and not starred.
      final content = client.liveContent(view);
      final isAlias = tx.kind == TxKind.name && content != null && aliasOf(messageOf(content)) != null;
      final kind = isAlias ? l.publicName : kindLabel(context, tx.kind);
      final canAct = wallets.wallet != null && isMessage;
      final alreadyFlagged = canAct && client.hasFlagged(wallets.wallet!.addressHex, tx.id);
      // What a Reply answers or a Flag reports.
      final target = client.referenced(view);
      final threaded = tx.kind != TxKind.reply || client.isThreadedReply(view);
      String n(int v) => formatAmount(context, v);

      return Scaffold(
        appBar: AppBar(title: Text(kind), actions: [if (isMessage && !client.isNonText(view)) StarButton(tx.id)]),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          _StatusCard(view: view, client: client),
          if (tx.referenceId != null)
            Card(
              child: ListTile(
                leading: MurmurIcon(tx.kind == TxKind.flag ? Glyph.flag : Glyph.reply),
                title: target == null
                    ? Text(l.refNotLocal(shortHex(tx.referenceId!)))
                    : MessageText(messageOrUnavailable(context, target)),
                subtitle: Text(tx.kind == TxKind.flag
                    ? l.flaggedMessage
                    : threaded
                        ? l.inReplyTo
                        : l.notThreadedExplain),
                trailing: target == null ? null : const MurmurIcon(Glyph.openInNew),
                onTap: target == null ? null : () => openMessage(context, target),
              ),
            ),
          if (tx.kind != TxKind.flag && tx.messageHash != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.message, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  MessageText(
                    text ?? messageOrUnavailable(context, view),
                    selectable: true,
                    style: text == null ? TextStyle(color: theme.colorScheme.outline) : theme.textTheme.bodyLarge,
                  ),
                  if (canAct) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      // A message that isn't text (an alias, say) is neither
                      // replied to nor a thread (Section 2.4).
                      if (!client.isNonText(view))
                        FilledButton.tonalIcon(
                          icon: const MurmurIcon(Glyph.reply),
                          label: Text(l.actionReply),
                          // Only mined messages can be replied to (Section 2.4).
                          onPressed: !view.confirmed ? null : () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ComposePage(replyTo: view),
                          )),
                        ),
                      if (!client.isNonText(view) && client.threadRootOf(view) != null)
                        OutlinedButton.icon(
                          icon: const MurmurIcon(Glyph.thread),
                          label: Text(l.openThread),
                          onPressed: () => openMessage(context, view),
                        ),
                      OutlinedButton.icon(
                        icon: const MurmurIcon(Glyph.flag),
                        label: Text(alreadyFlagged ? l.flagged : l.actionFlag),
                        onPressed: alreadyFlagged ? null : () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ComposePage(flagTarget: view),
                        )),
                      ),
                    ]),
                  ],
                ]),
              ),
            ),
          const SizedBox(height: 8),
          InfoRow(l.transactionId, HashText(tx.id)),
          InfoRow(l.type, Text(kind)),
          InfoRow(l.from, HashText(tx.fromAddress, onTap: () => openAddress(context, tx.fromAddress))),
          // Who it credits: a transfer's recipient, or for a reply the author
          // of its thread, which the chain pays.
          if (client.creditedBy(tx) case final paid?)
            InfoRow(l.to, HashText(paid, onTap: () => openAddress(context, paid))),
          if (tx.kind.startsThread)
            InfoRow(l.burned, Text(l.burnedValue(n(tx.burned))))
          else
            InfoRow(l.amount, Text(n(tx.amount))),
          InfoRow(l.fee, Text(n(tx.fee))),
          if (tx.messageHash != null) ...[
            InfoRow(l.contentHash, HashText(toHex(tx.messageHash!))),
            InfoRow(l.contentSize, Text(l.contentSizeValue(tx.contentSize, saltLength, tx.contentSize - saltLength))),
          ],
          if (tx.referenceId != null)
            InfoRow(tx.kind == TxKind.flag ? l.reports : l.repliesTo,
                HashText(tx.referenceId!, onTap: target == null ? null : () => openTx(context, target.tx.id))),
          InfoRow(l.weight, Text(l.weightValue(tx.weight, n(tx.fee ~/ tx.weight)))),
          InfoRow(l.publicKey, HashText(toHex(tx.pubkey))),
        ]),
      );
    });
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.view, required this.client});

  final TxView view;
  final MurmurClient client;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final status = StatusColors.of(context);
    // What the node answered when this client submitted it (advisory).
    final answer = client.statusOf(view.tx.id);
    final (Glyph icon, Color color, String title, String detail) = switch (view) {
      TxView(height: final int h) => (
          Glyph.confirmed,
          status.success,
          l.confirmedIn(h),
          l.confirmationCount(client.height - h + 1),
        ),
      TxView(pending: PendingTx(mine: true))
          when answer != null && (answer.code == TxStatusCode.refused || answer.code == TxStatusCode.invalid) =>
        (
          Glyph.error,
          status.danger,
          answer.code == TxStatusCode.refused ? l.statusRefused : l.statusInvalid,
          l.nodeReason(answer.reason),
        ),
      TxView(pending: PendingTx(mine: true, sentAtHeight: final int sent))
          when client.height - sent >= MurmurClient.staleAfterBlocks =>
        (
          Glyph.warning,
          status.danger,
          l.notConfirmedAfter(client.height - sent),
          l.maybeRefused,
        ),
      TxView(pending: PendingTx(mine: true)) => (
          Glyph.pending,
          status.pending,
          l.sentWaiting,
          answer == null ? l.submittedHere : l.statusAccepted,
        ),
      _ => (Glyph.pending, status.pending, l.pendingTitle, l.relayedPending),
    };
    return Card(
      child: ListTile(
        leading: MurmurIcon(icon, color: color),
        title: Text(title),
        subtitle: Text(detail),
        trailing: view.height != null
            ? TextButton(onPressed: () => openBlock(context, view.height!), child: Text(l.viewBlock))
            : null,
      ),
    );
  }
}
