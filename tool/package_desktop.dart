// Packages the built desktop app as an archive anyone can unpack and run,
// for the release (.github/workflows/release.yml: build-windows, build-linux). Run on
// the platform that built it, after `flutter build windows|linux|macos --release`
// and `dart run tool/bundle_node.dart`:
//
//   dart run tool/package_desktop.dart [--tag v0.2.1] [--store]
//
// Writes dist/murmur-client-<tag>-windows-x64.zip,
// dist/murmur-client-<tag>-linux-<x64|arm64>.tar.gz, or
// dist/murmur-client-<tag>-macos-universal.zip, holding one folder:
// the app (murmur_client and what it needs), its own node beside it, and
// LICENSE and NOTICE. The Windows one also holds the Visual C++ runtime the
// app is linked against (a Windows without Visual Studio may not have it).
// The tag defaults to `v` + the version in pubspec.yaml.
//
// With --store (Windows only, after a build with MURMUR_STORE): the same
// folder without murmur-miner, since a Microsoft Store build never mines,
// as build/desktop-package/murmur-client-<tag>-windows-x64-store, and no
// archive: tool/msix_package.ps1 packs it.
//
// The Mac one holds murmur_client.app, with the node and its miner inside
// (Contents/MacOS, where the app looks for them) and the node's notices in
// Contents/Resources, since codesign takes everything in Contents/MacOS for
// code. Adding them breaks the seal the build put on the app, so the app is
// signed again, ad hoc only: there's no Apple developer account yet, so no
// Developer ID and no notarization, and Gatekeeper stops a downloaded copy.
// The regression packages it only to smoke-test it (desktop_smoke_test.dart);
// no release publishes it.

import 'dart:io';

final _sep = Platform.pathSeparator;

/// The runtime libraries a Flutter Windows app needs next to it.
const _windowsRuntime = ['msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll'];

Future<void> main(List<String> args) async {
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) _fail('this packages the desktop builds');
  String? tag;
  var store = false;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--tag' && i + 1 < args.length) {
      tag = args[++i];
    } else if (args[i] == '--store') {
      store = true;
    } else {
      _fail('unknown option ${args[i]}\nusage: dart run tool/package_desktop.dart [--tag <tag>] [--store]');
    }
  }
  tag ??= 'v${RegExp(r'^version:\s*([0-9.]+)', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync())![1]}';
  if (store && !Platform.isWindows) _fail('--store packages the Windows app for the Microsoft Store');

  final arch = _arch();
  final built = Directory(Platform.isWindows
      ? 'build${_sep}windows${_sep}x64${_sep}runner${_sep}Release'
      : Platform.isMacOS
          ? 'build/macos/Build/Products/Release/$_macApp'
          : 'build${_sep}linux$_sep$arch${_sep}release${_sep}bundle');
  final needed = Platform.isWindows
      ? ['murmur_client.exe', 'murmur-node.exe', if (!store) 'murmur-miner.exe', 'flutter_windows.dll', 'data']
      : Platform.isMacOS
          ? ['Contents/MacOS/murmur_client', 'Contents/MacOS/murmur-node', 'Contents/MacOS/murmur-miner']
          : ['murmur_client', 'murmur-node', 'murmur-miner', 'lib', 'data'];
  for (final name in needed) {
    if (FileSystemEntity.typeSync('${built.path}$_sep$name') == FileSystemEntityType.notFound) {
      _fail('$name is missing from ${built.path}: build the app and bundle the node first');
    }
  }

  final system = Platform.isWindows
      ? 'windows-x64'
      : Platform.isMacOS
          ? 'macos-universal'
          : 'linux-$arch';
  final name = 'murmur-client-$tag-$system${store ? '-store' : ''}';
  final stage = Directory('build${_sep}desktop-package$_sep$name');
  if (stage.parent.existsSync()) stage.parent.deleteSync(recursive: true);
  stage.parent.createSync(recursive: true);
  String? runtimeFrom;
  if (Platform.isWindows) {
    _copyTree(built, stage);
    final runtime = await _windowsRuntimeDir();
    runtimeFrom = runtime.path;
    for (final dll in _windowsRuntime) {
      final source = File('${runtime.path}\\$dll');
      if (!source.existsSync()) _fail('$dll not found in ${runtime.path}');
      source.copySync('${stage.path}\\$dll');
    }
  } else if (Platform.isMacOS) {
    await _stageMacApp(built, Directory('${stage.path}/$_macApp'));
  } else {
    // cp keeps what a Dart copy would lose: the programs' permission to run.
    final r = await Process.run('cp', ['-a', built.path, stage.path]);
    if (r.exitCode != 0) _fail('could not copy ${built.path}: ${r.stderr}');
  }
  for (final notice in ['LICENSE', 'NOTICE']) {
    File(notice).copySync('${stage.path}$_sep$notice');
  }
  if (store) {
    // No miner in what the Store gets: its policies refuse mining on the
    // device, and the build doesn't offer it (lib/services/updates.dart).
    final miner = File('${stage.path}${_sep}murmur-miner.exe');
    if (miner.existsSync()) miner.deleteSync();
    stdout.writeln('${stage.path}: staged for the Microsoft Store, without murmur-miner');
    return;
  }

  final archive = File('dist$_sep$name.${Platform.isLinux ? 'tar.gz' : 'zip'}');
  archive.parent.createSync(recursive: true);
  if (archive.existsSync()) archive.deleteSync();
  // Windows' tar writes a zip when the name says so (-a); Linux's a gzip.
  // On a Mac, ditto: it keeps the frameworks' links and the signature as
  // the Finder unpacks them.
  final r = Platform.isMacOS
      ? await Process.run('ditto', ['-c', '-k', '--keepParent', stage.path, archive.absolute.path])
      : await Process.run('tar', [
          if (Platform.isWindows) ...['-a', '-c'] else '-cz',
          '-f', archive.absolute.path,
          '-C', stage.parent.path,
          name,
        ]);
  if (r.exitCode != 0) _fail('could not write ${archive.path}: ${r.stderr}');
  stdout.writeln('${archive.path}: ${(archive.lengthSync() / 1048576).toStringAsFixed(1)} MiB'
      '${runtimeFrom == null ? '' : ' (runtime from $runtimeFrom)'}');
}

/// The Mac app's bundle, as `flutter build macos` names it (PRODUCT_NAME).
const _macApp = 'murmur_client.app';

/// Copies the Mac app to `to`, moves the node's notices out of
/// Contents/MacOS, signs it again ad hoc, and checks the signature.
Future<void> _stageMacApp(Directory from, Directory to) async {
  final copy = await Process.run('ditto', [from.path, to.path]);
  if (copy.exitCode != 0) _fail('could not copy ${from.path}: ${copy.stderr}');
  final programs = Directory('${to.path}/Contents/MacOS');
  final resources = Directory('${to.path}/Contents/Resources')..createSync(recursive: true);
  for (final f in programs.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (name.startsWith('murmur-node-') || name == 'murmur-node.version') f.renameSync('${resources.path}/$name');
  }
  final sign = await Process.run('codesign', ['--force', '--deep', '--sign', '-', to.path]);
  if (sign.exitCode != 0) _fail('could not sign ${to.path}: ${sign.stderr}');
  final check = await Process.run('codesign', ['--verify', '--deep', '--strict', '--verbose=2', to.path]);
  if (check.exitCode != 0) _fail('the signature of ${to.path} does not hold: ${check.stderr}');
  stdout.writeln('${to.path}: signed ad hoc, and the signature holds');
}

String _arch() {
  final v = Platform.version.toLowerCase();
  return v.contains('arm64') || v.contains('aarch64') ? 'arm64' : 'x64';
}

void _copyTree(Directory from, Directory to) {
  to.createSync(recursive: true);
  for (final entity in from.listSync()) {
    final target = '${to.path}$_sep${entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty)}';
    if (entity is Directory) {
      _copyTree(entity, Directory(target));
    } else if (entity is File) {
      entity.copySync(target);
    }
  }
}

/// Where the Visual C++ runtime libraries are: the redistributable folder of
/// the Visual Studio that built the app, or else this system's own copies.
Future<Directory> _windowsRuntimeDir() async {
  final vswhere = File('${Platform.environment['ProgramFiles(x86)']}\\Microsoft Visual Studio\\Installer\\vswhere.exe');
  if (vswhere.existsSync()) {
    final r = await Process.run(vswhere.path, ['-latest', '-products', '*', '-property', 'installationPath']);
    final redist = Directory('${'${r.stdout}'.trim()}\\VC\\Redist\\MSVC');
    if (r.exitCode == 0 && redist.existsSync()) {
      final found = [
        for (final version in redist.listSync().whereType<Directory>())
          for (final crt in Directory('${version.path}\\x64').existsSync()
              ? Directory('${version.path}\\x64').listSync().whereType<Directory>()
              : const <Directory>[])
            if (crt.path.endsWith('.CRT') && _windowsRuntime.every((dll) => File('${crt.path}\\$dll').existsSync())) crt,
      ]..sort((a, b) => a.path.compareTo(b.path));
      if (found.isNotEmpty) return found.last;
    }
  }
  return Directory('${Platform.environment['SystemRoot']}\\System32');
}

Never _fail(String problem) {
  stderr.writeln(problem);
  exit(1);
}
