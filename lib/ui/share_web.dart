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

Future<void> shareToApps(String text, {String? subject}) async {
  try {
    await web.window.navigator.share(web.ShareData(text: text, title: subject ?? '')).toDart;
  } catch (_) {
    // Dismissed, or not allowed: nothing to do.
  }
}
