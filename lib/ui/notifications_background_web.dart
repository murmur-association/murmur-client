// Browsers have no background checks: notifications come only while the
// page is open (ui/notifications.dart).

/// Nothing to register: there's no other isolate to tell.
void registerAppPort() {}

/// Nothing to schedule.
Future<void> scheduleBackgroundChecks(bool on) async {}
