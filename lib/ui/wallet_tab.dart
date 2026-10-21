import 'dart:convert';

import 'package:flutter/material.dart';

import '../protocol/alias.dart';
import '../protocol/bytes.dart';
import '../protocol/profile.dart';
import '../services/activity.dart';
import '../services/node_client.dart';
import '../services/picture.dart';
import '../services/storage.dart';
import 'brand.dart';
import 'claim_page.dart';
import 'common.dart';
import 'compose_page.dart';
import 'seed.dart';
import 'unlock.dart';
import 'invitations_page.dart';
import 'paged_list.dart';
import 'picture_picker.dart';
import 'glyphs.dart';

class WalletTab extends StatelessWidget {
  const WalletTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = AppScope.of(context).prefs;
    return AppBuilder(builder: (context, client, wallets) {
      if (!wallets.loaded) return const Center(child: CircularProgressIndicator());
      final wallet = wallets.wallet;
      if (wallet == null) return _NoWallet(wallets: wallets);

      final address = wallet.addressHex;
      // Every block touching this wallet is found by its filter and fetched.
      client.watchAddress(address);
      final theme = Theme.of(context);
      final pending = client.pendingDebitOf(address);
      final mined = client.blocksMinedBy(address);
      return ListenableBuilder(
        listenable: prefs,
        builder: (context, _) {
          final filters = prefs.walletFilters;
          bool shown(TxView v) => walletFiltersOf(v, address, client).any(filters.contains);
          return PagedList<TxView>(
            resetKey: (address, filters.fold(0, (mask, f) => mask | (1 << f.index))),
            fetch: (n) => client.activityOf(address).where(shown).take(n).toList(),
            itemBuilder: (context, v) => TxTile(v, perspective: address),
            dividerIndent: null,
            empty: Padding(padding: const EdgeInsets.all(16), child: Text(l.noHistory)),
            loadingMore: client.historyPending(address) || client.historyHasEarlier(address),
            onNeedMore: () => client.readEarlierHistory(address),
            header: [
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      InkWell(
                        onTap: () => openAddress(context, address),
                        child: Row(children: [
                          AddressAvatar(address, size: 40),
                          const SizedBox(width: 12),
                          Expanded(child: Text(nameOf(context, address), style: theme.textTheme.titleMedium)),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      Text(l.balance, style: theme.textTheme.labelLarge),
                      BalanceText(client: client, address: address, style: theme.textTheme.displaySmall),
                      if (pending > 0) Text(l.pendingCommitted(formatAmount(context, pending))),
                      if (mined > 0) Text(l.blocksMined(mined)),
                      const SizedBox(height: 12),
                      Text(l.address, style: theme.textTheme.labelLarge),
                      HashText(address, qr: addressLink(address), qrCaption: l.addressQrHint),
                      const SizedBox(height: 12),
                      _PublicName(client: client, address: address),
                      const SizedBox(height: 4),
                      _Protection(wallets.protection),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        OutlinedButton.icon(
                          icon: const MurmurIcon(Glyph.key),
                          label: Text(l.showSeed),
                          onPressed: () => _showSeed(context),
                        ),
                        OutlinedButton.icon(
                          icon: const MurmurIcon(Glyph.send),
                          label: Text(l.invitations),
                          onPressed: () =>
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InvitationsPage())),
                        ),
                        OutlinedButton.icon(
                          icon: const MurmurIcon(Glyph.logout),
                          label: Text(l.removeWallet),
                          onPressed: () => _confirmForget(context, wallets),
                        ),
                      ]),
                    ]),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 8, 0),
                  child: Row(children: [
                    Expanded(child: Text(l.history, style: theme.textTheme.titleMedium)),
                    _WalletFilterMenu(selected: filters, onChanged: prefs.setWalletFilters),
                  ]),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  /// The seed, after "are you sure" and unlocking it (the device's check or
  /// the passphrase).
  Future<void> _showSeed(BuildContext context) async {
    final l = context.l10n;
    final sure = await confirmAction(context, title: l.seedConfirmTitle, body: l.seedConfirmBody, action: l.showAction);
    if (!sure || !context.mounted) return;
    final unlocked = await unlockWallet(context, reason: l.authReasonSeed);
    if (unlocked == null || !context.mounted) return;
    return showSeed(context, unlocked);
  }

  /// Removing the wallet from this device: "are you sure", then unlocking
  /// it. If it can't be unlocked (a forgotten passphrase, a lost passkey),
  /// it can still be removed, after a plain warning: that's how a wallet is
  /// restored from its seed backup.
  Future<void> _confirmForget(BuildContext context, WalletController wallets) async {
    final l = context.l10n;
    final sure = await confirmAction(context,
        title: l.removeWalletTitle, body: l.removeWalletBody, action: l.remove, destructive: true);
    if (!sure || !context.mounted) return;
    if (await unlockWallet(context, reason: l.authReasonRemove) == null) {
      if (!context.mounted) return;
      final anyway = await confirmAction(context,
          title: l.removeAnywayTitle, body: l.removeAnywayBody, action: l.remove, destructive: true);
      if (!anyway) return;
    }
    await wallets.forget();
  }
}

/// The wallet's published alias (PROTOCOL.md Section 7.8), always with the
/// start of its address, and a way to set or clear it.
class _PublicName extends StatelessWidget {
  const _PublicName({required this.client, required this.address});

  final MurmurClient client;
  final String address;

  /// Asks for the name, checked as every client checks it, and a picture
  /// (Section 7.8: a profile), then sends them through the usual compose
  /// page (fee, summary, unlock). The picture published now is kept unless
  /// the user removes it: a name sent alone would drop it.
  Future<void> _edit(BuildContext context, String? current) async {
    final l = context.l10n;
    final formKey = GlobalKey<FormState>();
    var picture = client.publishedPicture(address);
    String? problem;
    var reading = false;
    final chosen = await showAppDialog<(String, ProfilePicture?)>(
      context: context,
      builder: (context) => WithTextController(
          text: current ?? '', builder: (context, controller) => StatefulBuilder(builder: (context, setState) {
        // Reads a picked image into a picture, or says why it can't.
        Future<void> choose(PictureSource source) async {
          final picked = await pickPicture(source);
          if (picked == null || !context.mounted) return;
          setState(() => (reading, problem) = (true, null));
          final made = picked.bytes == null ? null : await pictureFromImage(picked.bytes!);
          if (!context.mounted) return;
          setState(() {
            reading = false;
            if (made != null) picture = made;
            problem = switch (picked.problem) {
              PictureProblem.tooLarge => l.pictureTooLarge(formatCount(context, maxPictureFileBytes ~/ 1000000)),
              _ when made == null => l.pictureUnreadable,
              _ => null,
            };
          });
        }

        return AlertDialog(
          scrollable: true,
          title: Text(l.publicName),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Emphasized(l.publicNameIntro),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l.publicNameField,
                    helperText: l.bytesOf(utf8.encode(controller.text).length, maxAliasBytes),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => switch (aliasProblem(v ?? '')) {
                    AliasProblem.tooLong => l.aliasTooLong(maxAliasBytes),
                    AliasProblem.forbiddenCharacter => l.aliasBadCharacter,
                    AliasProblem.edgeSpace => l.aliasEdgeSpace,
                    null => null,
                  },
                ),
                // How it will read, as the user types.
                if (controller.text.isNotEmpty && aliasProblem(controller.text) == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(children: [
                      PicturePreview(address, picture, size: 28),
                      const SizedBox(width: 10),
                      Expanded(child: Emphasized(l.publicNameShownAs(publicNameOf(controller.text, address)))),
                    ]),
                  ),
                const SizedBox(height: 16),
                Text(l.publicNamePicture, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(children: [
                  PicturePreview(address, picture, size: 72),
                  const SizedBox(width: 16),
                  Expanded(
                    child: reading
                        ? const Align(alignment: AlignmentDirectional.centerStart, child: CircularProgressIndicator())
                        : Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final (source, label) in hasPhotoLibrary
                                ? [(PictureSource.photos, l.pictureFromPhotos), (PictureSource.files, l.pictureFromFiles)]
                                : [(PictureSource.files, l.pictureChoose)])
                              OutlinedButton(onPressed: () => choose(source), child: Text(label)),
                            if (picture != null)
                              TextButton(
                                  onPressed: () => setState(() => (picture, problem) = (null, null)),
                                  child: Text(l.pictureRemove)),
                          ]),
                  ),
                ]),
                if (problem != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(problem!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                const SizedBox(height: 12),
                InfoPoint(Glyph.warning, l.publicNameNotUnique, style: Theme.of(context).textTheme.bodySmall),
                InfoPoint(Glyph.burn, l.publicNameCost, style: Theme.of(context).textTheme.bodySmall),
                if (picture != null) ...[
                  InfoPoint(Glyph.edit, l.picturePoint, style: Theme.of(context).textTheme.bodySmall),
                  InfoPoint(Glyph.fee, l.pictureCost, style: Theme.of(context).textTheme.bodySmall),
                ],
                InfoPoint(Glyph.blocks, l.publicNameRemovable, style: Theme.of(context).textTheme.bodySmall),
                InfoPoint(Glyph.edit, l.publicNameClear, style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(context, (controller.text, picture));
              },
              child: Text(l.publicNameSet),
            ),
          ],
        );
      })),
    );
    if (chosen == null || !context.mounted) return;
    final (name, chosenPicture) = chosen;
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ComposePage(alias: name, picture: chosenPicture)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final alias = client.publishedAlias(address);
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.publicName, style: theme.textTheme.labelLarge),
          Text(
            alias == null ? l.publicNameNone : publicNameOf(alias, address),
            style: alias == null ? theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline) : null,
          ),
        ]),
      ),
      TextButton.icon(
        icon: const MurmurIcon(Glyph.edit, size: 18),
        label: Text(l.publicNameSet),
        onPressed: client.state == LinkState.live ? () => _edit(context, alias) : null,
      ),
    ]);
  }
}

/// How the wallet's key is kept on this device (see `services/key_vault.dart`).
class _Protection extends StatelessWidget {
  const _Protection(this.protection);

  final String? protection;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final text = switch (protection) {
      'device' => l.protectionDevice,
      'passkey' => l.protectionPasskey,
      'passphrase' => l.protectionPassphrase,
      'legacy' => l.protectionLegacy,
      _ => null,
    };
    if (text == null) return const SizedBox.shrink();
    final color = protection == 'legacy' ? StatusColors.of(context).pending : StatusColors.of(context).success;
    return Row(children: [
      MurmurIcon(protection == 'legacy' ? Glyph.warning : Glyph.key, size: 16, color: color),
      const SizedBox(width: 6),
      Flexible(
          child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
    ]);
  }
}

/// Which movements the history shows, as checkboxes in a menu that stays
/// open while they're ticked.
class _WalletFilterMenu extends StatelessWidget {
  const _WalletFilterMenu({required this.selected, required this.onChanged});

  final Set<WalletFilter> selected;
  final ValueChanged<Set<WalletFilter>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String label(WalletFilter f) => switch (f) {
          WalletFilter.transfersSent => l.walletFilterTransfersSent,
          WalletFilter.transfersReceived => l.walletFilterTransfersReceived,
          WalletFilter.repliesPaid => l.walletFilterRepliesPaid,
          WalletFilter.repliesEarned => l.walletFilterRepliesEarned,
          WalletFilter.threadCosts => l.walletFilterThreadCosts,
          WalletFilter.flagCosts => l.walletFilterFlagCosts,
        };
    return MenuAnchor(
      menuChildren: [
        for (final f in WalletFilter.values)
          CheckboxMenuButton(
            value: selected.contains(f),
            closeOnActivate: false,
            onChanged: (on) => onChanged(on == true ? {...selected, f} : selected.difference({f})),
            child: Text(label(f)),
          ),
      ],
      builder: (context, controller, _) => TextButton.icon(
        icon: const MurmurIcon(Glyph.filter, size: 18),
        label: Text(l.filters),
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _NoWallet extends StatelessWidget {
  const _NoWallet({required this.wallets});

  final WalletController wallets;

  Future<void> _import(BuildContext context) async {
    final l = context.l10n;
    final seed = await askSeed(context);
    if (seed == null || !context.mounted) return;
    // Saved encrypted: this sets up its protection (the device's check or a
    // passphrase).
    await protectWallet(context, (p) => wallets.import(toHex(seed), p, reason: l.authReasonNewWallet));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            MurmurIcon(Glyph.wallet, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(l.walletIntro, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const MurmurIcon(Glyph.add),
              label: Text(l.createWallet),
              onPressed: () => createWallet(context),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const MurmurIcon(Glyph.import),
              label: Text(l.importSeed),
              onPressed: () => _import(context),
            ),
            const SizedBox(height: 12),
            // A newcomer with a card: claiming creates the wallet.
            TextButton(onPressed: () => enterInvitation(context), child: Text(l.haveInvitation)),
          ]),
        ),
      ),
    );
  }
}
