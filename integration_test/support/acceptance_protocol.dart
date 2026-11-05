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

/// The file the runner writes into the app's own folder once it has run the
/// background job (whatever came of it): the app waits for it before it
/// switches notifications off, which cancels the job.
const androidBackgroundJobDone = 'acceptance-background-job-done';

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

/// Asks the runner of the phone storage test (tool/phone_storage_test.dart)
/// to have the system clear apps' caches, as it does when storage runs
/// short: on Android, `pm trim-caches`.
const phoneClearCachesRequest = 'PHONE STORAGE CLEAR CACHES';

/// The file the runner writes into the app's own folder once the system has
/// cleared the caches (whatever came of it).
const phoneCachesCleared = 'phone-storage-caches-cleared';
