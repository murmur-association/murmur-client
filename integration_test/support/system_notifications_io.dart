// Natively: Android, iOS and macOS list the app's notifications the system
// shows (the notification plugin's getActiveNotifications); a Linux test
// session's notification server keeps a log and takes clicks
// (tool/notification_server.dart); Windows lists nothing for an app
// installed without a package. A click on Android goes through the runner
// on the host, which opens the shade and taps it (tool/android_system.dart):
// the test asks for it with a line the runner reads.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'acceptance_protocol.dart';
import 'system_notifications.dart';

String? get _log => Platform.isLinux ? Platform.environment['MURMUR_NOTIFY_LOG'] : null;

/// The notifications the system was given, oldest first; null where they
/// can't be read here.
Future<List<SystemNotification>?> systemNotifications() async {
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    return [
      for (final n in await FlutterLocalNotificationsPlugin().getActiveNotifications())
        (id: n.id, title: n.title ?? '', body: n.body ?? ''),
    ];
  }
  final log = _log;
  if (log == null) return null;
  return [
    for (final line in File(log).readAsLinesSync())
      if (line.trim().isNotEmpty)
        if (jsonDecode(line) case {'id': final int id, 'summary': final String title, 'body': final String body})
          (id: id, title: title, body: body),
  ];
}

/// Clicks `notification` as a user does, if the system here takes clicks
/// from a test; false where it doesn't (Apple's notification centre, Windows).
Future<bool> clickSystemNotification(SystemNotification notification) async {
  if (Platform.isAndroid) {
    debugPrint('$androidClickRequest${notification.title}');
    return true;
  }
  final log = _log, id = notification.id;
  if (log == null || id == null) return false;
  File('$log.click').writeAsStringSync('$id\n', mode: FileMode.append, flush: true);
  return true;
}
