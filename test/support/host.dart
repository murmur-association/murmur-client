// What the tools that run on the host share: the acceptance runner
// (tool/acceptance_test.dart) and what it drives from outside the app
// (tool/android_system.dart), the desktop smoke test, and the tests against
// the node (test/support/test_node.dart). Plain Dart, no flutter_test: the
// smoke test runs under `dart run`, so each caller fails its own way.
//
// Not for tests inside the app (integration_test/): those move time on by
// drawing frames (AppDriver.waitUntil), and run in browsers too.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Checks `done` every `every` until it holds, or `timeout` has passed;
/// whether it held. `done` may also act (tap a screen, say), and is always
/// asked once, however short `timeout`.
Future<bool> poll(FutureOr<bool> Function() done,
    {required Duration timeout, Duration every = const Duration(milliseconds: 500)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await done()) {
    if (DateTime.now().isAfter(deadline)) return false;
    await Future<void>.delayed(every);
  }
  return true;
}

/// Hands each line `process` writes, to its output or its errors, to
/// `line`, as it comes; bytes that aren't UTF-8 don't stop it.
void eachLine(Process process, void Function(String line) line) {
  for (final stream in [process.stdout, process.stderr]) {
    stream.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter()).listen(line);
  }
}
