// Runs the acceptance tests (integration_test/acceptance_test.dart) on one
// flavour of the app, against a node of their own: a demo chain built for
// the run, served and mined on by the pinned murmur-node release
// (test/support/test_node.dart), paying a wallet made for the run.
//
//   flutter test tool/acceptance_test.dart                             # this desktop: Windows, Linux or macOS
//   ACCEPTANCE_DEVICE=chrome flutter test tool/acceptance_test.dart    # a browser, with a passphrase
//   ACCEPTANCE_DEVICE=chrome-passkey flutter test tool/acceptance_test.dart   # a browser, with a passkey
//   ACCEPTANCE_DEVICE=firefox flutter test tool/acceptance_test.dart   # Firefox (Linux)
//   ACCEPTANCE_DEVICE=safari flutter test tool/acceptance_test.dart    # Safari (macOS, after `sudo safaridriver --enable`)
//   ACCEPTANCE_DEVICE=emulator-5554 flutter test tool/acceptance_test.dart   # an Android emulator
//   ACCEPTANCE_DEVICE=$(tool/ios_simulator.sh) flutter test tool/acceptance_test.dart   # an iPhone simulator (macOS)
//
// A browser run uses a pinned browser and its WebDriver (`dart run
// tool/fetch_test_browser.dart chrome|firefox` downloads them), or the
// system's own Safari and safaridriver: the driver is started here, on port
// 4444, and stopped afterwards. ACCEPTANCE_HEADED shows the browser (Safari
// always shows). Not Edge: `flutter drive` asks Edge's driver for a browser
// it doesn't know by that name.
//
// What the machine can't do is said in the environment:
// ACCEPTANCE_NO_NOTIFICATIONS (it can't show the system's notifications, so
// the notification test skips itself) and ACCEPTANCE_NO_CHOOSER (nothing
// can work the system's file dialog from outside the app: no desktop, so a
// file is handed over in its place).
//
// The app in the test keeps its settings and secrets in memory
// (app_driver.dart), and a desktop app its local copy, its own messages and
// its node's data in a folder thrown away with the run (MURMUR_DATA_HOME),
// so this can run where the app is used. On Linux it still needs a display:
// tool/linux_session.sh gives one.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/services/local_node_io.dart' show stopLeftNode;
import 'package:murmur_client/ui/notifications.dart' show backgroundCheckLog;

import '../integration_test/support/acceptance_protocol.dart';
import '../test/support/host.dart';
import '../test/support/test_node.dart';
import 'android_system.dart';
import 'fetch_test_browser.dart';
import 'system_chooser.dart';

final _env = Platform.environment;
final _device = _env['ACCEPTANCE_DEVICE'] ?? Platform.operatingSystem;
const _browsers = {'chrome', 'chrome-passkey', 'firefox', 'safari'};

/// Whether the environment says so (any value).
bool _said(String name) => _env[name] != null;

/// The browser `flutter drive` drives for a browser flavour.
String get _browserName => _device == 'chrome-passkey' ? 'chrome' : _device;
const _suite = 'integration_test/acceptance_test.dart';

/// A device far slower than a desktop (ACCEPTANCE_SLOW): the suite waits longer.
final _slow = _said('ACCEPTANCE_SLOW');

/// A port nothing listens on now.
Future<int> _freePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

/// Starts the browser's WebDriver on the port `flutter drive` expects, and
/// waits until it answers.
Future<Process> _startWebDriver() async {
  // Safari's driver is the system's own (enabled once with `sudo
  // safaridriver --enable`); the others are pinned downloads.
  final String program;
  if (_browserName == 'safari') {
    program = '/usr/bin/safaridriver';
  } else {
    final pinned = testBrowserNamed(_browserName);
    if (!pinned.ready) {
      fail('No $_browserName ${pinned.version} in ${pinned.dir.path}: '
          'run `dart run tool/fetch_test_browser.dart $_browserName`.');
    }
    program = pinned.driver.path;
  }
  final driver = await Process.start(program, [
    if (_browserName == 'safari') ...['--port', '4444'] else '--port=4444',
    if (_browserName == 'firefox') '--binary=${testBrowserNamed('firefox').browser.path}',
  ]);
  // Kept for a failure's report: a driver that won't start says why.
  final said = StringBuffer();
  eachLine(driver, said.writeln);
  final listening = await poll(() async {
    try {
      (await Socket.connect(InternetAddress.loopbackIPv4, 4444)).destroy();
      return true;
    } on SocketException {
      return false;
    }
  }, timeout: const Duration(seconds: 30), every: const Duration(milliseconds: 200));
  if (!listening) fail('$program did not listen on port 4444; it said: $said');
  return driver;
}

/// Flutter's web server settings (web_dev_config.yaml) that serve the page
/// with the headers Cloudflare gives app.murmur.info (`headers`, web/_headers
/// in Cloudflare's format), plus one thing only the test needs: its node,
/// a plain WebSocket on this machine, among the places the page may connect
/// to (`node`; the public page reaches its nodes over wss:).
String webDevConfig(String headers, {required String node}) {
  final yaml = StringBuffer('# Written by tool/acceptance_test.dart for a browser run, and removed after.\n'
      'server:\n  headers:\n');
  for (final line in headers.split('\n')) {
    final header = RegExp(r'^\s+([A-Za-z-]+):\s*(.*?)\s*$').firstMatch(line);
    if (header == null) continue;
    var value = header[2]!;
    if (header[1]!.toLowerCase() == 'content-security-policy') {
      value = value.replaceFirstMapped(RegExp(r'connect-src([^;]*)'), (m) => 'connect-src${m[1]} $node');
    }
    yaml.write('    - name: "${header[1]}"\n      value: "${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"\n');
  }
  return '$yaml';
}

/// Stops the node the app under test may have left running in the run's
/// data folder (a test that failed midway never switched it off), as the
/// app itself would at its next start, then removes the folder.
Future<void> _throwAway(Directory dataHome) async {
  final sep = Platform.pathSeparator;
  await stopLeftNode('${dataHome.path}${sep}murmur-client${sep}node');
  try {
    dataHome.deleteSync(recursive: true);
  } on FileSystemException {
    // Still held for a moment by the node on its way out.
  }
}

/// Finds the app's WorkManager job (scheduled once notifications are on),
/// runs it as Android would, and says whether its Dart side ran.
Future<bool> _runBackgroundJob(AndroidSystem android) async {
  ({String? namespace, String id})? job;
  if (await poll(() async => (job = await android.backgroundJob()) != null,
      timeout: const Duration(minutes: 1), every: const Duration(seconds: 2))) {
    return android.runBackgroundJob(job!, backgroundCheckLog);
  }
  print('android: no background job was scheduled; the scheduler lists for the app:');
  print(await android.scheduledJobsText());
  return false;
}

void main() {
  test('acceptance: the app on $_device, against a node of its own', () async {
    final browser = _browsers.contains(_device);
    // The browser is given a virtual passkey authenticator
    // (test_driver/integration_test.dart), and the app uses it.
    final passkey = _device == 'chrome-passkey';
    // A key for this run only, on a chain thrown away with it: the one seed
    // that may be passed around in the clear.
    final wallet = await MurmurWallet.generate();
    final node = await TestNode.build(300, mineTo: wallet.address);
    // Browsers reach a node over WebSocket only.
    final webSocket = browser ? await _freePort() : null;
    await node.start(mineTo: wallet.address, webSocketPort: webSocket);
    // An Android emulator reaches this machine as 10.0.2.2.
    final host = _device.startsWith('emulator-') ? '10.0.2.2' : '127.0.0.1';
    // A desktop app keeps its local copy, its own messages and its node's
    // data under MURMUR_DATA_HOME: a folder thrown away with the run, never
    // the user's (the demo chain would replace the user's local copy). Its
    // node is the pinned one, on the demo network.
    final desktop = _device == 'windows' || _device == 'linux' || _device == 'macos';
    final dataHome = desktop ? await Directory.systemTemp.createTemp('murmur-acceptance') : null;
    if (dataHome != null) addTearDown(() => _throwAway(dataHome));
    // Safari's driver has no way to grant notifications (WebDriver's Set
    // Permission) nor to give a file input its file.
    final noNotifications = _said('ACCEPTANCE_NO_NOTIFICATIONS') || _device == 'safari';
    final settings = [
      '--dart-define=ACCEPTANCE_NODE=$host:${webSocket ?? node.port}',
      '--dart-define=ACCEPTANCE_SEED=${toHex(wallet.seed)}',
      if (desktop) ...['--dart-define=ACCEPTANCE_OWN_NODE=true', '--dart-define=MURMUR_LOCAL_NODE_SPEC=demo'],
      if (passkey) '--dart-define=ACCEPTANCE_PASSKEY=true',
      // A machine that can't show the system's notifications.
      if (noNotifications) '--dart-define=ACCEPTANCE_NO_NOTIFICATIONS=true',
      // A device far slower than a desktop (an emulator without KVM).
      if (_slow) '--dart-define=ACCEPTANCE_SLOW=true',
    ];
    if (browser) {
      final driver = await _startWebDriver();
      addTearDown(driver.kill);
      // The page is served with app.murmur.info's own headers (web/_headers),
      // its Content-Security-Policy above all: a policy that blocked the
      // picked picture's read passed tests served without it.
      final config = File('web_dev_config.yaml');
      if (config.existsSync()) fail('web_dev_config.yaml is in the way: the runner writes its own');
      config.writeAsStringSync(webDevConfig(File('web/_headers').readAsStringSync(), node: 'ws://127.0.0.1:$webSocket'));
      addTearDown(() => config.existsSync() ? config.deleteSync() : null);
    }
    // An Android emulator's system screens are the runner's to answer
    // (tool/android_system.dart): a fingerprint enrolled first, so the
    // wallet goes under the device's lock as on a phone; then, while the
    // suite runs, its prompts answered and its requests done.
    final android = _device.startsWith('emulator-') ? AndroidSystem(_device, androidApplicationId()!) : null;
    if (android != null) {
      android.fingerprint = await android.enrollFingerprint();
      print('android: a fingerprint is ${android.fingerprint ? '' : 'not '}enrolled');
      if (android.fingerprint) settings.add('--dart-define=ACCEPTANCE_DEVICE_LOCK=true');
      unawaited(android.watch());
      addTearDown(android.stop);
    }
    // Whether the app's background job ran when the runner ran it: null
    // until the suite asks.
    bool? backgroundJobRan;
    // The system's picture chooser, worked from outside the app wherever it
    // can be: by the browser's driver (test_driver/integration_test.dart),
    // through adb on Android, by tool/system_chooser.dart on a desktop with
    // a screen. Elsewhere the suite hands over a file in its place.
    // In the system's own form (backslashes on Windows, whose file dialog
    // takes no other).
    final picture = File(chooserPictureFile).resolveSymbolicLinksSync();
    final (desktopChooser, chooserWhy) = !desktop
        ? (null, 'not a desktop')
        : _said('ACCEPTANCE_NO_CHOOSER')
            ? (null, 'no desktop to work it on')
            : await SystemChooser.here();
    final chooser = browser && _device != 'safari'
        ? 'browser'
        : android != null || desktopChooser != null
            ? 'host'
            : '';
    print('the picture chooser: ${switch (chooser) {
      'browser' => "the browser's driver",
      'host' => android != null ? 'adb' : chooserWhy,
      _ => 'none here ($chooserWhy): a file is handed over in its place',
    }}');
    if (chooser.isNotEmpty) settings.add('--dart-define=ACCEPTANCE_SYSTEM_CHOOSER=$chooser');
    await android?.placePicture(picture);
    // What the runner did with each request, for a failure's report.
    final chooserDone = <String>[];
    Future<void> answerChooser(String line) async {
      final cancel = line.contains(chooserCancelRequest);
      final done = android != null
          ? await (cancel ? android.cancelChooser() : android.pickPicture())
          : await (cancel ? desktopChooser!.cancel() : desktopChooser!.pick(picture));
      chooserDone.add('${cancel ? 'cancel' : 'pick'}: $done');
      print('the picture chooser: ${chooserDone.last}');
    }
    final args = !browser
        ? ['test', _suite, '-d', _device, ...settings]
        : [
            'drive',
            '--driver=test_driver/integration_test.dart',
            '--target=$_suite',
            '-d', 'web-server',
            // As app.murmur.info is built: a release build, CanvasKit served
            // from the page. (A debug build can't run under the page's
            // Content-Security-Policy, which the run applies.)
            '--release', '--no-web-resources-cdn',
            '--browser-name=$_browserName',
            if (_browserName == 'chrome') '--chrome-binary=${testBrowserNamed('chrome').browser.path}',
            // Safari has no headless mode.
            if (!_said('ACCEPTANCE_HEADED') && _browserName != 'safari') '--headless',
            ...settings,
          ];
    print('flutter ${args.where((a) => !a.contains('ACCEPTANCE_SEED')).join(' ')}');
    // Not with what `flutter test` sets for the tests it runs itself, this
    // one included: FONTCONFIG_FILE hides the system's fonts, and the app
    // then can't measure a line of monospace text. Nor with GITHUB_ACTIONS:
    // under it `flutter test` picks its GitHub reporter, which holds a
    // test's output until the test ends, and the requests the app prints for
    // this runner to answer (the system's chooser, Android's screens) came
    // only after the test had timed out waiting for them.
    final environment = {
      for (final MapEntry(:key, :value) in _env.entries)
        if (key != 'FONTCONFIG_FILE' && key != 'FLUTTER_TEST' && key != 'GITHUB_ACTIONS') key: value,
      if (dataHome != null) ...{'MURMUR_NODE_BIN': nodeBinary!, 'MURMUR_DATA_HOME': dataHome.path},
      if (passkey) 'ACCEPTANCE_PASSKEY': '1',
      // The file a browser's driver gives the page's file input.
      if (chooser == 'browser') 'ACCEPTANCE_PICTURE_FILE': picture,
    };
    final flutter = await Process.start(Platform.isWindows ? 'flutter.bat' : 'flutter', args,
        environment: environment, includeParentEnvironment: false, runInShell: Platform.isWindows);
    final output = DeviceOutput();
    output.capture(() => eachLine(flutter, (line) {
          output.add(line);
          if (chooser == 'host' && (line.contains(chooserPickRequest) || line.contains(chooserCancelRequest))) {
            unawaited(answerChooser(line));
          }
          if (android == null) return;
          final click = line.indexOf(androidClickRequest);
          if (click >= 0) {
            final title = line.substring(click + androidClickRequest.length).trim();
            android.clickNotification(title).then((done) => print('android: clicked "$title": $done'));
          } else if (line.contains(androidBackgroundJobRequest)) {
            _runBackgroundJob(android).then((ran) async {
              backgroundJobRan = ran;
              print('android: the background job ran: $ran');
              // The app waits for this before it switches notifications off,
              // which cancels the job.
              await android.tellApp(androidBackgroundJobDone);
            });
          }
        }));
    expect(output.failed(await flutter.exitCode, 'the acceptance tests on $_device', node: node.node.recentOutput), isFalse,
        reason: 'the acceptance tests on $_device');
    if (android != null) expect(backgroundJobRan, isTrue, reason: "the app's background job, run as Android runs it");
    // A cancel and a pick from each source the device offers (Android has
    // two), each done in the system's own chooser.
    if (chooser == 'host') {
      expect(
          chooserDone,
          [
            for (final _ in android != null ? [1, 2] : [1]) 'cancel: true',
            for (final _ in android != null ? [1, 2] : [1]) 'pick: true',
          ],
          reason: "the system's picture chooser, worked from outside the app");
    }
  }, skip: nodeSkip, timeout: Timeout(Duration(minutes: _slow ? 150 : 30)));
}
