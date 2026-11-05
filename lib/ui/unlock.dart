// The interface around the key vault (services/key_vault.dart): asking
// "are you sure", the passphrase dialogs, and unlocking the wallet for one
// use. Every signature, "Show seed" and "Remove wallet" unlocks anew.

import 'package:flutter/material.dart';

import '../crypto/wallet.dart';
import '../services/key_vault.dart';
import '../services/storage.dart' show InviteStore, KeyringUnavailable;
import 'common.dart';
import 'glyphs.dart';
import 'brand.dart';
import 'invitations_page.dart' show inviteStore;

/// "Are you sure": `title`, `body`, and the `action` button (red when
/// `destructive`).
Future<bool> confirmAction(BuildContext context,
    {required String title, required String body, required String action, bool destructive = false}) async {
  final l = context.l10n;
  final ok = await showAppDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      // Centred: the dialog lays its icon out at full width.
      icon: const Center(child: MurmurIcon(Glyph.key, size: 32)),
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error) : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Passphrase dialogs, for devices where the vault uses one.
class DialogPrompts implements VaultPrompts {
  DialogPrompts(this.context);

  final BuildContext context;

  @override
  Future<String?> newPassphrase() {
    final l = context.l10n;
    final first = TextEditingController(), second = TextEditingController();
    final form = GlobalKey<FormState>();
    final small = Theme.of(context).textTheme.bodyMedium;
    return showAppDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        scrollable: true,
        icon: const Center(child: MurmurIcon(Glyph.key, size: 32)),
        title: Text(l.passphraseNewTitle),
        content: Form(
          key: form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // One passphrase for the app: the wallet's and the cards'.
            InfoPoint(Glyph.key, l.passphraseNewWhat, style: small),
            InfoPoint(Glyph.pending, l.passphraseNewWhen, style: small),
            InfoPoint(Glyph.warning, l.passphraseNewForget, color: StatusColors.of(context).pending, style: small),
            const SizedBox(height: 16),
            TextFormField(
              controller: first,
              obscureText: true,
              decoration: InputDecoration(labelText: l.passphraseField, border: const OutlineInputBorder()),
              validator: (v) =>
                  (v ?? '').length < minPassphraseLength ? l.passphraseTooShort(minPassphraseLength) : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: second,
              obscureText: true,
              decoration: InputDecoration(labelText: l.passphraseRepeat, border: const OutlineInputBorder()),
              validator: (v) => v != first.text ? l.passphraseMismatch : null,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(context, first.text);
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  @override
  Future<String?> passphrase(String reason) {
    final l = context.l10n;
    final field = TextEditingController();
    return showAppDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        icon: const Center(child: MurmurIcon(Glyph.key, size: 32)),
        title: Text(l.passphraseTitle),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(reason),
          const SizedBox(height: 16),
          TextField(
            controller: field,
            obscureText: true,
            decoration: InputDecoration(labelText: l.passphraseField, border: const OutlineInputBorder()),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, field.text), child: Text(l.unlock)),
        ],
      ),
    );
  }

  @override
  Future<bool?> passkeyUnsupported() {
    final l = context.l10n;
    final small = Theme.of(context).textTheme.bodyMedium;
    return showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        scrollable: true,
        icon: Center(child: MurmurIcon(Glyph.warning, size: 32, color: Theme.of(context).colorScheme.primary)),
        title: Text(l.passkeyNoPrfTitle),
        content: SizedBox(
          width: 440,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            InfoPoint(Glyph.key, l.passkeyNoPrfWhy, style: small),
            InfoPoint(Glyph.refresh, l.passkeyNoPrfTry, style: small),
            InfoPoint(Glyph.logout, l.passkeyNoPrfLeftover, style: small),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.passkeyUsePassphrase)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.passkeyTryAnother)),
        ],
      ),
    );
  }
}

/// Asks the passphrase once for one action that needs it twice: funding
/// the first invitation cards signs with the wallet's key and puts the
/// cards' key under the same passphrase. The answer is handed to the second
/// question and lives no longer than the action (this object); nothing
/// stays unlocked.
class OneAnswer implements VaultPrompts {
  OneAnswer(this._prompts);

  final VaultPrompts _prompts;
  String? _answer;

  @override
  Future<String?> newPassphrase() async => _answer = await _prompts.newPassphrase();

  @override
  Future<String?> passphrase(String reason) async => _answer ??= await _prompts.passphrase(reason);

  @override
  Future<bool?> passkeyUnsupported() => _prompts.passkeyUnsupported();
}

/// The wallet with its key, for one use, after the device's check or the
/// passphrase; null (and a note) if that doesn't happen. `prompts` replaces
/// the dialogs' own, for an action that shares one answer ([OneAnswer]).
Future<MurmurWallet?> unlockWallet(BuildContext context, {required String reason, VaultPrompts? prompts}) async {
  final l = context.l10n;
  try {
    return await AppScope.of(context).wallets.unlock(prompts ?? DialogPrompts(context), reason: reason);
  } on VaultLocked catch (e) {
    if (context.mounted) showSnack(context, e.wrongPassphrase ? l.wrongPassphrase : l.authFailed);
    return null;
  }
}

/// Runs `save` (creating or importing a wallet, which sets up its
/// protection); false (and a note) if the user cancels.
Future<bool> protectWallet(BuildContext context, Future<void> Function(VaultPrompts prompts) save) async {
  try {
    await save(DialogPrompts(context));
    return true;
  } on VaultLocked catch (e) {
    // A new wallet shares the passphrase or passkey the invitation cards
    // are under. A user who no longer has it may let the cards' key go,
    // or no wallet could ever be made or imported on this device again.
    if (context.mounted && await InviteStore.keyShared() && context.mounted) {
      final l = context.l10n;
      final letGo = await confirmAction(context,
          title: l.forgetCardsKeyTitle, body: l.forgetCardsKeyBody, action: l.forgetCardsKeyAction, destructive: true);
      if (letGo && context.mounted) {
        try {
          await inviteStore.forgetKey();
        } on KeyringUnavailable {
          if (context.mounted) showSnack(context, l.keyringUnavailable);
          return false;
        }
        return context.mounted && await protectWallet(context, save);
      }
      return false;
    }
    if (context.mounted) showSnack(context, e.wrongPassphrase ? context.l10n.wrongPassphrase : context.l10n.authFailed);
    return false;
  } on KeyringUnavailable {
    // Linux, with a keyring that is locked and can't ask (services/keyring.dart).
    if (context.mounted) showSnack(context, context.l10n.keyringUnavailable);
    return false;
  }
}
