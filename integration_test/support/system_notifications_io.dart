// Natively: a Linux test session's notification server keeps a log, and
// takes clicks (tool/notification_server.dart). Nothing to read elsewhere.

import 'dart:convert';
import 'dart:io';

import 'system_notifications.dart';

String? get _log => Platform.isLinux ? Platform.environment['MURMUR_NOTIFY_LOG'] : null;

/// The notifications the system was given, oldest first; null where they
/// can't be read here.
Future<List<SystemNotification>?> systemNotifications() async {
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
/// from a test; false where it doesn't.
Future<bool> clickSystemNotification(SystemNotification notification) async {
  final log = _log, id = notification.id;
  if (log == null || id == null) return false;
  File('$log.click').writeAsStringSync('$id\n', mode: FileMode.append, flush: true);
  return true;
}
