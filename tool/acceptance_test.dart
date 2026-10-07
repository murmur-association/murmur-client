// Runs the acceptance tests (integration_test/acceptance_test.dart) on one
// flavour of the app, against a node of their own: a demo chain built for
// the run, served and mined on by the pinned murmur-node release
// (test/support/test_node.dart), paying a wallet made for the run.
//
//   flutter test tool/acceptance_test.dart                             # this desktop: Windows or Linux
//   ACCEPTANCE_DEVICE=chrome flutter test tool/acceptance_test.dart    # a browser, with a passphrase
//   ACCEPTANCE_DEVICE=chrome-passkey flutter test tool/acceptance_test.dart   # a browser, with a passkey
//   ACCEPTANCE_DEVICE=emulator-5554 flutter test tool/acceptance_test.dart   # an Android emulator
//
// A browser run uses the pinned "Chrome for Testing" and its chromedriver
// (`dart run tool/fetch_test_browser.dart` downloads them): the driver is
// started here, on port 4444, and stopped afterwards. ACCEPTANCE_HEADED
// shows the browser. Only Chrome: `flutter drive` asks Edge's driver for a
// browser it doesn't know by that name.
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

import '../test/support/test_node.dart';
import 'fetch_test_browser.dart';

final _env = Platform.environment;
final _device = _env['ACCEPTANCE_DEVICE'] ?? Platform.operatingSystem;
const _browsers = {'chrome', 'chrome-passkey'};
const _suite = 'integration_test/acceptance_test.dart';

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
  if (!testBrowserReady) {
    fail('No Chrome for Testing $testBrowserVersion in $testBrowserDir: run `dart run tool/fetch_test_browser.dart`.');
  }
  const program = 'chromedriver';
  final driver = await Process.start(testBrowserDriver.path, ['--port=4444']);
  unawaited(driver.stdout.drain<void>());
  unawaited(driver.stderr.drain<void>());
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (true) {
    try {
      (await Socket.connect(InternetAddress.loopbackIPv4, 4444)).destroy();
      return driver;
    } on SocketException {
      if (DateTime.now().isAfter(deadline)) fail('$program did not listen on port 4444');
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }
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
    final desktop = _device == 'windows' || _device == 'linux';
    final ownNodeData = desktop ? await Directory.systemTemp.createTemp('murmur-acceptance-node') : null;
    if (ownNodeData != null) addTearDown(() => _stopOwnNode(ownNodeData));
    final settings = [
      '--dart-define=ACCEPTANCE_NODE=$host:${webSocket ?? node.port}',
      '--dart-define=ACCEPTANCE_SEED=${toHex(wallet.seed)}',
      if (desktop) ...['--dart-define=ACCEPTANCE_OWN_NODE=true', '--dart-define=MURMUR_LOCAL_NODE_SPEC=demo'],
      if (passkey) '--dart-define=ACCEPTANCE_PASSKEY=true',
    ];
    if (browser) {
      final driver = await _startWebDriver();
      addTearDown(driver.kill);
    }
    final args = !browser
        ? ['test', _suite, '-d', _device, ...settings]
        : [
            'drive',
            '--driver=test_driver/integration_test.dart',
            '--target=$_suite',
            '-d', 'web-server',
            '--browser-name=chrome',
            '--chrome-binary=${testBrowser.path}',
            if (_env['ACCEPTANCE_HEADED'] == null) '--headless',
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
      });
    }
    expect(await flutter.exitCode, 0, reason: 'the acceptance tests on $_device');
    // `flutter drive` can end with 0 after tests that failed.
    expect(said.where((line) => line.contains('Some tests failed') || line.contains('[E]')), isEmpty);
  }, skip: nodeSkip, timeout: const Timeout(Duration(minutes: 30)));
}
