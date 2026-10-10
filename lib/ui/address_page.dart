import 'package:flutter/material.dart';

import '../protocol/models.dart';
import '../services/node_client.dart';
import 'common.dart';
import 'compose_page.dart';
import 'paged_list.dart';
import 'glyphs.dart';

class AddressPage extends StatelessWidget {
  const AddressPage({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppBuilder(builder: (context, client, wallets) {
      final theme = Theme.of(context);
      final isMine = wallets.wallet?.addressHex == address;
      final prefs = AppScope.of(context).prefs;
      final pending = client.pendingDebitOf(address);
      // Its whole history is found through block filters.
      client.watchAddress(address, mentions: true);
      return Scaffold(
        appBar: AppBar(title: Text(isMine ? l.yourAddress : l.address)),
        body: PagedList<TxView>(
          resetKey: address,
          fetch: (n) => client.activityOf(address).take(n).toList(),
          itemBuilder: (context, v) => TxTile(v, perspective: address),
          dividerIndent: null,
          empty: Padding(padding: const EdgeInsets.all(16), child: Text(l.noTransactions)),
          loadingMore: client.historyPending(address),
          onNeedMore: client.requestOlder,
          header: [
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      AddressAvatar(address, size: 56),
                      const SizedBox(width: 16),
                      Expanded(child: Text(nameOf(context, address), style: theme.textTheme.titleLarge)),
                      // Followed in the Starred tab (not oneself).
                      if (!isMine) StarButton.person(address),
                    ]),
                    const SizedBox(height: 8),
                    HashText(address, qr: addressLink(address), qrCaption: l.addressQrHint),
                    // Names and mutes are this device's own.
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      OutlinedButton.icon(
                        icon: const MurmurIcon(Glyph.edit, size: 18),
                        label: Text(l.nameAddress),
                        onPressed: () => editAlias(context, address),
                      ),
                      if (!isMine)
                        OutlinedButton.icon(
                          icon: MurmurIcon(prefs.muted.contains(address) ? Glyph.show : Glyph.hide, size: 18),
                          label: Text(prefs.muted.contains(address) ? l.unmute : l.mute),
                          onPressed: () => prefs.setMuted(address, !prefs.muted.contains(address)),
                        ),
                    ]),
                    if (prefs.muted.contains(address)) ...[
                      const SizedBox(height: 8),
                      Text(l.mutedNote, style: theme.textTheme.bodySmall),
                    ],
                    const SizedBox(height: 12),
                    Text(l.balance, style: theme.textTheme.labelLarge),
                    BalanceText(client: client, address: address, style: theme.textTheme.headlineMedium),
                    if (pending > 0) Text(l.pendingCommitted(formatAmount(context, pending))),
                    // Counted from the chain, so only known with a local copy.
                    if (client.blocksMinedBy(address) > 0) Text(l.blocksMined(client.blocksMinedBy(address))),
                    if (wallets.wallet != null && !isMine) ...[
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        icon: const MurmurIcon(Glyph.send),
                        label: Text(l.sendToAddress),
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ComposePage(kind: TxKind.raw, to: address),
                        )),
                      ),
                    ],
                  ]),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
