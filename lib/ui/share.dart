// Sharing a link, address or hash: to other apps through the system's own
// share sheet where there is one (Android, iOS, macOS, and browsers with
// the Web Share API), and always by copying. Nothing goes anywhere unless
// the user picks where.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'common.dart';
import 'glyphs.dart';
import 'share_io.dart' if (dart.library.js_interop) 'share_web.dart' as impl;

/// Whether this platform has a system share sheet.
bool get canShareToApps => impl.canShareToApps;

void _copy(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  showSnack(context, context.l10n.copied);
}

/// A share button: a menu with "Copy" and "Share…" where the system can
/// share to other apps; elsewhere it simply copies.
class ShareButton extends StatelessWidget {
  const ShareButton(this.text, {super.key, this.subject, this.size = 20});

  final String text;

  /// A title for apps that take one (mail, notes).
  final String? subject;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final icon = MurmurIcon(Glyph.share, size: size);
    if (!canShareToApps) {
      return IconButton(
        icon: icon,
        tooltip: l.copy,
        visualDensity: VisualDensity.compact,
        onPressed: () => _copy(context, text),
      );
    }
    return PopupMenuButton<bool>(
      icon: icon,
      tooltip: l.share,
      onSelected: (toApps) => toApps ? impl.shareToApps(text, subject: subject) : _copy(context, text),
      itemBuilder: (context) => [
        PopupMenuItem(value: false, child: Row(children: [const MurmurIcon(Glyph.copy, size: 18), const SizedBox(width: 12), Text(l.copy)])),
        PopupMenuItem(value: true, child: Row(children: [const MurmurIcon(Glyph.share, size: 18), const SizedBox(width: 12), Text(l.share)])),
      ],
    );
  }
}
