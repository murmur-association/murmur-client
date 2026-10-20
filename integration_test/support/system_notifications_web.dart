// In a browser: the notifications the page's service workers show (the
// plugin shows them through a worker of its own, registered under its
// assets, so not the one for the page's address). A page can't click one:
// that takes a user.

import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'system_notifications.dart';

/// The notifications the browser shows for this page's origin.
Future<List<SystemNotification>?> systemNotifications() async {
  final registrations = (await web.window.navigator.serviceWorker.getRegistrations().toDart).toDart;
  return [
    for (final registration in registrations)
      for (final n in (await registration.getNotifications().toDart).toDart) (id: null, title: n.title, body: n.body),
  ];
}

/// Pages can't click notifications.
Future<bool> clickSystemNotification(SystemNotification notification) async => false;
