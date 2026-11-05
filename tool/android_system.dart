// What a test inside the app can't do on Android: the system's own screens.
// The acceptance runner (tool/acceptance_test.dart) drives them from the
// host, through adb, while the suite runs in an emulator: it reads the
// screen (`uiautomator dump`), finds an element by its id or text, and taps
// it. So the notification permission is answered as a user would ("Allow"),
// a notification is opened from the shade, a fingerprint is enrolled and
// touched when the system asks for it, and the app's WorkManager job is
// found and run.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import '../test/support/host.dart';

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
    // Not while the shade still slides down: an element found then is
    // tapped where it was, beside where it ends up.
    await Future<void>.delayed(const Duration(seconds: 2));
    final tapped = await poll(() async {
      final n = find(await screen(), texts: [title]);
      if (n != null) await tap(n);
      return n != null;
    }, timeout: const Duration(seconds: 30), every: const Duration(seconds: 2));
    if (!tapped) await _shell('cmd statusbar collapse');
    return tapped;
  }

  // ---- the picture chooser ------------------------------------------------------

  /// What the picture the runner picks is called on the device.
  static const pictureName = 'murmur-acceptance.png';

  /// Puts `hostFile` in the device's Downloads, and has the media store
  /// list it, so the photo picker and the Files app both offer it.
  Future<void> placePicture(String hostFile) async {
    await adb(['push', hostFile, '/sdcard/Download/$pictureName']);
    await _shell('content call --uri content://media --method scan_volume --arg external_primary');
    await _shell('am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Download/$pictureName');
  }

  /// The screen once a chooser of the system's is on it: an app other than
  /// this one and the system's own bar. Null if none comes.
  Future<List<ScreenNode>?> _chooser({Duration timeout = const Duration(minutes: 2)}) async {
    var now = <ScreenNode>[];
    final came = await poll(() async {
      now = await screen();
      final others = {for (final n in now) n.attributes['package'] ?? ''}..removeAll({'', package, 'com.android.systemui'});
      return others.isNotEmpty;
    }, timeout: timeout, every: const Duration(seconds: 1));
    return came ? now : null;
  }

  /// Cancels the chooser the app opens, as the Back key does; false if none
  /// came.
  Future<bool> cancelChooser() async {
    if (await _chooser() == null) return false;
    await _shell('input keyevent KEYCODE_BACK');
    return true;
  }

  /// Picks [pictureName] in the chooser the app opens: the photo picker (its
  /// first photo, the only one on the device) or the Files app (the file by
  /// name, from Downloads if it isn't listed at first). False if it can't.
  Future<bool> pickPicture({Duration timeout = const Duration(minutes: 3)}) async {
    if (await _chooser() == null) return false;
    final began = DateTime.now();
    // What the chooser showed, for a failure's report: every element, since
    // a file may be named in its description rather than its text.
    var last = <ScreenNode>[];
    // Downloads is tapped once: tapping it again while its list loads
    // started the list over (GitHub's runner, 2026-11-03).
    var openedDownloads = false;
    final stem = pictureName.substring(0, pictureName.lastIndexOf('.'));
    final picked = await poll(() async {
      final now = await screen();
      if (now.isNotEmpty) last = now;
      // By name, with or without its extension (Files may leave it out),
      // in the element's text or its description.
      final byName = now.where((n) =>
          (n.attributes['text'] ?? '').startsWith(stem) || (n.attributes['content-desc'] ?? '').startsWith(stem)).firstOrNull;
      final photo = now.where((n) =>
          (n.attributes['resource-id'] ?? '').endsWith(':id/icon_thumbnail') ||
          (n.attributes['content-desc'] ?? '').startsWith('Photo taken')).firstOrNull;
      final roots = now.where((n) => n.attributes['content-desc'] == 'Show roots').firstOrNull;
      final downloads = find(now, texts: const ['Downloads']);
      // The device's storage in the side panel (its summary says how much is
      // free), and the Download folder in it: Files' "Downloads" lists only
      // what the system took as a download, which a pushed file may not be
      // (GitHub's runner showed it empty, 2026-11-03).
      final storage = now.where((n) => RegExp(r'\bfree$').hasMatch(n.attributes['text'] ?? '')).firstOrNull;
      final folder = find(now, texts: const ['Download']);
      final late = DateTime.now().difference(began) > const Duration(seconds: 20);
      if (byName ?? photo case final n?) {
        await tap(n);
        return true;
      } else if (!late && downloads != null && !openedDownloads) {
        openedDownloads = true;
        await tap(downloads);
      } else if (!late && roots != null && !openedDownloads) {
        await tap(roots);
      } else if (late && folder != null) {
        await tap(folder);
      } else if (late && storage != null) {
        await tap(storage);
      } else if (late && roots != null) {
        await tap(roots);
      }
      return false;
    }, timeout: timeout, every: const Duration(seconds: 2));
    if (picked) return true;
    print('android: the picture was not found in the chooser; it last showed:');
    for (final n in last) {
      final a = n.attributes;
      if ((a['text'] ?? '').isEmpty && (a['content-desc'] ?? '').isEmpty && (a['resource-id'] ?? '').isEmpty) continue;
      print('  ${a['resource-id']} text="${a['text']}" desc="${a['content-desc']}" class=${a['class']}');
    }
    return false;
  }

  // ---- the device's setup -------------------------------------------------------

  /// Sets a screen lock and enrolls finger 1, through Settings' own screens;
  /// true once the system says a fingerprint is enrolled. Given long: an
  /// emulator without KVM takes many seconds a screen.
  Future<bool> enrollFingerprint({Duration timeout = const Duration(minutes: 25)}) async {
    await _shell('locksettings set-pin $pin');
    await _shell('am start -a android.settings.FINGERPRINT_ENROLL');
    // What Settings showed, for a failure's report: the last few screens.
    final seen = <String>[];
    final enrolled = await poll(() async {
      if (await fingerprintEnrolled()) return true;
      final now = await screen();
      final texts = [for (final n in now) if (n.attributes['text'] case final t? when t.isNotEmpty) t].join(' | ');
      if (seen.isEmpty || seen.last != texts) seen.add(texts);
      // The PIN, when Settings asks for it again.
      if (find(now, ids: const ['password_entry', 'lockPassword']) != null) {
        await _shell('input text $pin && input keyevent KEYCODE_ENTER');
      } else if (find(now, texts: const ['Done', 'Next', 'I agree', 'Agree', 'More', 'Continue', 'Start']) case final b?) {
        await tap(b);
      } else {
        // The sensor's screen: touch, lift, touch again.
        await touchFinger();
      }
      return false;
    }, timeout: timeout, every: const Duration(seconds: 2));
    if (enrolled) {
      await _shell('input keyevent KEYCODE_HOME');
      return true;
    }
    // Back as it was: a PIN without a fingerprint leaves a lock screen, and
    // a key store asking for the PIN, that nobody answers.
    print('android: no fingerprint enrolled; Settings last showed:\n'
        '${seen.skip(seen.length > 5 ? seen.length - 5 : 0).map((t) => '  $t').join('\n')}');
    await _shell('locksettings clear --old $pin');
    await _shell('input keyevent KEYCODE_HOME');
    return false;
  }

  /// Whether a fingerprint is enrolled for the device's user.
  Future<bool> fingerprintEnrolled() async =>
      RegExp(r'"count":\s*[1-9]|enrollments?[^0-9]{1,8}[1-9]').hasMatch(await _shell('dumpsys fingerprint'));

  // ---- the app's background job -------------------------------------------------

  /// The app's WorkManager job, if one is scheduled: its id, and the
  /// namespace Android 14 lists it under (`JOB androidx.work.systemjobscheduler:u0a192/1:
  /// f745f69 @androidx.work.systemjobscheduler@info.murmur.client/androidx.work…`),
  /// or null where jobs have none (`JOB #u0a192/1: f745f69 info.murmur.client/androidx.work…`).
  Future<({String? namespace, String id})?> backgroundJob() async {
    final jobs = await _shell('dumpsys jobscheduler');
    final job = RegExp('JOB (?:([\\w.]+):)?#?\\w+/(\\d+): \\S+ (?:@[\\w.]+@)?${RegExp.escape(package)}/androidx\\.work')
        .firstMatch(jobs);
    return job == null ? null : (namespace: job.group(1), id: job.group(2)!);
  }

  /// The job scheduler's lines that name the app, for a failure's report.
  Future<String> scheduledJobsText() async {
    final jobs = (await _shell('dumpsys jobscheduler')).split('\n');
    return [for (final line in jobs) if (line.contains(package)) '  ${line.trim()}'].take(40).join('\n');
  }

  /// Leaves the app a word: the file `name` in its own folder (where
  /// path_provider's support directory is), which only a debuggable app's
  /// `run-as` reaches.
  Future<void> tellApp(String name) =>
      adb(['shell', "run-as $package sh -c 'mkdir -p files && touch files/$name'"]);

  /// Runs the app's background job now, as the system would; whether the
  /// app's log then shows its Dart side ran (`marker`, within `timeout`).
  Future<bool> runBackgroundJob(({String? namespace, String id}) job, String marker,
      {Duration timeout = const Duration(minutes: 3)}) async {
    await adb(['logcat', '-c']);
    final namespace = job.namespace == null ? '' : '-n ${job.namespace} ';
    print('android: running the background job: ${(await _shell('cmd jobscheduler run -f $namespace$package ${job.id}')).trim()}');
    return poll(() async => '${(await adb(['logcat', '-d'])).stdout}'.contains(marker),
        timeout: timeout, every: const Duration(seconds: 5));
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
