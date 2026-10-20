// A stand-in for a desktop's notification server, in a Linux test session
// (tool/linux_session.sh): it owns org.freedesktop.Notifications on the
// session bus, as a desktop's does, and writes each notification it is
// given to a log, one JSON object a line ({"id", "app", "summary", "body"}).
// A test "clicks" one by writing its id as a line to the log's `.click`
// file: the server then sends ActionInvoked for it, as a desktop does when
// the user clicks a notification.
//
//   dart run tool/notification_server.dart <log file>
//
// The log is created once the name is owned, so a session can wait for it.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dbus/dbus.dart';

const _interface = 'org.freedesktop.Notifications';

class _Notifications extends DBusObject {
  _Notifications(this.log) : super(DBusObjectPath('/org/freedesktop/Notifications'));

  final File log;
  var _next = 1;

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall call) async {
    if (call.interface != _interface) return DBusMethodErrorResponse.unknownInterface();
    switch (call.name) {
      case 'Notify':
        final v = call.values;
        // Replacing one keeps its id, as a desktop does. (Typed loosely: a
        // caller without the interface's description may send any integer.)
        final replaces = switch (v[1]) {
          DBusUint32(:final value) || DBusInt32(:final value) => value,
          _ => 0,
        };
        final id = replaces != 0 ? replaces : _next++;
        log.writeAsStringSync(
            '${jsonEncode({'id': id, 'app': v[0].asString(), 'summary': v[3].asString(), 'body': v[4].asString()})}\n',
            mode: FileMode.append,
            flush: true);
        return DBusMethodSuccessResponse([DBusUint32(id)]);
      case 'CloseNotification':
        await emitSignal(_interface, 'NotificationClosed', [call.values[0], const DBusUint32(3)]);
        return DBusMethodSuccessResponse();
      case 'GetCapabilities':
        return DBusMethodSuccessResponse([DBusArray.string(const ['body', 'actions'])]);
      case 'GetServerInformation':
        return DBusMethodSuccessResponse(
            const [DBusString('murmur-test'), DBusString('Murmur'), DBusString('1'), DBusString('1.2')]);
    }
    return DBusMethodErrorResponse.unknownMethod();
  }

  /// Clicks the notification `id`: its default action.
  Future<void> click(int id) => emitSignal(_interface, 'ActionInvoked', [DBusUint32(id), const DBusString('default')]);
}

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    print('usage: dart run tool/notification_server.dart <log file>');
    exit(64);
  }
  final log = File(args.single);
  final clicks = File('${log.path}.click');
  final client = DBusClient.session();
  final object = _Notifications(log);
  await client.registerObject(object);
  final reply = await client.requestName(_interface, flags: {DBusRequestNameFlag.doNotQueue});
  if (reply != DBusRequestNameReply.primaryOwner) {
    print('another notification server owns $_interface');
    exit(1);
  }
  log.writeAsStringSync('');
  // Clicks asked for, read as they're added.
  var done = 0;
  Timer.periodic(const Duration(milliseconds: 200), (_) async {
    if (!clicks.existsSync()) return;
    final lines = clicks.readAsLinesSync();
    for (; done < lines.length; done++) {
      final id = int.tryParse(lines[done].trim());
      if (id != null) await object.click(id);
    }
  });
}
