// Where a phone keeps what the app stores (AGENTS.md, gap 7), checked on the
// device with the real path_provider, not with folder names handed to
// chainCacheBase as the unit tests do (test/chain_cache_test.dart):
// - the local copy of the chain goes under the app's cache folder, which
//   device backups leave out and the system may clear;
// - the user's own messages go under its support folder, which is kept;
// - a copy an earlier version left in the temp folder is moved along;
// - after the system clears the caches (on Android the runner has it do so
//   for real, `pm trim-caches`; iOS has no such command, so there the test
//   empties the folder in its place), the own messages are still there, and
//   the next session downloads the copy again into the same folder.
//
// Run on an Android emulator or an iPhone simulator by its runner, which
// gives it a node of its own and answers its request to clear the caches:
//
//   ACCEPTANCE_DEVICE=emulator-5554 flutter test tool/phone_storage_test.dart
//
// It deletes and writes only the app's own murmur-client folders, so it
// belongs on a test device: the runners' emulators and simulators are made
// for the run.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:murmur_client/protocol/wire.dart' show headerBytes;
import 'package:murmur_client/services/chain_cache.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/own_messages.dart';
import 'package:path_provider/path_provider.dart';

import 'support/acceptance_protocol.dart';

/// The runner's node, `host:port`, and the height of the chain it serves.
const _node = String.fromEnvironment('ACCEPTANCE_NODE');
const _height = int.fromEnvironment('ACCEPTANCE_HEIGHT');

final _sep = Platform.pathSeparator;

/// Waits for `done`, checking every half second, failing after `timeout`
/// with `what` was awaited.
Future<void> _until(bool Function() done, String what, {Duration timeout = const Duration(minutes: 2)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) fail('timed out waiting for $what');
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}

/// A session with the local copy in `cache`, synced to the runner's chain
/// and disconnected once the copy holds every header.
Future<void> _session(ChainCache cache, File headers) async {
  final client = MurmurClient()..useCache(cache);
  final colon = _node.lastIndexOf(':');
  try {
    await client.connect(_node.substring(0, colon), int.parse(_node.substring(colon + 1)));
    await _until(() => client.state == LinkState.live && client.height >= _height, 'the client to sync to $_height');
    await _until(() => headers.existsSync() && headers.lengthSync() >= _height * headerBytes,
        'the local copy to hold $_height headers');
  } finally {
    client.dispose();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the local copy is under the cache folder, own messages under the support folder', (tester) async {
    if (_node.isEmpty || _height == 0) fail('run through tool/phone_storage_test.dart, which gives ACCEPTANCE_NODE');
    final android = defaultTargetPlatform == TargetPlatform.android;
    if (!android && defaultTargetPlatform != TargetPlatform.iOS) fail('this checks a phone\'s folders');

    final cacheDir = (await getApplicationCacheDirectory()).path;
    final supportDir = (await getApplicationSupportDirectory()).path;
    final tempDir = Directory.systemTemp.path;
    debugPrint('cache folder: $cacheDir\nsupport folder: $supportDir\ntemp folder: $tempDir');
    // The folders the systems leave out of backups and may clear, and the
    // ones they keep: what path_provider names must be those.
    if (android) {
      expect(cacheDir, endsWith('${_sep}cache'), reason: "Android's cache folder (Context.getCacheDir)");
      expect(supportDir, endsWith('${_sep}files'), reason: "Android's files folder (Context.getFilesDir)");
    } else {
      expect(cacheDir, contains('${_sep}Library${_sep}Caches'), reason: "iOS's Caches folder, which backups leave out");
      expect(supportDir, contains('${_sep}Library${_sep}Application Support'), reason: "iOS's Application Support folder");
    }

    final chain = Directory('$cacheDir${_sep}murmur-client${_sep}chain');
    final headers = File('${chain.path}${_sep}headers.bin');
    final oldCopy = Directory('$tempDir${_sep}murmur-client${_sep}chain');
    final own = File('$supportDir${_sep}murmur-client${_sep}own${_sep}messages.log');
    // A clean start: an app reinstalled for the test may keep its data.
    for (final dir in {
      Directory('$cacheDir${_sep}murmur-client'),
      Directory('$supportDir${_sep}murmur-client'),
      Directory('$tempDir${_sep}murmur-client'),
    }) {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    }
    // Where the runner leaves its word (as runner_signal_io.dart reads it).
    final cleared = File('$supportDir$_sep$phoneCachesCleared');
    if (cleared.existsSync()) cleared.deleteSync();

    // An earlier version's copy in the temp folder, moved along on opening.
    // (On Android the temp folder is the cache folder itself: nothing moves.)
    final moves = oldCopy.path != chain.path;
    oldCopy.createSync(recursive: true);
    File('${oldCopy.path}${_sep}planted').writeAsStringSync('an earlier copy');
    final cache = await ChainCache.open();
    expect(cache, isNotNull, reason: 'the local copy opens');
    expect(File('${chain.path}${_sep}planted').existsSync(), isTrue, reason: 'the earlier copy, in the cache folder');
    if (moves) expect(oldCopy.existsSync(), isFalse, reason: 'the earlier copy left the temp folder');
    debugPrint(moves ? 'the earlier copy moved from the temp folder' : 'the temp folder is the cache folder here');

    // A session stores the chain there, and nowhere that's kept.
    await _session(cache!, headers);
    debugPrint('the local copy: ${headers.path}, ${headers.lengthSync()} bytes');
    expect(Directory('$supportDir${_sep}murmur-client${_sep}chain').existsSync(), isFalse,
        reason: 'no copy of the chain in the support folder, which backups include');

    // The user's own messages, kept for good.
    final store = await OwnMessageStore.open();
    expect(store, isNotNull);
    final kept = OwnMessage(
        txid: 'ab' * 32, author: 'cd' * 32, content: Uint8List.fromList(List.generate(40, (i) => i)), keptAt: 1);
    await store!.add([kept]);
    expect(own.existsSync(), isTrue, reason: 'own messages in ${own.path}');
    expect(Directory('$cacheDir${_sep}murmur-client${_sep}own').existsSync(), isFalse,
        reason: 'no own messages in the cache folder, which the system may clear');

    // The system clears the caches, as when storage runs short.
    if (android) {
      debugPrint(phoneClearCachesRequest);
      await _until(() => cleared.existsSync(), 'the runner to have the system clear the caches',
          timeout: const Duration(minutes: 3));
      expect(headers.existsSync(), isFalse, reason: 'Android cleared the local copy with the other caches');
    } else {
      debugPrint('iOS has no command to clear caches: the test empties the folder in its place');
      Directory('$cacheDir${_sep}murmur-client').deleteSync(recursive: true);
    }
    final after = await (await OwnMessageStore.open())!.load();
    expect(after.map((m) => m.txid), [kept.txid], reason: 'own messages outlast the caches');

    // The next session downloads the copy again, into the same folder.
    await _session((await ChainCache.open())!, headers);
    debugPrint('downloaded again: ${headers.lengthSync()} bytes');

    for (final dir in [Directory('$cacheDir${_sep}murmur-client'), Directory('$supportDir${_sep}murmur-client')]) {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 15)));
}
