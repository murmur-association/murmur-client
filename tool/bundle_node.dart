// Puts the murmur-node program next to a built desktop app, so the app can
// run a node of its own (lib/services/local_node.dart). Run after
// `flutter build windows|linux|macos`:
//
//   dart run tool/bundle_node.dart --version v0.9.0      # a published release
//   dart run tool/bundle_node.dart --from <murmur-node>  # a binary at hand
//   ... [--into <dir>]                                   # another build folder
//
// A release is downloaded from the node project's package registry and
// checked against its SHA256SUMS before anything is copied; its license
// notices go next to the binary too. This is a build step: the app itself
// never downloads anything.

import 'dart:io';

import 'package:crypto/crypto.dart';

const _releases = 'https://gitlab.com/api/v4/projects/elc4no%2Fmurmur/packages/generic/murmur-node';

Future<void> main(List<String> args) async {
  String? version, from, into;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--version':
        version = args[++i];
      case '--from':
        from = args[++i];
      case '--into':
        into = args[++i];
      default:
        _usage('unknown option ${args[i]}');
    }
  }
  if ((version == null) == (from == null)) _usage('give either --version or --from');
  final target = Directory(into ?? _buildDir());
  if (!await target.exists()) _usage('no build at ${target.path}: run flutter build first, or give --into');
  final name = Platform.isWindows ? 'murmur-node.exe' : 'murmur-node';

  if (from != null) {
    await File(from).copy('${target.path}/$name');
  } else {
    final triple = _triple();
    final archive = 'murmur-node-$version-$triple.${Platform.isWindows ? 'zip' : 'tar.gz'}';
    final tmp = await Directory.systemTemp.createTemp('murmur-node-bundle');
    try {
      final file = File('${tmp.path}/$archive');
      await file.writeAsBytes(await _get('$_releases/$version/$archive'));
      final sums = String.fromCharCodes(await _get('$_releases/$version/SHA256SUMS'));
      final expected = RegExp('^([0-9a-f]{64})  ${RegExp.escape(archive)}\$', multiLine: true).firstMatch(sums)?.group(1);
      final actual = sha256.convert(await file.readAsBytes()).toString();
      if (expected == null || expected != actual) {
        stderr.writeln('$archive does not match SHA256SUMS: refusing it');
        exit(1);
      }
      // tar reads both .tar.gz and, on Windows 10 and later, .zip.
      final r = await Process.run('tar', ['-xf', file.path, '-C', tmp.path]);
      if (r.exitCode != 0) {
        stderr.writeln('could not unpack $archive: ${r.stderr}');
        exit(1);
      }
      for (final f in [name, 'LICENSE', 'NOTICE', 'THIRD-PARTY-NOTICES.txt']) {
        final dest = f == name ? name : 'murmur-node-$f';
        await File('${tmp.path}/$f').copy('${target.path}/$dest');
      }
    } finally {
      await tmp.delete(recursive: true);
    }
  }
  if (!Platform.isWindows) await Process.run('chmod', ['755', '${target.path}/$name']);
  stdout.writeln('murmur-node is in ${target.path}');
}

/// Where `flutter build` puts this platform's release app.
String _buildDir() {
  if (Platform.isWindows) return 'build/windows/x64/runner/Release';
  if (Platform.isLinux) return 'build/linux/${_arch() == 'arm64' ? 'arm64' : 'x64'}/release/bundle';
  if (Platform.isMacOS) return 'build/macos/Build/Products/Release/murmur_client.app/Contents/MacOS';
  _usage('not a desktop platform');
}

String _arch() {
  final v = Platform.version.toLowerCase();
  return v.contains('arm64') || v.contains('aarch64') ? 'arm64' : 'x64';
}

/// The release's name for this machine.
String _triple() {
  if (Platform.isWindows) return 'x86_64-pc-windows-msvc';
  if (Platform.isLinux) return _arch() == 'arm64' ? 'aarch64-unknown-linux-musl' : 'x86_64-unknown-linux-musl';
  _usage('no published macOS build yet: build murmur-node yourself and use --from');
}

Future<List<int>> _get(String url) async {
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(Uri.parse(url))).close();
    if (response.statusCode != 200) {
      stderr.writeln('$url: HTTP ${response.statusCode}');
      exit(1);
    }
    return [for (final chunk in await response.toList()) ...chunk];
  } finally {
    client.close();
  }
}

Never _usage(String problem) {
  stderr.writeln('$problem\n'
      'usage: dart run tool/bundle_node.dart (--version <tag> | --from <murmur-node>) [--into <build dir>]');
  exit(2);
}
