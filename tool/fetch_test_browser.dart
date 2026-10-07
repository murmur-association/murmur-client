// Downloads the browser the acceptance tests run in (tool/acceptance_test.dart
// with ACCEPTANCE_DEVICE=chrome): "Chrome for Testing" and the chromedriver
// of the same version, into build/test-browser. Both are pinned by version
// and SHA-256, so every run, here and in CI, drives the same browser.
//
//   dart run tool/fetch_test_browser.dart
//
// For tests only: nothing of it is released (AGENTS.md rule 2 is about what's
// released).

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:crypto/crypto.dart';

/// The pinned version; raise it together with the hashes below.
const testBrowserVersion = '155.0.8059.39';

const _hashes = {
  'win64': (
    chrome: '59ab2a6e99bde9c0bc180414988394f9f5355a0d3764c704151ee8ecea235c7e',
    chromedriver: '2c08ba237981b72b824ac8063927f545c4cdf7f59b49f5eaeaa3a5d4e1a20eaf',
  ),
  'linux64': (
    chrome: '55672d1f392fd3e7b7a08621b6e804e6bcb39d40cf155504abb74b3a021ea8ea',
    chromedriver: 'a65f025c692e686ec2a21fa6b9639c69fa9813683a47af9cabf1ba0b1f453e42',
  ),
};

final _platform = Platform.isWindows ? 'win64' : 'linux64';
final _exe = Platform.isWindows ? '.exe' : '';

/// Where the browser and its driver are once fetched.
const testBrowserDir = 'build/test-browser';
final testBrowser = File('$testBrowserDir/chrome-$_platform/chrome$_exe').absolute;
final testBrowserDriver = File('$testBrowserDir/chromedriver-$_platform/chromedriver$_exe').absolute;
final _fetched = File('$testBrowserDir/version');

/// Whether the pinned version is there.
bool get testBrowserReady =>
    testBrowser.existsSync() &&
    testBrowserDriver.existsSync() &&
    _fetched.existsSync() &&
    _fetched.readAsStringSync().trim() == testBrowserVersion;

Future<void> main() async {
  if (testBrowserReady) {
    print('Chrome for Testing $testBrowserVersion is in $testBrowserDir');
    return;
  }
  final hashes = _hashes[_platform]!;
  final dir = Directory(testBrowserDir);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);
  final http = HttpClient();
  try {
    for (final (name, hash) in [('chrome', hashes.chrome), ('chromedriver', hashes.chromedriver)]) {
      final url = 'https://storage.googleapis.com/chrome-for-testing-public/$testBrowserVersion/$_platform/$name-$_platform.zip';
      final response = await (await http.getUrl(Uri.parse(url))).close();
      if (response.statusCode != 200) {
        stderr.writeln('$url: HTTP ${response.statusCode}');
        exit(1);
      }
      final zip = File('${dir.path}/$name.zip');
      await response.pipe(zip.openWrite());
      final actual = sha256.convert(await zip.readAsBytes()).toString();
      if (actual != hash) {
        stderr.writeln('$name-$_platform.zip has SHA-256 $actual, not the pinned $hash: not unpacked.');
        exit(1);
      }
      // Windows' own tar reads zip files; elsewhere unzip does.
      final unpack = Platform.isWindows
          ? await Process.run('tar', ['-xf', '$name.zip'], workingDirectory: dir.path)
          : await Process.run('unzip', ['-oq', '$name.zip'], workingDirectory: dir.path);
      if (unpack.exitCode != 0) {
        stderr.writeln('could not unpack $name.zip: ${unpack.stderr}');
        exit(1);
      }
      zip.deleteSync();
    }
  } finally {
    http.close();
  }
  _fetched.writeAsStringSync(testBrowserVersion);
  print('Chrome for Testing $testBrowserVersion is in $testBrowserDir');
}
