// Packages the built desktop app as an archive anyone can unpack and run,
// for the release jobs (.gitlab-ci.yml: build-windows, build-linux). Run on
// the platform that built it, after `flutter build windows|linux --release`
// and `dart run tool/bundle_node.dart`:
//
//   dart run tool/package_desktop.dart [--tag v0.2.1]
//
// Writes dist/murmur-client-<tag>-windows-x64.zip, or
// dist/murmur-client-<tag>-linux-<x64|arm64>.tar.gz, holding one folder:
// the app (murmur_client and what it needs), its own node beside it, and
// LICENSE and NOTICE. The Windows one also holds the Visual C++ runtime the
// app is linked against (a Windows without Visual Studio may not have it).
// The tag defaults to `v` + the version in pubspec.yaml.

import 'dart:io';

final _sep = Platform.pathSeparator;

/// The runtime libraries a Flutter Windows app needs next to it.
const _windowsRuntime = ['msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll'];

Future<void> main(List<String> args) async {
  if (!Platform.isWindows && !Platform.isLinux) _fail('this packages the Windows and Linux builds');
  String? tag;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--tag' && i + 1 < args.length) {
      tag = args[++i];
    } else {
      _fail('unknown option ${args[i]}\nusage: dart run tool/package_desktop.dart [--tag <tag>]');
    }
  }
  tag ??= 'v${RegExp(r'^version:\s*([0-9.]+)', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync())![1]}';

  final arch = _arch();
  final built = Directory(Platform.isWindows
      ? 'build${_sep}windows${_sep}x64${_sep}runner${_sep}Release'
      : 'build${_sep}linux$_sep$arch${_sep}release${_sep}bundle');
  final needed = Platform.isWindows
      ? ['murmur_client.exe', 'murmur-node.exe', 'flutter_windows.dll', 'data']
      : ['murmur_client', 'murmur-node', 'lib', 'data'];
  for (final name in needed) {
    if (FileSystemEntity.typeSync('${built.path}$_sep$name') == FileSystemEntityType.notFound) {
      _fail('$name is missing from ${built.path}: build the app and bundle the node first');
    }
  }

  final name = 'murmur-client-$tag-${Platform.isWindows ? 'windows-x64' : 'linux-$arch'}';
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
  } else {
    // cp keeps what a Dart copy would lose: the programs' permission to run.
    final r = await Process.run('cp', ['-a', built.path, stage.path]);
    if (r.exitCode != 0) _fail('could not copy ${built.path}: ${r.stderr}');
  }
  for (final notice in ['LICENSE', 'NOTICE']) {
    File(notice).copySync('${stage.path}$_sep$notice');
  }

  final archive = File('dist$_sep$name.${Platform.isWindows ? 'zip' : 'tar.gz'}');
  archive.parent.createSync(recursive: true);
  if (archive.existsSync()) archive.deleteSync();
  // Windows' tar writes a zip when the name says so (-a); Linux's a gzip.
  final r = await Process.run('tar', [
    if (Platform.isWindows) ...['-a', '-c'] else '-cz',
    '-f', archive.absolute.path,
    '-C', stage.parent.path,
    name,
  ]);
  if (r.exitCode != 0) _fail('could not write ${archive.path}: ${r.stderr}');
  stdout.writeln('${archive.path}: ${(archive.lengthSync() / 1048576).toStringAsFixed(1)} MiB'
      '${runtimeFrom == null ? '' : ' (runtime from $runtimeFrom)'}');
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
