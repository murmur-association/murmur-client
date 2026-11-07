// What the tools that run on the host share: the acceptance runner
// (tool/acceptance_test.dart) and what it drives from outside the app
// (tool/android_system.dart), the desktop smoke test, and the tests against
// the node (test/support/test_node.dart). Plain Dart, no flutter_test: the
// smoke test runs under `dart run`, so each caller fails its own way.
//
// Not for tests inside the app (integration_test/): those move time on by
// drawing frames (AppDriver.waitUntil), and run in browsers too.

// ignore_for_file: avoid_print

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

/// What a device run printed, kept and passed on, for the two runners that
/// start one (tool/acceptance_test.dart, tool/phone_storage_test.dart). A
/// job's log needs a GitHub login to read; its annotations don't, so the
/// device's own failure annotations are passed on where GitHub reads them,
/// and a run that fails anywhere else ([failed]) leaves its last lines as
/// one.
class DeviceOutput {
  /// Every line, oldest first.
  final said = <String>[];

  /// Keeps and prints `line`. A failure's annotation the app printed comes
  /// after a prefix on some devices (Android's "I/flutter (…): "), and
  /// GitHub reads a workflow command only at the start of a line, so it's
  /// printed again from there.
  void add(String line) {
    said.add(line);
    print(line);
    final command = line.indexOf('::error ');
    if (command > 0) print(line.substring(command));
  }

  /// Whether the run, ended with `exitCode`, failed: `flutter drive` can
  /// end with 0 after tests that failed. If so, its last lines become an
  /// annotation titled `what`.
  bool failed(int exitCode, String what) {
    final failed = exitCode != 0 || said.any((line) => line.contains('Some tests failed') || line.contains('[E]'));
    if (failed && Platform.environment['GITHUB_ACTIONS'] == 'true') {
      final tail = said.skip(said.length > 60 ? said.length - 60 : 0).join('\n');
      String escaped(String s) => s.replaceAll('%', '%25').replaceAll('\r', '%0D').replaceAll('\n', '%0A');
      print('::error title=${escaped(what).replaceAll(':', '%3A').replaceAll(',', '%2C')}'
          '::${escaped('exit code $exitCode; last lines:\n$tail')}');
    }
    return failed;
  }
}
