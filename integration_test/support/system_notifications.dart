// What the system itself shows of the app's notifications, where a test can
// read it back: on Linux from the session's stand-in notification server
// (tool/notification_server.dart, started by tool/linux_session.sh), in a
// browser from the page's service worker. Elsewhere (Windows, Android until
// a native driver reads the shade) only what the app handed the system is
// known: `SystemNotifier.onShown`.

export 'system_notifications_io.dart' if (dart.library.js_interop) 'system_notifications_web.dart';

/// One notification the system shows. `id` is the system's own, where a
/// click can be sent to it.
typedef SystemNotification = ({int? id, String title, String body});
