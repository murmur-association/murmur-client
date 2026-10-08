import 'package:flutter/material.dart';

import '../services/activity.dart';
import '../services/node_client.dart';
import 'common.dart';
import 'paged_list.dart';
import 'glyphs.dart';

/// The current wallet's messages, newest first: threads it started, replies
/// it sent and received, and (when chosen) flags it raised or received.
/// Plain transfers are in the Wallet tab. The list follows new blocks.
class MessagesTab extends StatelessWidget {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = AppScope.of(context).prefs;
    return AppBuilder(builder: (context, client, wallets) {
      final wallet = wallets.wallet;
      if (wallet == null) {
        return EmptyState(icon: Glyph.wallet, text: l.messagesNeedWallet);
      }
      final me = wallet.addressHex;
      // What it sent, what credited it, and the flags against its messages.
      client.watchAddress(me, flags: true);
      return ListenableBuilder(
        listenable: prefs,
        builder: (context, _) {
          final filters = prefs.messageFilters;
          // Muted addresses' replies and flags stay out of sight here too.
          bool shown(TxView v) =>
              !prefs.muted.contains(v.tx.fromAddress) && messageFiltersOf(v, me, client).any(filters.contains);
          return PagedList<TxView>(
            // Another wallet or other filters start the list over.
            resetKey: (me, filters.fold(0, (mask, f) => mask | (1 << f.index))),
            fetch: (n) => client.activityOf(me).where(shown).take(n).toList(),
            itemBuilder: (context, v) => TxTile(v, showCounts: true),
            empty: EmptyState(icon: Glyph.outbox, text: l.noMessages),
            loadingMore: client.historyPending(me),
            onNeedMore: client.requestOlder,
            header: [
              SliverToBoxAdapter(
                child: _FilterChips(
                  selected: filters,
                  onChanged: prefs.setMessageFilters,
                ),
              ),
            ],
          );
        },
      );
    });
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged});

  final Set<MessageFilter> selected;
  final ValueChanged<Set<MessageFilter>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String label(MessageFilter f) => switch (f) {
          MessageFilter.threads => l.filterThreads,
          MessageFilter.sent => l.filterRepliesSent,
          MessageFilter.received => l.filterRepliesReceived,
          MessageFilter.flagsSent => l.filterFlagsSent,
          MessageFilter.flagsReceived => l.filterFlagsReceived,
        };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(children: [
        for (final f in MessageFilter.values)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilterChip(
              label: Text(label(f)),
              selected: selected.contains(f),
              onSelected: (on) => onChanged(on ? {...selected, f} : selected.difference({f})),
            ),
          ),
      ]),
    );
  }
}
