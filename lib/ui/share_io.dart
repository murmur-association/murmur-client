import 'dart:io';

import 'package:share_plus/share_plus.dart';

/// Where the system has a real share sheet. (On Windows and Linux the
/// plugin would fall back to a mail link, so there it's copy only.)
bool get canShareToApps => Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

Future<void> shareToApps(String text, {String? subject}) =>
    SharePlus.instance.share(ShareParams(text: text, subject: subject));
