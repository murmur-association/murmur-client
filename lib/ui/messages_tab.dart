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
      // What it sent, what credited it, the flags against its messages and
      // the answers to its replies.
      client.watchAddress(me, mentions: true);
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
            // What others wrote to it is marked until opened.
            itemBuilder: (context, v) {
              final unread = v.confirmed && v.tx.fromAddress != me && prefs.isUnread(v.tx.id, activityTime(v));
              return TxTile(v,
                  showCounts: true,
                  unread: unread,
                  onOpen: unread ? () => prefs.markOpened(v.tx.id, activityTime(v)) : null);
            },
            empty: EmptyState(icon: Glyph.outbox, text: l.noMessages),
            loadingMore: client.historyPending(me) || client.historyHasEarlier(me),
            onNeedMore: () => client.readEarlierHistory(me),
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
          MessageFilter.mentioned => l.filterMentions,
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
