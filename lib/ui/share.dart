// Sharing a link, address or hash: to other apps through the system's own
// share sheet where there is one (Android, iOS, macOS, and browsers with
// the Web Share API), always by copying, and for what a phone can open, as
// a QR code to scan. Nothing goes anywhere unless the user picks where.

import 'package:flutter/material.dart';

import 'common.dart';
import 'glyphs.dart';
import 'qr.dart';
import 'share_io.dart' if (dart.library.js_interop) 'share_web.dart' as impl;

/// Whether this platform has a system share sheet.
bool get canShareToApps => impl.canShareToApps;

/// Copies `text` and says so. Call it from the tap itself, never after
/// something awaited or a menu's closing: browsers (Safari on iPhones
/// above all) let a page write to the clipboard only while the user's tap
/// is being handled.
void copyText(BuildContext context, String text) {
  impl.copyText(text);
  showSnack(context, context.l10n.copied);
}

enum _Way { copy, apps, qr }

/// A share button: a menu with "Copy", "Share…" where the system can share
/// to other apps, and "QR code" when there's a link to scan (`qr`). With
/// only copying to offer, it simply copies.
class ShareButton extends StatelessWidget {
  const ShareButton(this.text, {super.key, this.subject, this.size = 20, this.qr, this.qrCaption});

  final String text;

  /// A title for apps that take one (mail, notes).
  final String? subject;
  final double size;

  /// A link to show as a QR code, for another device to scan and open (an
  /// address's page, say); null for things that aren't opened by a link.
  final String? qr;

  /// What the QR code is of, said under it.
  final String? qrCaption;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final icon = MurmurIcon(Glyph.share, size: size);
    if (!canShareToApps && qr == null) {
      return IconButton(
        icon: icon,
        tooltip: l.copy,
        visualDensity: VisualDensity.compact,
        onPressed: () => copyText(context, text),
      );
    }
    // Copying and sharing happen in the item's own tap (`onTap`), not once
    // the menu has closed (`onSelected` comes after its animation): by then
    // the browser no longer takes the tap for the user's, and an iPhone
    // refuses both the clipboard and the share sheet.
    PopupMenuItem<_Way> item(_Way way, Glyph glyph, String label, {VoidCallback? onTap}) => PopupMenuItem(
          value: way,
          onTap: onTap,
          child: Row(children: [MurmurIcon(glyph, size: 18), const SizedBox(width: 12), Text(label)]),
        );
    return PopupMenuButton<_Way>(
      icon: icon,
      tooltip: l.share,
      onSelected: (way) {
        if (way == _Way.qr) showQr(context, qr!, caption: qrCaption, subject: subject);
      },
      itemBuilder: (_) => [
        item(_Way.copy, Glyph.copy, l.copy, onTap: () => copyText(context, text)),
        if (canShareToApps)
          item(_Way.apps, Glyph.share, l.share, onTap: () => impl.shareToApps(text, subject: subject)),
        if (qr != null) item(_Way.qr, Glyph.qr, l.qrCode),
      ],
    );
  }
}

/// `link` as a QR code, large, over the page: to be scanned from the screen,
/// or passed on again with the share button under it. `code` is what to
/// type where scanning isn't possible (an invitation's code).
Future<void> showQr(BuildContext context, String link, {String? caption, String? code, String? subject}) =>
    showAppDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            QrView(link, size: 280),
            if (caption != null) ...[
              const SizedBox(height: 12),
              SizedBox(width: 280, child: Text(caption, textAlign: TextAlign.center)),
            ],
            if (code != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 280,
                child: SelectableText(code, style: mono.copyWith(fontSize: 13), textAlign: TextAlign.center),
              ),
            ],
            const SizedBox(height: 4),
            ShareButton(link, subject: subject, size: 24),
          ]),
        ),
      ),
    );
