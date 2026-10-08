// Murmur emoji in the interface: message text with its ":name:" codes drawn
// as glyphs, and the picker that writes them. The convention itself is in
// protocol/emoji.dart.

import 'package:flutter/material.dart';

import '../protocol/emoji.dart';
import 'glyphs.dart';
import 'l10n.dart';

/// The emoji this client draws: each name (lower-case letters only), and its
/// glyph. None yet: no name is taken, so every message reads as written and
/// the picker doesn't show.
///
/// A name is what's on the chain: once messages hold one, it's never renamed
/// or given another meaning.
const murmurEmoji = <String, Glyph>{};

/// A message's text, with its Murmur emoji drawn in copper at the text's
/// size. Text without any is shown exactly as a [Text] or [SelectableText]
/// would.
class MessageText extends StatelessWidget {
  const MessageText(this.text,
      {super.key, this.style, this.maxLines, this.selectable = false, this.emoji = murmurEmoji});

  final String text;
  final TextStyle? style;
  final int? maxLines;

  /// Whether the text can be selected and copied. Copying gives the emoji
  /// back as their codes, so a copied message is the one that was sent.
  final bool selectable;

  /// The emoji drawn: the app's, unless a test brings its own.
  final Map<String, Glyph> emoji;

  @override
  Widget build(BuildContext context) {
    final pieces = emojiPieces(text, emoji.keys.toSet());
    final overflow = maxLines == null ? null : TextOverflow.ellipsis;
    if (pieces.every((p) => p.emoji == null)) {
      return selectable
          ? SelectableText(text, style: style, maxLines: maxLines)
          : Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }
    final fontSize = DefaultTextStyle.of(context).style.merge(style).fontSize ?? 14;
    // A little over the letters' height, as emoji are.
    final size = MediaQuery.textScalerOf(context).scale(fontSize) * 1.2;
    final copper = Theme.of(context).colorScheme.primary;
    final rich = Text.rich(
      TextSpan(children: [
        for (final piece in pieces)
          if (piece.emoji == null)
            TextSpan(text: piece.text)
          else
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _Drawn(emoji[piece.emoji]!, piece.text, size: size, color: copper, selectable: selectable),
            ),
      ]),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
    // SelectableText takes text spans only.
    return selectable ? SelectionArea(child: rich) : rich;
  }
}

/// One emoji in a line of text.
class _Drawn extends StatelessWidget {
  const _Drawn(this.glyph, this.code, {required this.size, required this.color, required this.selectable});

  final Glyph glyph;
  final String code;
  final double size;
  final Color color;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final icon = MurmurIcon(glyph, size: size, color: color, semanticLabel: code);
    if (!selectable) return icon;
    // Its code lies under the glyph, unseen, so that a selection takes it.
    return SizedBox.square(
      dimension: size,
      child: Stack(fit: StackFit.expand, children: [
        ExcludeSemantics(
          child: FittedBox(
            child: Text(code, textScaler: TextScaler.noScaling, style: const TextStyle(color: Color(0x00000000))),
          ),
        ),
        icon,
      ]),
    );
  }
}

/// A button under the message field that opens the emoji, each writing its
/// code where the cursor is. Nothing at all while there are no emoji.
class EmojiPicker extends StatefulWidget {
  const EmojiPicker(this.controller, {super.key, this.emoji = murmurEmoji});

  final TextEditingController controller;

  /// The emoji offered: the app's, unless a test brings its own.
  final Map<String, Glyph> emoji;

  @override
  State<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker> {
  var _open = false;

  void _write(String code) {
    final value = widget.controller.value;
    final selection = value.selection;
    // Before the field was ever focused it has no cursor: write at the end.
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    widget.controller.value = TextEditingValue(
      text: value.text.replaceRange(start, end, code),
      selection: TextSelection.collapsed(offset: start + code.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emoji = widget.emoji;
    if (emoji.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    final theme = Theme.of(context);
    final copper = theme.colorScheme.primary;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextButton.icon(
        icon: MurmurIcon(emoji.values.first, size: 18, filled: _open),
        label: Text(l.murmurEmoji),
        onPressed: () => setState(() => _open = !_open),
      ),
      if (_open) ...[
        Wrap(children: [
          for (final MapEntry(key: name, value: glyph) in emoji.entries)
            IconButton(
              tooltip: emojiCode(name),
              icon: MurmurIcon(glyph, color: copper),
              onPressed: () => _write(emojiCode(name)),
            ),
        ]),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 12, top: 4),
          child: Text(l.murmurEmojiHint(emojiCode(emoji.keys.first)), style: theme.textTheme.bodySmall),
        ),
      ],
    ]);
  }
}
