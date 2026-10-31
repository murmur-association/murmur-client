// The wallet's seed on screen: as 24 words and as 64 characters, with copy
// buttons only (the seed is never offered to other apps, AGENTS.md rule 4).
// Shown on request (Wallet tab, "Show seed"), and once to every new wallet,
// which must not be left without a backup of it.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../crypto/seed_phrase.dart';
import '../crypto/wallet.dart';
import 'common.dart';
import 'glyphs.dart';
import 'share.dart';
import 'unlock.dart';

/// The seed in both forms. Left-to-right in every language: the words are
/// English and the characters hex.
class SeedView extends StatelessWidget {
  const SeedView(this.wallet, {super.key});

  final MurmurWallet wallet;

  void _copy(BuildContext context, String text) => copyText(context, text);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final words = seedPhrase(wallet.seed).split(' ');
    final box = BoxDecoration(
      color: theme.colorScheme.surface,
      border: Border.all(color: theme.colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(8),
    );
    Widget heading(String text, String copyLabel, String value) => Row(children: [
          Expanded(child: Text(text, style: theme.textTheme.labelLarge)),
          TextButton.icon(
            icon: const MurmurIcon(Glyph.copy, size: 16),
            label: Text(copyLabel),
            onPressed: () => _copy(context, value),
          ),
        ]);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      heading(l.seedAsWords, l.copyWords, words.join(' ')),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: box,
        child: Directionality(
          textDirection: TextDirection.ltr,
          // Numbered, so they're written down and typed back in order.
          child: Wrap(spacing: 14, runSpacing: 8, children: [
            for (var i = 0; i < words.length; i++)
              Text.rich(TextSpan(children: [
                TextSpan(text: '${i + 1} ', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                TextSpan(text: words[i], style: mono.copyWith(fontWeight: FontWeight.w600)),
              ])),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      heading(l.seedAsHex, l.copyCharacters, wallet.seedHex),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: box,
        child: SelectableText(wallet.seedHex, style: mono, textDirection: TextDirection.ltr),
      ),
      const SizedBox(height: 8),
      Text(l.seedEitherForm, style: theme.textTheme.bodySmall),
    ]);
  }
}

/// The seed of a wallet the user asked to see.
Future<void> showSeed(BuildContext context, MurmurWallet wallet) {
  final l = context.l10n;
  return showAppDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(l.seedTitle),
      content: SizedBox(
        width: 460,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.seedWarning),
          const SizedBox(height: 12),
          SeedView(wallet),
        ]),
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.done))],
    ),
  );
}

/// The seed of a wallet just created: why it matters, the seed, and a box
/// to tick before the dialog can be closed. It can't be dismissed otherwise:
/// a wallet whose seed nobody kept is lost with the device.
Future<void> showNewSeed(BuildContext context, MurmurWallet wallet) => showAppDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _NewSeedDialog(wallet),
    );

class _NewSeedDialog extends StatefulWidget {
  const _NewSeedDialog(this.wallet);

  final MurmurWallet wallet;

  @override
  State<_NewSeedDialog> createState() => _NewSeedDialogState();
}

class _NewSeedDialogState extends State<_NewSeedDialog> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        scrollable: true,
        icon: Center(child: MurmurIcon(Glyph.key, size: 32, color: theme.colorScheme.primary)),
        title: Text(l.seedNewTitle),
        content: SizedBox(
          width: 460,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            InfoPoint(Glyph.key, l.seedNewKeep),
            InfoPoint(Glyph.warning, l.seedNewOnlyWay, color: theme.colorScheme.primary),
            InfoPoint(Glyph.hide, l.seedNewSecret),
            const SizedBox(height: 12),
            SeedView(widget.wallet),
            const SizedBox(height: 4),
            CheckboxListTile(
              value: _saved,
              onChanged: (v) => setState(() => _saved = v ?? false),
              title: Text(l.seedNewSaved),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ]),
        ),
        actions: [
          FilledButton(onPressed: _saved ? () => Navigator.of(context).pop() : null, child: Text(l.done)),
        ],
      ),
    );
  }
}

/// Creates a wallet (which sets up its protection), then shows its seed.
/// False (and a note) if the user cancels before it's created.
Future<bool> createWallet(BuildContext context) async {
  final wallets = AppScope.of(context).wallets;
  final reason = context.l10n.authReasonNewWallet;
  MurmurWallet? created;
  final ok = await protectWallet(context, (p) async => created = await wallets.create(p, reason: reason));
  if (!ok || created == null) return false;
  if (context.mounted) await showNewSeed(context, created!);
  return true;
}

/// Asks for a seed to import, in either form (its 24 words, or its 64
/// characters), and says what's wrong with what was typed until it is one.
/// Null if the user cancels.
Future<Uint8List?> askSeed(BuildContext context) {
  final l = context.l10n;
  final controller = TextEditingController();
  String? error;
  return showAppDialog<Uint8List>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        scrollable: true,
        title: Text(l.importWallet),
        content: SizedBox(
          width: 460,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.importHelp),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: mono,
              textDirection: TextDirection.ltr,
              // Room for 24 words, but one entry, not a text of several
              // lines: Enter confirms.
              minLines: 1,
              maxLines: 4,
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => error == null ? null : setState(() => error = null),
              decoration: InputDecoration(border: const OutlineInputBorder(), labelText: l.seedOrWords, errorText: error, errorMaxLines: 3),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          FilledButton(
            onPressed: () {
              final input = parseSeed(controller.text);
              if (input.seed != null) return Navigator.pop(context, input.seed);
              setState(() => error = switch (input.problem!) {
                    SeedProblem.format => l.seedInvalid,
                    SeedProblem.unknownWord => l.seedUnknownWord(input.word!),
                    SeedProblem.checksum => l.seedBadChecksum,
                  });
            },
            child: Text(l.import),
          ),
        ],
      ),
    ),
  );
}
