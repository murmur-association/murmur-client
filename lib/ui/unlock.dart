// The interface around the key vault (services/key_vault.dart): asking
// "are you sure", the passphrase dialogs, and unlocking the wallet for one
// use. Every signature, "Show seed" and "Remove wallet" unlocks anew.

import 'package:flutter/material.dart';

import '../crypto/wallet.dart';
import '../services/key_vault.dart';
import 'common.dart';
import 'glyphs.dart';

/// "Are you sure": `title`, `body`, and the `action` button (red when
/// `destructive`).
Future<bool> confirmAction(BuildContext context,
    {required String title, required String body, required String action, bool destructive = false}) async {
  final l = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
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
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Center(child: MurmurIcon(Glyph.key, size: 32)),
        title: Text(l.passphraseNewTitle),
        content: Form(
          key: form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l.passphraseNewBody),
            const SizedBox(height: 16),
            TextFormField(
              controller: first,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(labelText: l.passphraseField, border: const OutlineInputBorder()),
              validator: (v) => (v ?? '').length < minPassphraseLength ? l.passphraseTooShort(minPassphraseLength) : null,
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
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Center(child: MurmurIcon(Glyph.key, size: 32)),
        title: Text(l.passphraseTitle),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(reason),
          const SizedBox(height: 16),
          TextField(
            controller: field,
            obscureText: true,
            autofocus: true,
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
}

/// The wallet with its key, for one use, after the device's check or the
/// passphrase; null (and a note) if that doesn't happen.
Future<MurmurWallet?> unlockWallet(BuildContext context, {required String reason}) async {
  final l = context.l10n;
  try {
    return await AppScope.of(context).wallets.unlock(DialogPrompts(context), reason: reason);
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
  } on VaultLocked {
    if (context.mounted) showSnack(context, context.l10n.authFailed);
    return false;
  }
}
