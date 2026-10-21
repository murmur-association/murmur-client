// Runs the acceptance tests (integration_test/acceptance_test.dart) on one
// flavour of the app, against a node of their own: a demo chain built for
// the run, served and mined on by the pinned murmur-node release
// (test/support/test_node.dart), paying a wallet made for the run.
//
//   flutter test tool/acceptance_test.dart                             # this desktop: Windows, Linux or macOS
//   ACCEPTANCE_DEVICE=chrome flutter test tool/acceptance_test.dart    # a browser, with a passphrase
//   ACCEPTANCE_DEVICE=chrome-passkey flutter test tool/acceptance_test.dart   # a browser, with a passkey
//   ACCEPTANCE_DEVICE=firefox flutter test tool/acceptance_test.dart   # Firefox (Linux)
//   ACCEPTANCE_DEVICE=safari flutter test tool/acceptance_test.dart    # Safari (macOS)
//   ACCEPTANCE_DEVICE=emulator-5554 flutter test tool/acceptance_test.dart   # an Android emulator
//   ACCEPTANCE_DEVICE=$(tool/ios_simulator.sh) flutter test tool/acceptance_test.dart   # an iPhone simulator (macOS)
//
// A browser run uses a pinned browser and its WebDriver (`dart run
// tool/fetch_test_browser.dart chrome|firefox` downloads them), or Safari's
// own safaridriver (enabled once with `sudo safaridriver --enable`): the
// driver is started here, on port 4444, and stopped afterwards.
// ACCEPTANCE_HEADED shows the browser. Not Edge: `flutter drive` asks Edge's
// driver for a browser it doesn't know by that name.
//
// The app in the test keeps nothing on the device (app_driver.dart), so
// this can run where the app is used. On Linux it still needs a display:
// tool/linux_session.sh gives one.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/bytes.dart';

import 'package:murmur_client/ui/notifications.dart' show backgroundCheckLog;

import '../integration_test/support/acceptance_protocol.dart';
import '../test/support/test_node.dart';
import 'android_system.dart';
import 'fetch_test_browser.dart';

final _env = Platform.environment;
final _device = _env['ACCEPTANCE_DEVICE'] ?? Platform.operatingSystem;
const _browsers = {'chrome', 'chrome-passkey', 'firefox', 'safari'};

/// The browser `flutter drive` drives for a browser flavour.
String get _browserName => _device == 'chrome-passkey' ? 'chrome' : _device;
const _suite = 'integration_test/acceptance_test.dart';

/// A device far slower than a desktop (ACCEPTANCE_SLOW): the suite waits longer.
final _slow = _env['ACCEPTANCE_SLOW'] != null;

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
  final (program, args) = switch (_browserName) {
    // Its log goes to ~/Library/Logs/com.apple.WebDriver (_safariLog).
    'safari' => ('safaridriver', ['--diagnose', '-p', '4444']),
    final name => () {
        final pinned = testBrowserNamed(name);
        if (!pinned.ready) fail('No $name ${pinned.version} in ${pinned.dir.path}: run `dart run tool/fetch_test_browser.dart $name`.');
        return (
          pinned.driver.path,
          name == 'firefox' ? ['--port', '4444', '--binary', pinned.browser.path] : ['--port=4444'],
        );
      }(),
  };
  final driver = await Process.start(program, args);
  // Kept for a failure's report: a driver that won't start says why.
  final said = StringBuffer();
  for (final stream in [driver.stdout, driver.stderr]) {
    stream.transform(const Utf8Decoder(allowMalformed: true)).listen(said.write);
  }
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (true) {
    // Either loopback: safaridriver listens on IPv6's.
    for (final loopback in [InternetAddress.loopbackIPv4, InternetAddress.loopbackIPv6]) {
      try {
        (await Socket.connect(loopback, 4444)).destroy();
        return driver;
      } on SocketException {
        // Not there yet, or not on this one.
      }
    }
    if (DateTime.now().isAfter(deadline)) {
      // Whether it ended, and where it listens if it lives: a driver that
      // says nothing still says that much.
      final ended = await driver.exitCode.timeout(Duration.zero, onTimeout: () => -1);
      final ports = Platform.isWindows
          ? ''
          : (await Process.run('lsof', ['-nP', '-a', '-p', '${driver.pid}', '-iTCP'])).stdout;
      fail('$program did not listen on port 4444; '
          '${ended == -1 ? 'it runs, with sockets: $ports' : 'it ended with $ended'}; it said: $said'
          '${_browserName == 'safari' ? '\nits log: ${_safariLog()}' : ''}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

/// The end of safaridriver's latest log (`--diagnose`): it says nothing on
/// its output.
String _safariLog() {
  final dir = Directory('${Platform.environment['HOME']}/Library/Logs/com.apple.WebDriver');
  if (!dir.existsSync()) return 'none, in ${dir.path}';
  final logs = dir.listSync().whereType<File>().toList()
    ..sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
  if (logs.isEmpty) return 'none, in ${dir.path}';
  final lines = logs.last.readAsLinesSync();
  return '${logs.last.path}:\n${lines.skip(lines.length > 40 ? lines.length - 40 : 0).join('\n')}';
}

/// Stops the node the app under test may have left running (a test that
/// failed midway never switched it off), then removes its folder.
Future<void> _stopOwnNode(Directory data) async {
  final pidFile = File('${data.path}${Platform.pathSeparator}app-node.pid');
  if (pidFile.existsSync()) {
    final pid = int.tryParse(pidFile.readAsStringSync().trim());
    if (pid != null) Process.killPid(pid, ProcessSignal.sigkill);
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  try {
    data.deleteSync(recursive: true);
  } on FileSystemException {
    // Still held for a moment by the node on its way out.
  }
}
/// Finds the app's WorkManager job (scheduled once notifications are on),
/// runs it as Android would, and says whether its Dart side ran.
Future<bool> _runBackgroundJob(AndroidSystem android) async {
  for (var i = 0; i < 30; i++) {
    final job = await android.backgroundJob();
    if (job != null) return android.runBackgroundJob(job, backgroundCheckLog);
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  print('android: no background job was scheduled');
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
    // A desktop app can run a node of its own: the pinned one, on the demo
    // network, in a folder thrown away with the run (never the user's).
    final desktop = _device == 'windows' || _device == 'linux' || _device == 'macos';
    final ownNodeData = desktop ? await Directory.systemTemp.createTemp('murmur-acceptance-node') : null;
    if (ownNodeData != null) addTearDown(() => _stopOwnNode(ownNodeData));
    final settings = [
      '--dart-define=ACCEPTANCE_NODE=$host:${webSocket ?? node.port}',
      '--dart-define=ACCEPTANCE_SEED=${toHex(wallet.seed)}',
      if (desktop) ...['--dart-define=ACCEPTANCE_OWN_NODE=true', '--dart-define=MURMUR_LOCAL_NODE_SPEC=demo'],
      if (passkey) '--dart-define=ACCEPTANCE_PASSKEY=true',
      // A machine without a desktop, which can't show notifications.
      if (_env['ACCEPTANCE_NO_NOTIFICATIONS'] != null) '--dart-define=ACCEPTANCE_NO_NOTIFICATIONS=true',
      // A device far slower than a desktop (an emulator without KVM).
      if (_slow) '--dart-define=ACCEPTANCE_SLOW=true',
    ];
    if (browser) {
      final driver = await _startWebDriver();
      addTearDown(driver.kill);
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
    final args = !browser
        ? ['test', _suite, '-d', _device, ...settings]
        : [
            'drive',
            '--driver=test_driver/integration_test.dart',
            '--target=$_suite',
            '-d', 'web-server',
            '--browser-name=$_browserName',
            if (_browserName == 'chrome') '--chrome-binary=${testBrowserNamed('chrome').browser.path}',
            // Safari has no headless mode.
            if (_env['ACCEPTANCE_HEADED'] == null && _browserName != 'safari') '--headless',
            ...settings,
          ];
    print('flutter ${args.where((a) => !a.contains('ACCEPTANCE_SEED')).join(' ')}');
    // Not with what `flutter test` sets for the tests it runs itself, this
    // one included: FONTCONFIG_FILE hides the system's fonts, and the app
    // then can't measure a line of monospace text.
    final environment = {
      for (final MapEntry(:key, :value) in _env.entries)
        if (key != 'FONTCONFIG_FILE' && key != 'FLUTTER_TEST') key: value,
      if (ownNodeData != null) ...{'MURMUR_NODE_BIN': nodeBinary!, 'MURMUR_NODE_DATA': ownNodeData.path},
      if (passkey) 'ACCEPTANCE_PASSKEY': '1',
    };
    final flutter = await Process.start(Platform.isWindows ? 'flutter.bat' : 'flutter', args,
        environment: environment, includeParentEnvironment: false, runInShell: Platform.isWindows);
    final said = <String>[];
    for (final stream in [flutter.stdout, flutter.stderr]) {
      stream.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter()).listen((line) {
        said.add(line);
        print(line);
        if (android == null) return;
        final click = line.indexOf(androidClickRequest);
        if (click >= 0) {
          final title = line.substring(click + androidClickRequest.length).trim();
          android.clickNotification(title).then((done) => print('android: clicked "$title": $done'));
        } else if (line.contains(androidBackgroundJobRequest)) {
          _runBackgroundJob(android).then((ran) {
            backgroundJobRan = ran;
            print('android: the background job ran: $ran');
          });
        }
      });
    }
    expect(await flutter.exitCode, 0, reason: 'the acceptance tests on $_device');
    // `flutter drive` can end with 0 after tests that failed.
    expect(said.where((line) => line.contains('Some tests failed') || line.contains('[E]')), isEmpty);
    if (android != null) expect(backgroundJobRan, isTrue, reason: "the app's background job, run as Android runs it");
  }, skip: nodeSkip, timeout: Timeout(Duration(minutes: _slow ? 150 : 30)));
}
