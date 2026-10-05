// Packages the built Windows app as a zip anyone can unpack and run, for
// the release job (.gitlab-ci.yml, build-windows). Run after
// `flutter build windows --release` and `dart run tool/bundle_node.dart`:
//
//   dart run tool/package_windows.dart [--tag v0.2.1]
//
// Writes dist/murmur-client-<tag>-windows-x64.zip, holding one folder: the
// app (murmur_client.exe and what it needs), its own node beside it, the
// Visual C++ runtime the app is linked against (a Windows without Visual
// Studio may not have it), and LICENSE and NOTICE. The tag defaults to
// `v` + the version in pubspec.yaml.

import 'dart:io';

const _release = r'build\windows\x64\runner\Release';

/// The runtime libraries a Flutter Windows app needs next to it.
const _runtime = ['msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll'];

Future<void> main(List<String> args) async {
  if (!Platform.isWindows) _fail('this packages the Windows build: run it on Windows');
  String? tag;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--tag' && i + 1 < args.length) {
      tag = args[++i];
    } else {
      _fail('unknown option ${args[i]}\nusage: dart run tool/package_windows.dart [--tag <tag>]');
    }
  }
  tag ??= 'v${RegExp(r'^version:\s*([0-9.]+)', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync())![1]}';
  final built = Directory(_release);
  for (final needed in ['murmur_client.exe', 'murmur-node.exe', 'flutter_windows.dll', 'data']) {
    if (FileSystemEntity.typeSync('${built.path}\\$needed') == FileSystemEntityType.notFound) {
      _fail('$needed is missing from ${built.path}: build the app and bundle the node first');
    }
  }

  final name = 'murmur-client-$tag-windows-x64';
  final stage = Directory('build\\windows-package\\$name');
  if (stage.parent.existsSync()) stage.parent.deleteSync(recursive: true);
  _copyTree(built, stage);
  final runtime = await _runtimeDir();
  for (final dll in _runtime) {
    final source = File('${runtime.path}\\$dll');
    if (!source.existsSync()) _fail('$dll not found in ${runtime.path}');
    source.copySync('${stage.path}\\$dll');
  }
  for (final notice in ['LICENSE', 'NOTICE']) {
    File(notice).copySync('${stage.path}\\$notice');
  }

  final zip = File('dist\\$name.zip');
  zip.parent.createSync(recursive: true);
  if (zip.existsSync()) zip.deleteSync();
  // Windows' tar writes a zip when the name says so (-a).
  final r = await Process.run('tar', ['-a', '-c', '-f', zip.absolute.path, '-C', stage.parent.path, name]);
  if (r.exitCode != 0) _fail('could not write ${zip.path}: ${r.stderr}');
  stdout.writeln('${zip.path}: ${(zip.lengthSync() / 1048576).toStringAsFixed(1)} MiB '
      '(runtime from ${runtime.path})');
}

void _copyTree(Directory from, Directory to) {
  to.createSync(recursive: true);
  for (final entity in from.listSync()) {
    final target = '${to.path}\\${entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty)}';
    if (entity is Directory) {
      _copyTree(entity, Directory(target));
    } else if (entity is File) {
      entity.copySync(target);
    }
  }
}

/// Where the Visual C++ runtime libraries are: the redistributable folder of
/// the Visual Studio that built the app, or else this system's own copies.
Future<Directory> _runtimeDir() async {
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
            if (crt.path.endsWith('.CRT') && _runtime.every((dll) => File('${crt.path}\\$dll').existsSync())) crt,
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
