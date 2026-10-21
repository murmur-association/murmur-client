// Lines the app under test prints for the runner on the host
// (tool/acceptance_test.dart), which reads the app's output: what only the
// host can do, on an Android emulator (tool/android_system.dart).

/// Asks the runner to open the shade and tap the notification with the
/// title that follows.
const androidClickRequest = 'ACCEPTANCE CLICK NOTIFICATION: ';

/// Asks the runner to run the app's WorkManager job now, as Android would,
/// and check its Dart side ran (`backgroundCheckLog` in its log).
const androidBackgroundJobRequest = 'ACCEPTANCE RUN BACKGROUND JOB';
