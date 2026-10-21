// Downloads a browser the acceptance tests run in (tool/acceptance_test.dart
// with ACCEPTANCE_DEVICE=chrome, chrome-passkey or firefox) and its WebDriver,
// into build/test-browser/<browser>: "Chrome for Testing" with the
// chromedriver of the same version, or Firefox with geckodriver. Each is
// pinned by version and SHA-256, so every run, here and in CI, drives the
// same browser. Safari needs nothing fetched: it and safaridriver come with
// macOS.
//
//   dart run tool/fetch_test_browser.dart [chrome|firefox]     # chrome by default
//
// For tests only: nothing of it is released (AGENTS.md rule 2 is about what's
// released).

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:crypto/crypto.dart';

final _windows = Platform.isWindows;
final _exe = _windows ? '.exe' : '';

/// One download: where from, its pinned SHA-256, and what unpacks it.
typedef _Archive = ({String url, String sha256, List<String> unpack});

/// A pinned browser and its WebDriver, for this system.
class TestBrowser {
  const TestBrowser._(this.name, this.version, this._browser, this._driver, this._archives);

  final String name, version;
  final String _browser, _driver;
  final List<_Archive> _archives;

  Directory get dir => Directory('build/test-browser/$name');
  File get browser => File('${dir.path}/$_browser').absolute;
  File get driver => File('${dir.path}/$_driver').absolute;
  File get _fetched => File('${dir.path}/version');

  /// Whether the pinned version is there.
  bool get ready =>
      browser.existsSync() &&
      driver.existsSync() &&
      _fetched.existsSync() &&
      _fetched.readAsStringSync().trim() == version;

  /// Downloads, checks and unpacks it, unless it's there.
  Future<void> fetch() async {
    if (ready) return;
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final http = HttpClient();
    try {
      for (final (i, archive) in _archives.indexed) {
        final response = await (await http.getUrl(Uri.parse(archive.url))).close();
        if (response.statusCode != 200) throw StateError('${archive.url}: HTTP ${response.statusCode}');
        final file = File('${dir.path}/download-$i');
        await response.pipe(file.openWrite());
        final actual = sha256.convert(await file.readAsBytes()).toString();
        if (actual != archive.sha256) {
          throw StateError('${archive.url} has SHA-256 $actual, not the pinned ${archive.sha256}: not unpacked');
        }
        final unpack = await Process.run(archive.unpack.first, [...archive.unpack.skip(1), file.path.split('/').last],
            workingDirectory: dir.path);
        if (unpack.exitCode != 0) throw StateError('could not unpack ${archive.url}: ${unpack.stderr}');
        file.deleteSync();
      }
    } finally {
      http.close();
    }
    _fetched.writeAsStringSync(version);
  }
}

// Windows' own tar reads zip files; elsewhere unzip does.
final _unzip = _windows ? ['tar', '-xf'] : ['unzip', '-oq'];

/// Chrome for Testing and its chromedriver.
TestBrowser get _chrome {
  const version = '155.0.8059.39';
  final platform = _windows ? 'win64' : 'linux64';
  final hashes = {
    'win64': (
      chrome: '59ab2a6e99bde9c0bc180414988394f9f5355a0d3764c704151ee8ecea235c7e',
      chromedriver: '2c08ba237981b72b824ac8063927f545c4cdf7f59b49f5eaeaa3a5d4e1a20eaf',
    ),
    'linux64': (
      chrome: '55672d1f392fd3e7b7a08621b6e804e6bcb39d40cf155504abb74b3a021ea8ea',
      chromedriver: 'a65f025c692e686ec2a21fa6b9639c69fa9813683a47af9cabf1ba0b1f453e42',
    ),
  }[platform]!;
  String url(String name) =>
      'https://storage.googleapis.com/chrome-for-testing-public/$version/$platform/$name-$platform.zip';
  return TestBrowser._('chrome', version, 'chrome-$platform/chrome$_exe', 'chromedriver-$platform/chromedriver$_exe', [
    (url: url('chrome'), sha256: hashes.chrome, unpack: _unzip),
    (url: url('chromedriver'), sha256: hashes.chromedriver, unpack: _unzip),
  ]);
}

/// Firefox and geckodriver, on Linux (where CI runs them).
TestBrowser get _firefox {
  const version = '158.0.1', geckodriver = '0.37.1';
  if (Platform.isWindows || Platform.isMacOS) throw UnsupportedError('Firefox for the tests is pinned for Linux only');
  return const TestBrowser._('firefox', '$version+$geckodriver', 'firefox/firefox', 'geckodriver', [
    (
      url: 'https://ftp.mozilla.org/pub/firefox/releases/$version/linux-x86_64/en-US/firefox-$version.tar.xz',
      sha256: 'dce45470139242cf294eb6ada3d192a9bb334696842b02b71ade448a139eb41a',
      unpack: ['tar', '-xJf'],
    ),
    (
      url: 'https://github.com/mozilla/geckodriver/releases/download/v$geckodriver/geckodriver-v$geckodriver-linux64.tar.gz',
      sha256: 'e815130ea95983e162ae91843b48d3a3ce991735635fce83a647afde21e09f7e',
      unpack: ['tar', '-xzf'],
    ),
  ]);
}

/// The browser named `name` (chrome or firefox).
TestBrowser testBrowserNamed(String name) => switch (name) {
      'chrome' => _chrome,
      'firefox' => _firefox,
      _ => throw ArgumentError('no pinned browser "$name"'),
    };

Future<void> main(List<String> args) async {
  final browser = testBrowserNamed(args.isEmpty ? 'chrome' : args.single);
  await browser.fetch();
  print('${browser.name} ${browser.version} is in ${browser.dir.path}');
}
