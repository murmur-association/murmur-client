import 'dart:io';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Where the system has a real share sheet. (On Windows and Linux the
/// plugin would fall back to a mail link, so there it's copy only.)
bool get canShareToApps => Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

/// Puts `text` on the clipboard.
void copyText(String text) => Clipboard.setData(ClipboardData(text: text));

Future<void> shareToApps(String text, {String? subject}) =>
    SharePlus.instance.share(ShareParams(text: text, subject: subject));
