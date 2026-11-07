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
/// one: the device's and, from what [capture] ran, the runner's own.
class DeviceOutput {
  /// The device's lines and the runner's, oldest first.
  final _said = <String>[];

  /// The device's lines alone.
  final _device = <String>[];

  /// Keeps and prints a line of the device's. A failure's annotation the
  /// app printed comes after a prefix on some devices (Android's
  /// "I/flutter (…): "), and GitHub reads a workflow command only at the
  /// start of a line, so it's printed again from there.
  void add(String line) {
    _said.add(line);
    _device.add(line);
    Zone.root.print(line);
    final command = line.indexOf('::error ');
    if (command > 0) Zone.root.print(line.substring(command));
  }

  /// Runs `body`, keeping what it prints, and what the work it starts
  /// prints later (the runner answering the app's requests), beside the
  /// device's lines.
  void capture(void Function() body) =>
      runZoned(body, zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) {
        _said.add(line);
        parent.print(zone, line);
      }));

  /// Whether the run, ended with `exitCode`, failed: `flutter drive` can
  /// end with 0 after tests that failed. If so, an annotation titled `what`
  /// holds every failure the app reported (its own annotations, which
  /// GitHub didn't always take from an iPhone's output), then the last
  /// lines, then `node`'s, the test node's last lines if given.
  bool failed(int exitCode, String what, {List<String> node = const []}) {
    final failed = exitCode != 0 || _device.any((line) => line.contains('Some tests failed') || line.contains('[E]'));
    if (failed && Platform.environment['GITHUB_ACTIONS'] == 'true') {
      final reported = [
        for (final line in _device)
          if (line.indexOf('::error ') case final at when at >= 0)
            line
                .substring(line.indexOf('::', at + 8) + 2)
                .replaceAll('%0A', '\n')
                .replaceAll('%0D', '')
                .replaceAll('%25', '%'),
      ];
      final tail = _said.skip(_said.length > 40 ? _said.length - 40 : 0).join('\n');
      String escaped(String s) => s.replaceAll('%', '%25').replaceAll('\r', '%0D').replaceAll('\n', '%0A');
      print('::error title=${escaped(what).replaceAll(':', '%3A').replaceAll(',', '%2C')}'
          '::${escaped('exit code $exitCode\n${reported.map((r) => 'failed: $r\n').join()}last lines:\n$tail'
              '${node.isEmpty ? '' : "\nthe node's last lines:\n${node.join('\n')}"}')}');
    }
    return failed;
  }
}
