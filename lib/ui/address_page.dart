import 'package:flutter/material.dart';

import '../protocol/models.dart';
import '../services/node_client.dart';
import 'common.dart';
import 'compose_page.dart';
import 'paged_list.dart';
import 'glyphs.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key, required this.address, this.heroTag, this.newSince});

  final String address;

  /// The flight of the picture this page was opened from (`AvatarLink`):
  /// it lands on the page's own.
  final Object? heroTag;

  /// Opened from a marked starred person: the messages they wrote after this
  /// (Unix seconds) are marked until opened, and a line under them says
  /// they're new. Only on this opening: other ways here show the page plain.
  final int? newSince;

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  String get address => widget.address;
  Object? get heroTag => widget.heroTag;
  int? get newSince => widget.newSince;

  /// The new messages opened from here: no longer marked when back.
  final _opened = <String>{};

  /// Whether `v` is what lit up the person's starred row and hasn't been
  /// opened from here: a message they wrote after [newSince], counted as the
  /// Starred tab counts them.
  bool _marked(MurmurClient client, TxView v) => _isNew(client, v) && !_opened.contains(v.tx.id);

  /// Whether `v` is a message they wrote after [newSince], counted as the
  /// Starred tab counts them. The line stays under these, opened or not.
  bool _isNew(MurmurClient client, TxView v) =>
      newSince != null &&
      v.confirmed &&
      v.tx.fromAddress == address &&
      activityTime(v) > newSince! &&
      !client.selfFlagged(v) &&
      !client.isNonText(v);

  /// The first `n` rows: the address's history, newest first, with the line
  /// under its new messages where the older ones begin.
  List<Object> _rows(MurmurClient client, int n) {
    final rows = <Object>[];
    var sawNew = false;
    var marked = false;
    for (final v in client.activityOf(address)) {
      if (rows.length >= n) break;
      if (_isNew(client, v)) {
        sawNew = true;
      } else if (sawNew && !marked && v.confirmed && activityTime(v) <= newSince!) {
        rows.add(const _NewAbove());
        marked = true;
        if (rows.length >= n) break;
      }
      rows.add(v);
    }
    return rows;
  }

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
      final avatar = AddressAvatar(address, size: 56);
      return Scaffold(
        appBar: AppBar(title: Text(isMine ? l.yourAddress : l.address)),
        body: PagedList<Object>(
          resetKey: address,
          fetch: (n) => _rows(client, n),
          itemBuilder: (context, row) => switch (row) {
            TxView v => TxTile(v,
                perspective: address,
                unread: _marked(client, v),
                onOpen: () => setState(() => _opened.add(v.tx.id))),
            _ => const _NewAboveLine(),
          },
          dividerIndent: null,
          empty: Padding(padding: const EdgeInsets.all(16), child: Text(l.noTransactions)),
          loadingMore: client.historyPending(address) || client.historyHasEarlier(address),
          onNeedMore: () => client.readEarlierHistory(address),
          header: [
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      // A tap shows the picture larger.
                      Tooltip(
                        message: l.pictureLarger,
                        child: InkResponse(
                          onTap: () => _showLarger(context),
                          radius: 40,
                          child: heroTag == null ? avatar : Hero(tag: heroTag!, child: avatar),
                        ),
                      ),
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
                    // Proven with the balance, since genesis.
                    if ((client.blocksMinedBy(address) ?? 0) > 0) Text(l.blocksMined(client.blocksMinedBy(address)!)),
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

  /// The picture as large as the screen allows, with the name under it; a
  /// tap anywhere on it closes it.
  void _showLarger(BuildContext context) {
    showAppDialog<void>(
      context: context,
      builder: (context) {
        final side = (MediaQuery.sizeOf(context).shortestSide - 96).clamp(120.0, 360.0);
        return Dialog(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AddressAvatar(address, size: side),
                const SizedBox(height: 16),
                SizedBox(
                  width: side,
                  child: Text(nameOf(context, address),
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

/// Where a starred person's new messages end, in their history.
class _NewAbove {
  const _NewAbove();
}

/// The line under the new messages: a copper rule saying what it means.
class _NewAboveLine extends StatelessWidget {
  const _NewAboveLine();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final rule = Expanded(child: Divider(color: color, thickness: 1.5));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        rule,
        Flexible(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(context.l10n.newAboveLastVisit,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ),
        ),
        rule,
      ]),
    );
  }
}
