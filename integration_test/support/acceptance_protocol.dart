// Lines the app under test prints for the runner on the host
// (tool/acceptance_test.dart), which reads the app's output: what only the
// host can do, on an Android emulator (tool/android_system.dart) or in a
// desktop's file dialog (tool/system_chooser.dart).

/// Asks the runner to open the shade and tap the notification with the
/// title that follows.
const androidClickRequest = 'ACCEPTANCE CLICK NOTIFICATION: ';

/// Asks the runner to run the app's WorkManager job now, as Android would,
/// and check its Dart side ran (`backgroundCheckLog` in its log).
const androidBackgroundJobRequest = 'ACCEPTANCE RUN BACKGROUND JOB';

/// Asks the runner to pick its picture file in the system's chooser that
/// the app is about to open, for the source that follows (`photos` or
/// `files`, as `PictureSource` names them): on Android, Linux and Windows
/// (tool/system_chooser.dart). A browser's driver fills the page's file
/// input by itself, unasked (test_driver/integration_test.dart).
const chooserPickRequest = 'ACCEPTANCE PICK PICTURE: ';

/// Asks the runner to cancel the system's chooser that the app is about to
/// open, for the source that follows.
const chooserCancelRequest = 'ACCEPTANCE CANCEL CHOOSER: ';

/// The file the runner and a browser's driver pick: the app's own icon,
/// a PNG every checkout has.
const chooserPictureFile = 'web/icons/Icon-192.png';
