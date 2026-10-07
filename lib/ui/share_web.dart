import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Whether the browser has the Web Share API (most phones, Safari, Edge
/// and Chrome on some desktops; not Firefox on desktop).
bool get canShareToApps {
  try {
    return web.window.navigator.canShare(web.ShareData(text: 'murmur'));
  } catch (_) {
    return false;
  }
}

/// Puts `text` on the clipboard, at once: the browser allows it only while
/// the tap that asked is being handled. First the old way, which every
/// browser takes there (a selection in a field off screen, and the copy
/// command): Safari on iPhones refuses the newer clipboard call in more
/// cases. Then that call, where the old way isn't there.
void copyText(String text) {
  if (_copySelection(text)) return;
  try {
    web.window.navigator.clipboard.writeText(text);
  } catch (_) {
    // No clipboard for this page: nothing more to try.
  }
}

bool _copySelection(String text) {
  final focused = web.document.activeElement;
  // Read-only, so a phone doesn't raise its keyboard; 16 px, so Safari
  // doesn't zoom in on it.
  final field = web.HTMLTextAreaElement()
    ..value = text
    ..readOnly = true;
  field.style
    ..position = 'fixed'
    ..top = '0'
    ..left = '0'
    ..opacity = '0'
    ..fontSize = '16px';
  web.document.body!.append(field);
  var copied = false;
  try {
    field.select();
    field.setSelectionRange(0, text.length);
    copied = web.document.execCommand('copy');
  } catch (_) {
    copied = false;
  }
  field.remove();
  // Back to where the keyboard's focus was.
  (focused as web.HTMLElement?)?.focus();
  return copied;
}

Future<void> shareToApps(String text, {String? subject}) async {
  try {
    await web.window.navigator.share(web.ShareData(text: text, title: subject ?? '')).toDart;
  } catch (_) {
    // Dismissed, or not allowed: nothing to do.
  }
}
