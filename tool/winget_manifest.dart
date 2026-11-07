// Writes the winget manifests for a release's Windows installer
// (tool/release/winget.dart), for the release job:
//
//   dart run tool/winget_manifest.dart --tag v0.10.4 --installer dist/murmur-client-v0.10.4-windows-x64-setup.exe
//
// into build/winget/manifests/m/MurmurAssociation/Murmur/0.10.4/. A pull
// request to github.com/microsoft/winget-pkgs adding that folder publishes
// the version to winget (README, "Desktop updates").

import 'dart:io';

import 'package:crypto/crypto.dart';

import 'release/winget.dart';

Future<void> main(List<String> args) async {
  String? tag, installer;
  var out = 'build/winget';
  for (var i = 0; i + 1 < args.length; i += 2) {
    switch (args[i]) {
      case '--tag':
        tag = args[i + 1];
      case '--installer':
        installer = args[i + 1];
      case '--out':
        out = args[i + 1];
      default:
        _fail('unknown option ${args[i]}');
    }
  }
  if (tag == null || installer == null || args.length.isOdd) {
    _fail('usage: dart run tool/winget_manifest.dart --tag vX.Y.Z --installer <setup.exe> [--out build/winget]');
  }
  final file = File(installer);
  if (!file.existsSync()) _fail('no installer at $installer');
  final sha = sha256.convert(await file.readAsBytes()).toString();
  final version = tag.startsWith('v') ? tag.substring(1) : tag;
  final dir = Directory('$out/${wingetFolder(version)}');
  await dir.create(recursive: true);
  final manifests = wingetManifests(
    version: version,
    installerName: file.uri.pathSegments.last,
    sha256: sha,
    date: DateTime.now().toUtc(),
  );
  for (final MapEntry(key: name, value: text) in manifests.entries) {
    await File('${dir.path}/$name').writeAsString(text);
    stdout.writeln('wrote ${dir.path}/$name');
  }
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(2);
}
