// Checks for news while the app is closed: Android only (WorkManager). The
// web has no such checks, and no isolates to tell the app's own from.

export 'notifications_background_io.dart' if (dart.library.js_interop) 'notifications_background_web.dart';
