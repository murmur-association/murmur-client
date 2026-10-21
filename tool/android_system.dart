// What a test inside the app can't do on Android: the system's own screens.
// The acceptance runner (tool/acceptance_test.dart) drives them from the
// host, through adb, while the suite runs in an emulator: it reads the
// screen (`uiautomator dump`), finds an element by its id or text, and taps
// it. So the notification permission is answered as a user would ("Allow"),
// a notification is opened from the shade, a fingerprint is enrolled and
// touched when the system asks for it, and the app's WorkManager job is
// found and run.

import 'dart:async';
import 'dart:io';

/// One element of the screen: its attributes, and its centre.
typedef ScreenNode = ({Map<String, String> attributes, int x, int y});

/// An Android device or emulator, driven through adb.
class AndroidSystem {
  AndroidSystem(this.serial, this.package);

  /// The device's serial (`emulator-5554`), and the app's application id.
  final String serial, package;

  /// The PIN set for the screen lock a fingerprint needs.
  static const pin = '4711';

  Future<ProcessResult> adb(List<String> args) => Process.run('adb', ['-s', serial, ...args]);

  Future<String> _shell(String command) async => '${(await adb(['shell', command])).stdout}';

  /// The elements on screen now; empty when the screen won't be read (it is
  /// changing, which uiautomator refuses).
  Future<List<ScreenNode>> screen() async {
    final xml = await _shell('uiautomator dump /sdcard/murmur-screen.xml >/dev/null && cat /sdcard/murmur-screen.xml');
    return [
      for (final node in RegExp(r'<node ([^>]*?)/?>').allMatches(xml))
        if (_node(node.group(1)!) case final n?) n,
    ];
  }

  static ScreenNode? _node(String raw) {
    final attributes = {for (final a in RegExp(r'([\w-]+)="([^"]*)"').allMatches(raw)) a.group(1)!: a.group(2)!};
    final b = RegExp(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]').firstMatch(attributes['bounds'] ?? '');
    if (b == null) return null;
    int at(int i) => int.parse(b.group(i)!);
    return (attributes: attributes, x: (at(1) + at(3)) ~/ 2, y: (at(2) + at(4)) ~/ 2);
  }

  /// The first element whose id ends with one of `ids`, or whose text (any
  /// case) is one of `texts`.
  static ScreenNode? find(List<ScreenNode> screen, {List<String> ids = const [], List<String> texts = const []}) {
    final wanted = {for (final t in texts) t.toLowerCase()};
    for (final n in screen) {
      final id = n.attributes['resource-id'] ?? '';
      if (ids.any((i) => id.endsWith(i))) return n;
      if (wanted.contains((n.attributes['text'] ?? '').toLowerCase())) return n;
    }
    return null;
  }

  Future<void> tap(ScreenNode n) => adb(['shell', 'input', 'tap', '${n.x}', '${n.y}']);

  /// Touches the emulator's fingerprint sensor with finger 1.
  Future<void> touchFinger() => adb(['emu', 'finger', 'touch', '1']);

  // ---- while the suite runs -----------------------------------------------------

  /// Whether a fingerprint is enrolled, so that the system's biometric
  /// prompts are answered by a touch.
  bool fingerprint = false;

  /// Answers the system's prompts as they come, until [stop]: the
  /// notification permission with "Allow", a biometric prompt with the
  /// enrolled finger.
  Future<void> watch() async {
    while (!_stopped) {
      final now = await screen();
      final allow = find(now, ids: const ['permission_allow_button'], texts: const ['Allow']);
      if (allow != null) {
        stdout.writeln('android: answering the permission prompt with "Allow"');
        await tap(allow);
      } else if (fingerprint && find(now, ids: const ['biometric_icon', 'biometric_scrollview']) != null) {
        stdout.writeln('android: touching the fingerprint sensor for the biometric prompt');
        await touchFinger();
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  bool _stopped = false;
  void stop() => _stopped = true;

  /// Opens the shade and taps the notification titled `title`; false if it
  /// isn't there.
  Future<bool> clickNotification(String title) async {
    await _shell('cmd statusbar expand-notifications');
    for (var i = 0; i < 15; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final n = find(await screen(), texts: [title]);
      if (n != null) {
        await tap(n);
        return true;
      }
    }
    await _shell('cmd statusbar collapse');
    return false;
  }

  // ---- the device's setup -------------------------------------------------------

  /// Sets a screen lock and enrolls finger 1, through Settings' own screens;
  /// true once the system says a fingerprint is enrolled.
  Future<bool> enrollFingerprint({Duration timeout = const Duration(minutes: 10)}) async {
    await _shell('locksettings set-pin $pin');
    await _shell('am start -a android.settings.FINGERPRINT_ENROLL');
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await fingerprintEnrolled()) {
        await _shell('input keyevent KEYCODE_HOME');
        return true;
      }
      final now = await screen();
      // The PIN, when Settings asks for it again.
      if (find(now, ids: const ['password_entry', 'lockPassword']) != null) {
        await _shell('input text $pin && input keyevent KEYCODE_ENTER');
      } else if (find(now, texts: const ['Done', 'Next', 'I agree', 'Agree', 'More', 'Continue', 'Start']) case final b?) {
        await tap(b);
      } else {
        // The sensor's screen: touch, lift, touch again.
        await touchFinger();
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return false;
  }

  /// Whether a fingerprint is enrolled for the device's user.
  Future<bool> fingerprintEnrolled() async =>
      RegExp(r'"count":\s*[1-9]|enrollments?[^0-9]{1,8}[1-9]').hasMatch(await _shell('dumpsys fingerprint'));

  // ---- the app's background job -------------------------------------------------

  /// The scheduler's id of the app's WorkManager job, if one is scheduled.
  Future<String?> backgroundJob() async {
    final jobs = await _shell('dumpsys jobscheduler');
    return RegExp('JOB #\\S+/(\\d+): \\S+ ${RegExp.escape(package)}/androidx\\.work').firstMatch(jobs)?.group(1);
  }

  /// Runs the app's background job now, as the system would; whether the
  /// app's log then shows its Dart side ran (`marker`, within `timeout`).
  Future<bool> runBackgroundJob(String job, String marker, {Duration timeout = const Duration(minutes: 3)}) async {
    await adb(['logcat', '-c']);
    await _shell('cmd jobscheduler run -f $package $job');
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if ('${(await adb(['logcat', '-d'])).stdout}'.contains(marker)) return true;
      await Future<void>.delayed(const Duration(seconds: 5));
    }
    return false;
  }
}

/// The app's application id, from its Android project (null without one).
String? androidApplicationId() {
  final gradle = [File('android/app/build.gradle.kts'), File('android/app/build.gradle')]
      .where((f) => f.existsSync())
      .firstOrNull;
  return gradle == null
      ? null
      : RegExp(r"""applicationId\s*=?\s*["']([^"']+)["']""").firstMatch(gradle.readAsStringSync())?.group(1);
}
