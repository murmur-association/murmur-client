// Mentions (PROTOCOL.md Section 2.4): a thread or a reply names up to four
// people, who learn of it through the node's index. What the chain carries
// is the first 8 bytes of each address; the `@name` in the text is for the
// reader, a convention between clients.

import 'package:flutter/material.dart';

import '../protocol/bytes.dart';
import '../protocol/models.dart';
import '../services/node_client.dart';
import '../services/storage.dart';
import 'common.dart';
import 'glyphs.dart';

/// What a mention writes in the text: the name the reader knows the person
/// by (a name given here, or their public name), else the start of their
/// address. Without spaces, so it reads as one word after its `@`.
String mentionName(BuildContext context, String address) =>
    nameOf(context, address).split(' · ').first.replaceAll(RegExp(r'\s+'), '_');

/// The people a message can mention, best first: those in its thread (when
/// it's a reply), then the starred, then those given a name here. Never
/// `me`.
List<String> mentionCandidates(MurmurClient client, Preferences prefs, {TxView? replyTo, String? me}) {
  final out = <String>{};
  final root = replyTo == null ? null : client.threadRootOf(replyTo);
  if (root != null) {
    out.add(root.tx.fromAddress);
    for (final r in client.repliesOf(root)) {
      out.add(r.tx.fromAddress);
    }
  }
  out
    ..addAll(prefs.starredPeople)
    ..addAll(prefs.aliases.keys)
    ..remove(me);
  return out.where((a) => !prefs.muted.contains(a)).toList();
}

/// Under the message field: who the message mentions, each removable, and,
/// while the word at the cursor starts with `@`, the people it could be.
/// Picking one writes `@name` in place of that word and adds them.
class MentionPicker extends StatefulWidget {
  const MentionPicker(
      {super.key, required this.message, required this.candidates, required this.chosen, required this.onChanged});

  final TextEditingController message;

  /// Addresses that can be mentioned, best first.
  final List<String> candidates;

  /// Addresses mentioned so far.
  final List<String> chosen;
  final ValueChanged<List<String>> onChanged;

  @override
  State<MentionPicker> createState() => _MentionPickerState();
}

class _MentionPickerState extends State<MentionPicker> {
  /// The `@word` before the cursor: where it starts, and what follows the
  /// `@`; null when the cursor isn't in one.
  (int, String)? _typing() {
    final value = widget.message.value;
    final at = value.selection.baseOffset;
    if (at < 0 || at > value.text.length) return null;
    final match = RegExp(r'(?:^|\s)@([^\s@]*)$').firstMatch(value.text.substring(0, at));
    if (match == null) return null;
    return (at - match.group(1)!.length - 1, match.group(1)!.toLowerCase());
  }

  void _changed() => setState(() {});

  @override
  void initState() {
    super.initState();
    widget.message.addListener(_changed);
  }

  @override
  void dispose() {
    widget.message.removeListener(_changed);
    super.dispose();
  }

  void _pick(String address, int from) {
    final value = widget.message.value;
    final at = value.selection.baseOffset;
    final word = '@${mentionName(context, address)} ';
    final text = value.text.replaceRange(from, at, word);
    widget.message.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: from + word.length),
    );
    widget.onChanged([...widget.chosen, address]);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final chosen = widget.chosen;
    final typing = _typing();
    final full = chosen.length >= maxMentions;
    final matches = typing == null || full
        ? const <String>[]
        : [
            for (final a in widget.candidates)
              if (!chosen.contains(a) &&
                  (mentionName(context, a).toLowerCase().contains(typing.$2) || a.startsWith(typing.$2)))
                a,
          ].take(5).toList();
    if (chosen.isEmpty && matches.isEmpty && !(typing != null && full)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (matches.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final a in matches)
              ActionChip(
                avatar: AddressAvatar(a, size: 20),
                label: Text('@${mentionName(context, a)}'),
                onPressed: () => _pick(a, typing!.$1),
              ),
          ]),
        if (typing != null && full) Text(l.mentionsMax(maxMentions), style: theme.textTheme.bodySmall),
        if (chosen.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(l.mentionsLabel, style: theme.textTheme.labelMedium),
            for (final a in chosen)
              InputChip(
                avatar: AddressAvatar(a, size: 20),
                label: Text(nameOf(context, a)),
                onDeleted: () => widget.onChanged([...chosen]..remove(a)),
              ),
          ]),
          InfoPoint(Glyph.show, l.mentionPublicPoint),
        ],
      ]),
    );
  }
}

/// Under a message's text: whom it mentions, each picture opening their
/// page. A mention nobody here has seen write shows the 8 bytes it holds.
class MentionsLine extends StatelessWidget {
  const MentionsLine(this.tx, {super.key});

  final Transaction tx;

  @override
  Widget build(BuildContext context) {
    if (tx.mentions.isEmpty) return const SizedBox.shrink();
    final scope = AppScope.of(context);
    final known = [
      if (scope.wallets.wallet != null) scope.wallets.wallet!.addressHex,
      ...scope.prefs.starredPeople,
      ...scope.prefs.aliases.keys,
    ];
    final theme = Theme.of(context);
    final copper = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(spacing: 10, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        for (final m in tx.mentions)
          if (scope.client.addressOfMention(m, also: known) case final address?)
            Row(mainAxisSize: MainAxisSize.min, children: [
              AvatarLink(address, size: 18),
              const SizedBox(width: 4),
              Text('@${nameOf(context, address)}', style: copper),
            ])
          else
            Text('@${toHex(m)}', style: mono.copyWith(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}
