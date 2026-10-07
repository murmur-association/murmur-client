import 'dart:convert';

import 'package:flutter/material.dart';

import '../protocol/bytes.dart';
import '../protocol/invite.dart';
import '../services/invitations.dart';
import '../services/key_vault.dart';
import '../services/node_client.dart';
import '../services/storage.dart';
import 'brand.dart';
import 'claim_page.dart';
import 'common.dart';
import 'glyphs.dart';
import 'print_sheet.dart';
import 'qr.dart';
import 'unlock.dart';

/// The invitations this device made (their codes hold keys, and are kept
/// encrypted: see [InviteStore]).
final inviteStore = InviteStore();

String _linkOf(String code) => inviteLink(appBaseUrl, code);

/// The codes of `records` by card address, for one use, after the device's
/// check or the passphrase: asked every time a card is shown, printed or
/// cancelled. Null (and a note) if that doesn't happen.
Future<Map<String, String>?> unlockCards(BuildContext context, List<InviteRecord> records) async {
  final l = context.l10n;
  try {
    final codes =
        await inviteStore.unlock(records, DialogPrompts(context), reason: l.authReasonCards);
    return {for (final (i, r) in records.indexed) r.address: codes[i]};
  } on VaultLocked catch (e) {
    if (context.mounted) showSnack(context, e.wrongPassphrase ? l.wrongPassphrase : l.authFailed);
    return null;
  }
}

/// The inviter's side, in one list: every card with its account picture
/// and QR code button, checkboxes, and Cancel and Print for the selected
/// ones.
class InvitationsPage extends StatefulWidget {
  const InvitationsPage({super.key});

  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  /// Selected cards, by address.
  final _selected = <String>{};
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    inviteStore.load();
  }

  /// Takes the selected cards' tokens back, after asking once: whoever has
  /// them can no longer claim them. When a card was funded by another
  /// wallet than the one here now, it also asks where the tokens go. Then
  /// the cards are unlocked: cancelling signs with each card's own key.
  Future<void> _cancel(List<InviteRecord> records) async {
    final scope = AppScope.of(context);
    final l = context.l10n;
    if (records.isEmpty) return;
    final to = await askCancel(context, records);
    if (to == null || !mounted) return;
    final codes = await unlockCards(context, records);
    if (codes == null || !mounted) return;
    setState(() => _cancelling = true);
    try {
      for (final r in records) {
        final String? destination = switch (to) {
          ReturnTo.funder => funderOf(scope.client, r),
          ReturnTo.current => scope.wallets.wallet?.addressHex,
        };
        // The dialog offers only destinations every card has.
        if (destination == null) continue;
        await sweepInvitation(
            client: scope.client, invite: Invite.parse(codes[r.address]!)!, to: fromHex(destination));
        await inviteStore.markTookBack(r);
        _selected.remove(r.address);
      }
    } on TxProblem catch (e) {
      if (mounted) showSnack(context, txProblemText(l, e));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  /// Asks which name the cards show (the wallet here now may not be the one
  /// that funded them), unlocks the cards, then prints.
  Future<void> _print(List<InviteRecord> records) async {
    final from = await askCardName(context, records);
    if (from == null || !mounted) return;
    final codes = await unlockCards(context, records);
    if (codes == null || !mounted) return;
    printHtml(cardSheet(context, records, codes: codes, from: from));
  }

  Future<void> _create() async {
    final records = await showAppDialog<List<InviteRecord>>(context: context, builder: (_) => const CreateInvitationsDialog());
    if (records == null || !mounted) return;
    // The new cards come selected, ready to print.
    setState(() => _selected
      ..clear()
      ..addAll(records.map((r) => r.address)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppBuilder(builder: (context, client, wallets) {
      return ListenableBuilder(
        listenable: inviteStore,
        builder: (context, _) {
          final records = inviteStore.invites.reversed.toList();
          final states = {for (final r in records) r.address: inviteState(client, r)};
          // Only cards that can still be claimed can be printed or cancelled.
          // (A selection is kept while a new card is still being checked.)
          final selectable = [
            for (final r in records)
              if (states[r.address] == InviteState.waiting) r
          ];
          final chosen = [
            for (final r in selectable)
              if (_selected.contains(r.address)) r
          ];
          final live = client.state == LinkState.live;
          final theme = Theme.of(context);
          return Scaffold(
            appBar: AppBar(title: Text(l.invitations), actions: [
              TextButton(onPressed: () => enterInvitation(context), child: Text(l.haveInvitation)),
            ]),
            floatingActionButton: wallets.wallet == null
                ? null
                : FloatingActionButton.extended(
                    onPressed: live ? _create : null,
                    icon: const MurmurIcon(Glyph.add),
                    label: Text(l.createInvitations),
                  ),
            body: ListView(padding: const EdgeInsets.fromLTRB(8, 8, 8, 96), children: [
              // How cards work, one point each.
              Card(
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    InfoPoint(Glyph.pending, l.inviteNoExpiryPoint, style: theme.textTheme.bodySmall),
                    InfoPoint(Glyph.coin, l.inviteCancelPoint, style: theme.textTheme.bodySmall),
                    InfoPoint(Glyph.show, l.invitePublicPoint, style: theme.textTheme.bodySmall),
                    InfoPoint(Glyph.key, l.inviteCashPoint, style: theme.textTheme.bodySmall),
                    InfoPoint(Glyph.hide, l.inviteLockedPoint, style: theme.textTheme.bodySmall),
                    InfoPoint(Glyph.warning, l.inviteLocalPoint,
                        color: StatusColors.of(context).pending, style: theme.textTheme.bodySmall),
                  ]),
                ),
              ),
              if (selectable.isNotEmpty)
                // Select all, and what applies to the selection.
                Row(children: [
                  Checkbox(
                    tristate: true,
                    value: chosen.isEmpty ? false : (chosen.length == selectable.length ? true : null),
                    onChanged: (_) => setState(() {
                      if (chosen.length == selectable.length) {
                        _selected.clear();
                      } else {
                        _selected.addAll(selectable.map((r) => r.address));
                      }
                    }),
                  ),
                  const Spacer(),
                  if (canPrint)
                    TextButton.icon(
                      icon: const MurmurIcon(Glyph.send, size: 18),
                      label: Text(l.printOne),
                      onPressed: chosen.isEmpty ? null : () => _print(chosen),
                    ),
                  TextButton(
                    onPressed: chosen.isEmpty || !live || _cancelling ? null : () => _cancel(chosen),
                    child: Text(l.cancelInvitation),
                  ),
                ]),
              // Cards that can still be claimed (or are being checked)...
              for (final r in records)
                if (!_done(states[r.address]!))
                  _InviteTile(
                    record: r,
                    state: states[r.address]!,
                    selected: _selected.contains(r.address),
                    onSelected: states[r.address] != InviteState.waiting
                        ? null
                        : (on) => setState(() => on ? _selected.add(r.address) : _selected.remove(r.address)),
                  ),
              // ...then, folded away, the ones that are over.
              if (records.any((r) => _done(states[r.address]!)))
                ExpansionTile(
                  tilePadding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: Text(
                    l.inviteDoneSection(records.where((r) => _done(states[r.address]!)).length),
                    style: theme.textTheme.titleSmall,
                  ),
                  children: [
                    for (final r in records)
                      if (_done(states[r.address]!)) _InviteTile(record: r, state: states[r.address]!),
                  ],
                ),
            ]),
          );
        },
      );
    });
  }
}

bool _done(InviteState s) => s == InviteState.claimed || s == InviteState.cancelled;

/// The wallet (hex) that funded card `r`: kept with the card, or found on
/// the chain. Null while it's still being looked up.
String? funderOf(MurmurClient client, InviteRecord r) => r.funder ?? inviterOf(client, r.address);

/// Where a cancelled card's tokens go.
enum ReturnTo { funder, current }

/// Confirms cancelling `records` (see [_CancelDialog]): where their tokens
/// go, or null if the user keeps them.
Future<ReturnTo?> askCancel(BuildContext context, List<InviteRecord> records) =>
    showAppDialog<ReturnTo>(context: context, builder: (_) => _CancelDialog(records: records));

/// "Cancel n invitations?", and, when a card was funded by another wallet
/// than the one here now (the cards stay when the wallet changes), where
/// the tokens go: back to the wallet that funded each card, or to this one.
class _CancelDialog extends StatefulWidget {
  const _CancelDialog({required this.records});

  final List<InviteRecord> records;

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  ReturnTo? _choice;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppBuilder(builder: (context, client, wallets) {
      final me = wallets.wallet?.addressHex;
      final funders = [for (final r in widget.records) funderOf(client, r)];
      final known = funders.every((f) => f != null);
      // Nothing to ask: every card goes back to the wallet that funded it,
      // which is the one here.
      final ask = !(known && me != null && funders.every((f) => f == me));
      bool usable(ReturnTo t) => t == ReturnTo.funder ? known : me != null;
      final choice =
          _choice != null && usable(_choice!) ? _choice : [ReturnTo.funder, ReturnTo.current].where(usable).firstOrNull;
      final distinct = {...funders.whereType<String>()};
      final funderLine = !known
          ? l.inviteFromChecking
          : distinct.length == 1
              ? nameOf(context, distinct.first)
              : l.inviteFromMixed;

      return AlertDialog(
        scrollable: true,
        title: Text(l.cancelInviteTitle(widget.records.length)),
        content: SizedBox(
          width: 460,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.cancelInviteBody(widget.records.length)),
            if (ask) ...[
              const SizedBox(height: 16),
              Text(l.cancelReturnTo, style: Theme.of(context).textTheme.titleSmall),
              RadioGroup<ReturnTo>(
                groupValue: choice,
                onChanged: (t) => setState(() => _choice = t),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  RadioListTile<ReturnTo>(
                    value: ReturnTo.funder,
                    enabled: usable(ReturnTo.funder),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.cancelToFunder),
                    subtitle: Text(funderLine, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  RadioListTile<ReturnTo>(
                    value: ReturnTo.current,
                    enabled: usable(ReturnTo.current),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.cancelToCurrent),
                    subtitle: Text(me == null ? l.createWalletFirst : nameOf(context, me),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ),
            ],
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.keepInvitation)),
          FilledButton(
            onPressed: choice == null ? null : () => Navigator.pop(context, choice),
            child: Text(l.cancelInvitation),
          ),
        ],
      );
    });
  }
}

/// Where the name printed on the cards comes from.
enum _From { original, originalAlias, originalPublic, current, currentAlias, currentPublic, custom }

/// Asks which name the cards `records` show (see [_FromDialog]); null if
/// the user cancels.
Future<String Function(InviteRecord)?> askCardName(BuildContext context, List<InviteRecord> records) =>
    showAppDialog<String Function(InviteRecord)>(
      context: context,
      builder: (_) => _FromDialog(records: records),
    );

/// The last choice this session, offered first next time.
_From? _lastFrom;
String _lastCustom = '';

/// Picks the name printed on the cards: the wallet that funded them (its
/// address, the name given to it here, or its public name), the wallet on
/// this device now (the same three), or any text. A public name (PROTOCOL.md
/// Section 7.8) can be picked once it's known for sure to be the latest.
class _FromDialog extends StatefulWidget {
  const _FromDialog({required this.records});

  final List<InviteRecord> records;

  @override
  State<_FromDialog> createState() => _FromDialogState();
}

class _FromDialogState extends State<_FromDialog> {
  _From? _choice = _lastFrom;
  late final _custom = TextEditingController(text: _lastCustom);

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return AppBuilder(builder: (context, client, wallets) {
      final aliases = AppScope.of(context).prefs.aliases;
      final me = wallets.wallet?.addressHex;
      String? funder(InviteRecord r) => funderOf(client, r);
      // A published alias (Section 7.8), shown with the start of its address.
      String? public(String? address) {
        if (address == null) return null;
        // Its history is needed to know its latest alias.
        client.watchAddress(address);
        final alias = client.publishedAlias(address);
        return alias == null ? null : publicNameOf(alias, address);
      }

      /// What an option prints on card `r`; null where it has nothing.
      String? valueOf(_From f, InviteRecord r) => switch (f) {
            _From.original => funder(r) == null ? null : shortHex(funder(r)!),
            _From.originalAlias => funder(r) == null ? null : aliases[funder(r)!],
            _From.originalPublic => public(funder(r)),
            _From.current => me == null ? null : shortHex(me),
            _From.currentAlias => me == null ? null : aliases[me],
            _From.currentPublic => public(me),
            _From.custom => _custom.text,
          };
      // Why an option can't be picked.
      String reasonOf(_From f) => switch (f) {
            _From.original => l.inviteFromChecking,
            _From.originalAlias || _From.currentAlias => l.inviteFromNotSet,
            _ => l.inviteFromNoPublic,
          };
      // The wallet here now, offered apart only if it isn't the funder.
      final sameWallet = widget.records.every((r) => funder(r) == me);
      final options = [
        _From.original,
        _From.originalAlias,
        _From.originalPublic,
        if (me != null && !sameWallet) ...[_From.current, _From.currentAlias, _From.currentPublic],
      ];
      bool usable(_From f) => f == _From.custom || widget.records.every((r) => valueOf(f, r) != null);
      final choice = _choice != null && (_choice == _From.custom || (options.contains(_choice) && usable(_choice!)))
          ? _choice!
          : [_From.originalAlias, _From.originalPublic, _From.original].firstWhere(usable, orElse: () => _From.custom);

      String titleOf(_From f) => switch (f) {
            _From.original => l.inviteFromOriginal,
            _From.originalAlias => l.inviteFromOriginalAlias,
            _From.originalPublic => l.inviteFromOriginalPublic,
            _From.current => l.inviteFromCurrent,
            _From.currentAlias => l.inviteFromCurrentAlias,
            _From.currentPublic => l.inviteFromCurrentPublic,
            _From.custom => l.inviteFromCustom,
          };
      String subtitleOf(_From f) {
        if (!usable(f)) return reasonOf(f);
        final values = {for (final r in widget.records) valueOf(f, r)!};
        return values.length == 1 ? values.first : l.inviteFromMixed;
      }

      return AlertDialog(
        scrollable: true,
        title: Text(l.inviteFromTitle),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: RadioGroup<_From>(
              groupValue: choice,
              onChanged: (f) => setState(() => _choice = f),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.inviteFromBody, style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                for (final f in options)
                  RadioListTile<_From>(
                    value: f,
                    enabled: usable(f),
                    contentPadding: EdgeInsets.zero,
                    title: Text(titleOf(f)),
                    subtitle: Text(subtitleOf(f), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                RadioListTile<_From>(
                  value: _From.custom,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.inviteFromCustom),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16),
                  child: TextField(
                    controller: _custom,
                    maxLength: 40,
                    onTap: () => setState(() => _choice = _From.custom),
                    onChanged: (_) => setState(() => _choice = _From.custom),
                    decoration: InputDecoration(
                      isDense: true,
                      helperText: l.inviteFromCustomHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          FilledButton.icon(
            icon: const MurmurIcon(Glyph.send, size: 18),
            label: Text(l.printOne),
            onPressed: () {
              _lastFrom = choice;
              _lastCustom = _custom.text;
              final custom = _custom.text;
              Navigator.pop<String Function(InviteRecord)>(
                  context, choice == _From.custom ? (_) => custom : (r) => valueOf(choice, r) ?? '');
            },
          ),
        ],
      );
    });
  }
}

/// An amount of tokens: a coin and the number, bold.
class _Amount extends StatelessWidget {
  const _Amount(this.value, {this.style, this.iconSize = 16});

  final int value;
  final TextStyle? style;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final style = (this.style ?? DefaultTextStyle.of(context).style).copyWith(fontWeight: FontWeight.w700);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      MurmurIcon(Glyph.coin, size: iconSize, color: Theme.of(context).colorScheme.primary),
      SizedBox(width: iconSize / 4),
      Text(formatAmount(context, value), style: style),
    ]);
  }
}

/// One card: checkbox (while it can be claimed), account picture, number,
/// state and amount, and a QR icon that, once the cards are unlocked, shows
/// the code large in place, with its link to share.
class _InviteTile extends StatelessWidget {
  const _InviteTile({
    required this.record,
    required this.state,
    this.selected = false,
    this.onSelected,
  });

  final InviteRecord record;
  final InviteState state;
  final bool selected;

  /// Null when the card can't be selected (claimed, cancelled, checking).
  final ValueChanged<bool>? onSelected;

  /// The QR code large, over the list, with the typed code under it and a
  /// button to share its link: after unlocking, since it shows the card's key.
  Future<void> _enlarge(BuildContext context) async {
    final code = (await unlockCards(context, [record]))?[record.address];
    if (code == null || !context.mounted) return;
    showQr(context, _linkOf(code), code: code, subject: context.l10n.inviteCardTitle);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final waiting = state == InviteState.waiting;
    final done = _done(state);
    final small =
        Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.only(start: 0, end: 4),
      leading: Row(mainAxisSize: MainAxisSize.min, children: [
        // Over cards keep the column, without a box to tick.
        done
            ? const SizedBox(width: 48)
            : Checkbox(value: selected, onChanged: onSelected == null ? null : (on) => onSelected!(on ?? false)),
        Opacity(opacity: done ? 0.5 : 1, child: AddressAvatar(record.address, size: 36)),
      ]),
      title: Text(l.inviteCardSerial(record.serial, record.batch)),
      subtitle: Row(children: [
        Text(
          switch (state) {
            InviteState.checking => l.inviteChecking,
            InviteState.waiting => l.inviteWaitingState,
            InviteState.claimed => l.inviteClaimed,
            InviteState.cancelled => l.inviteCancelled,
          },
          style: small,
        ),
        if (!done) ...[Text('  ·  ', style: small), _Amount(record.amount, style: small, iconSize: 14)],
      ]),
      trailing: !waiting
          ? null
          : IconButton(
              icon: const MurmurIcon(Glyph.qr, size: 22),
              tooltip: l.inviteCardHow,
              onPressed: () => _enlarge(context),
            ),
      // Finished cards open their story: who claimed it and when, or when
      // it was cancelled.
      onTap: done
          ? () => showAppDialog<void>(context: context, builder: (_) => _InviteDetails(record))
          : (onSelected == null ? null : () => onSelected!(!selected)),
    );
  }
}

/// A card's story, from its history on the chain: when it was funded, and
/// who claimed it and when (with what they received), or when it was
/// cancelled and what came back.
class _InviteDetails extends StatelessWidget {
  const _InviteDetails(this.record);

  final InviteRecord record;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppBuilder(builder: (context, client, wallets) {
      final theme = Theme.of(context);
      final card = record.address;
      TxView? funding, out;
      // Every block touching the card is found by its filter.
      client.watchAddress(card);
      for (final v in client.activityOf(card)) {
        if (v.tx.fromAddress == card) out ??= v;
        if (v.tx.toAddress == card && v.tx.fromAddress != card) funding ??= v;
      }
      String when(TxView v) => v.blockTime == null ? l.inviteDetailOnItsWay : formatTime(context, v.blockTime!);
      final caption = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
      Widget row(String label, TxView v, {Widget? who}) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: theme.textTheme.titleSmall),
                  if (who != null) who,
                  Text(when(v), style: caption),
                ]),
              ),
              _Amount(v.tx.amount, style: theme.textTheme.titleMedium),
            ]),
          );
      final claimer = out?.tx.toAddress;
      final cancelled = record.tookBack || (claimer != null && claimer == wallets.wallet?.addressHex);
      return AlertDialog(
        scrollable: true,
        title: Row(children: [
          AddressAvatar(card, size: 32),
          const SizedBox(width: 12),
          Text(l.inviteCardSerial(record.serial, record.batch)),
        ]),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 320, maxWidth: 420),
          child: funding == null && out == null
              ? Text(l.inviteChecking, style: caption)
              : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (funding != null) row(l.inviteDetailFunded, funding),
                  if (out != null) ...[
                    const Divider(),
                    // Cancelled: back here, or (after a change of wallet) to
                    // the wallet the user chose, named and linked.
                    if (cancelled && (claimer == null || claimer == wallets.wallet?.addressHex))
                      row(l.inviteDetailReturned, out, who: Text(l.inviteDetailCancelled, style: caption))
                    else if (cancelled)
                      row(l.inviteDetailReturned, out,
                          who: Emphasized(l.inviteDetailCancelledTo(Emphasized.link(nameOf(context, claimer!), 0)),
                              links: [claimer], style: caption, weight: FontWeight.w600))
                    else
                      row(
                        l.inviteDetailClaimedBy,
                        out,
                        who: InkWell(
                          onTap: () => openAddress(context, claimer),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              AddressAvatar(claimer!, size: 24),
                              const SizedBox(width: 8),
                              Text(nameOf(context, claimer), style: TextStyle(color: theme.colorScheme.primary)),
                            ]),
                          ),
                        ),
                      ),
                  ],
                ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.done))],
      );
    });
  }
}

/// How many cards, what they cost, and the button that funds them.
class CreateInvitationsDialog extends StatefulWidget {
  const CreateInvitationsDialog({super.key});

  @override
  State<CreateInvitationsDialog> createState() => _CreateInvitationsDialogState();
}

class _CreateInvitationsDialogState extends State<CreateInvitationsDialog> {
  int _count = 5;
  ({int perCard, int fundingFee, int claimFee})? _costs;
  bool _funding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fees = await AppScope.of(context).client.feeInfo();
      if (mounted) setState(() => _costs = invitationCosts(fees));
    });
  }

  Future<void> _fund() async {
    final scope = AppScope.of(context);
    final l = context.l10n;
    final costs = _costs!;
    // The first cards also put their codes' key under the wallet's
    // passphrase: asked once for both, as funding is one action.
    final prompts = OneAnswer(DialogPrompts(context));
    setState(() => _funding = true);
    try {
      // One unlock for the batch: funding the cards is one action.
      final wallet = await unlockWallet(context, reason: l.authReasonInvite, prompts: prompts);
      if (wallet == null) return;
      final records = await createInvitations(
        client: scope.client,
        wallet: wallet,
        keep: (records, codes) => inviteStore.add(records, codes, prompts, reason: l.authReasonCards),
        count: _count,
        perCard: costs.perCard,
        fundingFee: costs.fundingFee,
      );
      if (mounted) Navigator.pop(context, records);
    } on TxProblem catch (e) {
      if (mounted) showSnack(context, txProblemText(l, e));
    } on VaultLocked catch (e) {
      // The codes' protection wasn't set up: nothing was made or paid.
      if (mounted) showSnack(context, e.wrongPassphrase ? l.wrongPassphrase : l.authFailed);
    } finally {
      if (mounted) setState(() => _funding = false);
    }
  }

  // Rebuilt with the client: what the wallet can spend follows new blocks
  // and transactions, so "not enough" and the button do too.
  @override
  Widget build(BuildContext context) => AppBuilder(builder: (context, _, __) => _dialog(context));

  Widget _dialog(BuildContext context) {
    final l = context.l10n;
    final scope = AppScope.of(context);
    final costs = _costs;
    final total = costs == null ? null : _count * (costs.perCard + costs.fundingFee);
    final available = scope.client.availableTo(scope.wallets.wallet!.addressHex);
    final enough = total != null && available != null && total <= available;
    final theme = Theme.of(context);
    final caption = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    // A label with its explanation beneath, and the amount on the right.
    Widget line(String label, String explanation, Widget value) => Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: theme.textTheme.titleSmall),
              Text(explanation, style: caption),
            ]),
          ),
          const SizedBox(width: 16),
          value,
        ]);
    return AlertDialog(
      scrollable: true,
      title: Text(l.createInvitations),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(l.inviteHowMany, style: theme.textTheme.titleSmall)),
            IconButton.outlined(
              onPressed: _count > 1 ? () => setState(() => _count--) : null,
              icon: const Text('−', style: TextStyle(fontSize: 18)),
            ),
            SizedBox(
              width: 48,
              child: Text(formatAmount(context, _count),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            IconButton.outlined(
              onPressed: _count < 20 ? () => setState(() => _count++) : null,
              icon: const Text('+', style: TextStyle(fontSize: 18)),
            ),
          ]),
          const SizedBox(height: 16),
          if (costs == null)
            Text(l.checkingFees, style: caption)
          else ...[
            line(l.inviteEachLabel, l.inviteEachCaption,
                _Amount(costs.perCard, style: theme.textTheme.titleMedium, iconSize: 18)),
            const Divider(height: 24),
            line(l.inviteTotalLabel, l.inviteTotalCaption,
                _Amount(total!, style: theme.textTheme.headlineSmall, iconSize: 24)),
            if (available != null && !enough)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l.probInsufficientBalance(total, available),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              ),
          ],
          const SizedBox(height: 12),
          InfoPoint(Glyph.pending, l.inviteNoExpiryPoint, style: caption),
          // They exist only here: say so before any are made.
          InfoPoint(Glyph.warning, l.inviteLocalPoint, color: StatusColors.of(context).pending, style: caption),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: enough && !_funding ? _fund : null, child: Text(l.inviteFund)),
      ],
    );
  }
}

/// The logo (murmur-logo.svg), in `color`.
String _logoSvg(String color, {String size = '100%'}) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="$size" height="$size">'
    '<polyline points="15,80 30,25 50,60 70,25 85,80" fill="none" stroke="$color" stroke-width="6" '
    'stroke-linejoin="round" stroke-linecap="round"/>'
    '<circle cx="15" cy="80" r="8.5" fill="$color"/>'
    '<circle cx="30" cy="25" r="7.5" fill="none" stroke="$color" stroke-width="5"/>'
    '<circle cx="50" cy="60" r="7.5" fill="none" stroke="$color" stroke-width="5"/>'
    '<circle cx="70" cy="25" r="7.5" fill="none" stroke="$color" stroke-width="5"/>'
    '<circle cx="85" cy="80" r="8.5" fill="$color"/></svg>';

/// A printable page of business cards (85 x 55 mm): the logo and name, a
/// faded logo as a watermark, the slogan, the QR code, who it's from and
/// "n of N", and the typed code. In the app's copper-on-paper colours.
/// Self-contained HTML (SVG, inline styles): nothing is fetched. `codes`
/// are the cards' codes by address (`unlockCards`), and `from` gives each
/// card's sender line; an empty one leaves it out.
String cardSheet(BuildContext context, List<InviteRecord> records,
    {required Map<String, String> codes, required String Function(InviteRecord) from}) {
  final l = context.l10n;
  String esc(String s) => const HtmlEscape().convert(s);
  const copper = '#C1703A', ink = '#17171A';
  final cards = StringBuffer();
  for (final r in records) {
    final sender = from(r).trim();
    final code = codes[r.address]!;
    cards.write('<div class="card">'
        '<div class="mark">${_logoSvg(copper)}</div>'
        '<div class="main">'
        '<div class="brand"><span class="logo">${_logoSvg(copper, size: '7mm')}</span>'
        '<span class="name">Murmur</span></div>'
        '<div class="slogan">${esc(l.inviteCardSlogan)}</div>'
        '<div class="meta"><b>${esc(l.inviteCardTitle)}</b><br>'
        '${sender.isEmpty ? '' : '${esc(l.inviteCardFrom(sender))} · '}'
        '${esc(l.inviteCardSerial(r.serial, r.batch))}</div>'
        '</div>'
        '<div class="side"><div class="qr">${qrSvg(_linkOf(code), size: '27mm')}</div>'
        '<div class="scan">${esc(l.inviteCardJoin)}</div></div>'
        '<div class="code">${esc(code)}</div>'
        '</div>');
  }
  final dir = Directionality.of(context) == TextDirection.rtl ? 'rtl' : 'ltr';
  return '<!doctype html><html lang="${l.localeName}" dir="$dir">'
      '<head><meta charset="utf-8"><title>${esc(l.invitations)}</title><style>'
      '@page{margin:10mm}'
      '*{-webkit-print-color-adjust:exact;print-color-adjust:exact;box-sizing:border-box}'
      'body{margin:0;font-family:system-ui,-apple-system,"Segoe UI",sans-serif;color:$ink}'
      '.grid{display:grid;grid-template-columns:repeat(2,85mm);gap:6mm}'
      '.card{position:relative;overflow:hidden;width:85mm;height:55mm;border-radius:3.5mm;'
      'background:#F8F5F0;border:.25mm solid #E2DAD0;padding:5mm 5mm 4mm;display:grid;'
      'grid-template-columns:1fr 29mm;grid-template-rows:1fr auto;column-gap:4mm;break-inside:avoid}'
      '.card::before{content:"";position:absolute;inset-block:0;inset-inline-start:0;width:1.4mm;background:$copper}'
      '.mark{position:absolute;width:48mm;height:48mm;inset-inline-start:-8mm;bottom:-14mm;opacity:.07}'
      '.main{position:relative;display:flex;flex-direction:column;justify-content:space-between;min-width:0}'
      '.brand{display:flex;align-items:center;gap:2mm}'
      '.name{font-size:13pt;font-weight:600;letter-spacing:.02em}'
      '.slogan{font-size:10.5pt;line-height:1.25;color:$copper;font-weight:500}'
      '.meta{font-size:7.5pt;line-height:1.4;color:#4a4540}'
      '.side{position:relative;display:flex;flex-direction:column;align-items:center;gap:1mm}'
      '.qr{background:#fff;border-radius:2mm;padding:1mm;line-height:0}'
      '.scan{font-size:7pt;font-weight:600;color:$copper;letter-spacing:.03em}'
      '.code{position:relative;grid-column:1 / 3;margin-top:2mm;padding-top:1.5mm;border-top:.2mm solid #E2DAD0;'
      'font-family:ui-monospace,Consolas,monospace;font-size:5.6pt;letter-spacing:.02em;color:#6b645c;'
      'word-break:break-all;direction:ltr;unicode-bidi:isolate}'
      '</style></head><body><div class="grid">$cards</div>'
      '<script>window.onload=function(){window.print()}</script></body></html>';
}
