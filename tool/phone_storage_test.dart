// Runs the phone storage test (integration_test/phone_storage_test.dart) on
// an Android emulator or an iPhone simulator, against a node of its own: a
// small demo chain built for the run and served by the pinned murmur-node
// release (test/support/test_node.dart). On Android it answers the app's
// request to clear the caches through adb (tool/android_system.dart), so the
// system itself clears them.
//
//   ACCEPTANCE_DEVICE=emulator-5554 flutter test tool/phone_storage_test.dart
//   ACCEPTANCE_DEVICE=$(tool/ios_simulator.sh) flutter test tool/phone_storage_test.dart
//
// The regression runs it in the acceptance jobs for Android and iOS, on the
// emulator or simulator the acceptance tests ran on.

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';

import '../integration_test/support/acceptance_protocol.dart';
import '../test/support/host.dart';
import '../test/support/test_node.dart';
import 'android_system.dart';

const _suite = 'integration_test/phone_storage_test.dart';
const _blocks = 40;

void main() {
  final device = Platform.environment['ACCEPTANCE_DEVICE'];
  test('where a phone keeps the local copy and the own messages, on $device', () async {
    if (device == null) fail('set ACCEPTANCE_DEVICE to an Android emulator or an iPhone simulator');
    final wallet = await MurmurWallet.generate();
    final node = await TestNode.build(_blocks, mineTo: wallet.address);
    await node.start();
    // An Android emulator reaches this machine as 10.0.2.2.
    final emulator = device.startsWith('emulator-');
    final host = emulator ? '10.0.2.2' : '127.0.0.1';
    final android = emulator ? AndroidSystem(device, androidApplicationId()!) : null;
    final args = [
      'test',
      _suite,
      '-d',
      device,
      '--dart-define=ACCEPTANCE_NODE=$host:${node.port}',
      '--dart-define=ACCEPTANCE_HEIGHT=$_blocks',
    ];
    print('flutter ${args.join(' ')}');
    // As in tool/acceptance_test.dart: not with FONTCONFIG_FILE, nor with
    // GITHUB_ACTIONS, under which `flutter test` holds the app's output
    // (and so its request to this runner) until the test ends.
    final environment = {
      for (final MapEntry(:key, :value) in Platform.environment.entries)
        if (key != 'FONTCONFIG_FILE' && key != 'FLUTTER_TEST' && key != 'GITHUB_ACTIONS') key: value,
    };
    final flutter = await Process.start(Platform.isWindows ? 'flutter.bat' : 'flutter', args,
        environment: environment, includeParentEnvironment: false, runInShell: Platform.isWindows);
    final output = DeviceOutput();
    var cleared = false;
    output.capture(() => eachLine(flutter, (line) {
          output.add(line);
          if (android != null && line.contains(phoneClearCachesRequest)) {
            android.clearCaches().then((done) async {
              print('android: $done');
              cleared = true;
              await android.tellApp(phoneCachesCleared);
            });
          }
        }));
    expect(output.failed(await flutter.exitCode, 'the phone storage test on $device'), isFalse,
        reason: 'the phone storage test on $device');
    if (android != null) expect(cleared, isTrue, reason: 'the system cleared the caches when the app asked');
  }, skip: nodeSkip, timeout: const Timeout(Duration(minutes: 30)));
}
