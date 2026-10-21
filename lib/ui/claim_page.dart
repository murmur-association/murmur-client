import 'package:flutter/material.dart';

import '../protocol/invite.dart';
import '../services/invitations.dart';
import '../services/node_client.dart';
import 'common.dart';
import 'glyphs.dart';
import 'seed.dart';

/// Opening an invitation (a card's QR code or link): who it's from, what it
/// holds, and one button that moves it into the newcomer's wallet, created
/// on the spot if there's none. The claim's fee comes out of the card.
class ClaimPage extends StatefulWidget {
  const ClaimPage({super.key, required this.code});

  final String code;

  @override
  State<ClaimPage> createState() => _ClaimPageState();
}

class _ClaimPageState extends State<ClaimPage> {
  late final Invite? _invite = Invite.parse(widget.code);
  String? _card;
  bool _claiming = false;
  bool _claimed = false;

  @override
  void initState() {
    super.initState();
    final invite = _invite;
    if (invite != null) {
      cardWallet(invite).then((w) {
        if (mounted) setState(() => _card = w.addressHex);
      });
    }
  }

  Future<void> _claim() async {
    final scope = AppScope.of(context);
    final l = context.l10n;
    setState(() => _claiming = true);
    try {
      if (scope.wallets.wallet == null &&
          !await createWallet(context)) {
        return;
      }
      await sweepInvitation(client: scope.client, invite: _invite!, to: scope.wallets.wallet!.address);
      if (mounted) setState(() => _claimed = true);
    } on TxProblem catch (e) {
      if (mounted) showSnack(context, txProblemText(l, e));
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppBuilder(builder: (context, client, wallets) {
      final theme = Theme.of(context);
      final invite = _invite;
      final card = _card;
      Widget body;
      if (invite == null) {
        body = EmptyState(icon: Glyph.unknown, text: l.claimInvalid);
      } else if (client.genesis != null && !invite.isFor(client.genesis!)) {
        body = EmptyState(icon: Glyph.warning, text: l.claimWrongNetwork);
      } else if (_claimed) {
        body = EmptyState(icon: Glyph.confirmed, text: l.claimDone);
      } else {
        // The card's balance, proven; and who funded it, once its history
        // is found.
        final balance = card == null ? null : client.availableTo(card);
        if (card != null) client.watchAddress(card);
        final inviter = card == null ? null : inviterOf(client, card);
        // Freshly made, its funding may still be on its way to a block.
        final funding = card != null && client.activityOf(card).any((v) => !v.confirmed && v.tx.toAddress == card);
        if (balance == 0 && !funding) {
          body = EmptyState(icon: Glyph.unknown, text: l.claimEmpty);
        } else {
          body = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (inviter != null) ...[
                    AddressAvatar(inviter, size: 72),
                    const SizedBox(height: 12),
                    Text(l.claimInvitedBy(nameOf(context, inviter)), style: theme.textTheme.titleMedium),
                  ] else
                    MurmurIcon(Glyph.wallet, size: 72, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(balance == null || balance == 0 ? l.inviteChecking : l.claimHolds(formatAmount(context, balance)),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: _claiming
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const MurmurIcon(Glyph.wallet),
                    label: Text(wallets.wallet == null ? l.claimCreateWallet : l.claimIntoWallet),
                    onPressed:
                        balance == null || balance == 0 || _claiming || client.state != LinkState.live ? null : _claim,
                  ),
                  if (client.state != LinkState.live) ...[
                    const SizedBox(height: 8),
                    Text(l.sendingNeedsLive, style: theme.textTheme.bodySmall),
                  ],
                ]),
              ),
            ),
          );
        }
      }
      return Scaffold(appBar: AppBar(title: Text(l.claimTitle)), body: body);
    });
  }
}

/// Asks for an invitation code (or link) and opens it.
Future<void> enterInvitation(BuildContext context) async {
  final l = context.l10n;
  final code = await showAppDialog<String>(
    context: context,
    builder: (context) => WithTextController(builder: (context, controller) => AlertDialog(
      scrollable: true,
      title: Text(l.haveInvitation),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: mono,
        decoration: InputDecoration(labelText: l.inviteCodeField, border: const OutlineInputBorder()),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l.claim)),
      ],
    )),
  );
  if (code == null || code.trim().isEmpty || !context.mounted) return;
  if (Invite.parse(code) == null) {
    showSnack(context, l.claimInvalid);
    return;
  }
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClaimPage(code: code.trim())));
}
