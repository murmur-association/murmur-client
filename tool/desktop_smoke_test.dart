// Tries the packaged desktop app as a user would start it, the same way on
// Windows and Linux. Run on the folder a user unpacks (see
// package_desktop.dart), built with --dart-define=MURMUR_LOCAL_NODE_SPEC=demo
// so its node stays off the public network:
//
//   dart run tool/desktop_smoke_test.dart [--wallet-storage] <folder>
//   tool/linux_smoke_test.sh [--wallet-storage] <folder>     # on Linux
//
// 1. The app starts, makes its window, and runs its own node as a child
//    when that's switched on; closing the window stops both.
// 2. After the app is killed, its node is left running; the next start
//    stops that one and runs a new one.
// 3. With --wallet-storage (needs flutter, in the project folder): a wallet
//    is saved through the system's secure storage, found again, unlocked
//    and removed (integration_test/wallet_storage_test.dart, inside the
//    app).
//
// What differs between the systems is in [Desktop]: where the app keeps its
// settings, how its window and its node are found, and what each system
// must have for the app to start at all.
//
// The test switches the app's own node on in its settings and may store a
// wallet, so it must not run over a user's own: on Linux it runs in a
// throwaway home folder and session (linux_smoke_test.sh makes them, and
// this refuses without); Windows has no such thing, so there it refuses
// where the app's folders exist, and removes them when done.
//
// Exit codes: 0 passed, 1 failed, 3 this system can't start the app (the
// libraries it lacks are listed; nothing was tried).

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

final _sep = Platform.pathSeparator;

Future<void> main(List<String> args) async {
  final walletStorage = args.contains('--wallet-storage');
  final rest = args.where((a) => a != '--wallet-storage').toList();
  final desktop = Platform.isWindows ? _Windows() : _Linux() as Desktop;
  if (rest.length == 2 && rest[0] == '--check-system') {
    // What this system offers, starting nothing of the app's: for trying
    // the system-specific parts where the test itself can't run.
    final bundle = Directory(rest[1]).absolute.path;
    print('libraries the app needs and this system lacks: ${await desktop.missingLibraries(bundle)}');
    print("the wallet's storage is refused: ${await desktop.walletStorageRefusal()}");
    print('nodes from that folder: ${(await desktop.nodes('$bundle$_sep${desktop.node}')).join(', ')}');
    for (final line in desktop.system()) {
      print(line);
    }
    return;
  }
  if (rest.length == 3 && rest[0] == '--close-window') {
    // Closes the window with this title of this process, as the test does.
    final pid = int.parse(rest[1]);
    print('window of $pid titled "${rest[2]}": ${desktop.window(pid, rest[2])}');
    desktop.closeWindow(pid, rest[2]);
    return;
  }
  if (rest.length != 1) {
    stderr.writeln('usage: dart run tool/desktop_smoke_test.dart [--wallet-storage] <app folder>');
    exit(2);
  }
  final bundle = Directory(rest.single).absolute.path;
  for (final program in [desktop.app, desktop.node]) {
    if (!File('$bundle$_sep$program').existsSync()) {
      print('no $program in $bundle: build the app, bundle the node and package it first');
      exit(1);
    }
  }
  final missing = await desktop.missingLibraries(bundle);
  if (missing.isNotEmpty) {
    print("this system lacks libraries the app needs, so the app can't start here and nothing was tried:");
    for (final library in missing) {
      print('  $library');
    }
    exit(3);
  }
  final refusal = desktop.refusal();
  if (refusal != null) {
    print('$refusal Nothing was touched.');
    exit(1);
  }
  final test = _SmokeTest(desktop, bundle);
  try {
    desktop.switchOwnNodeOn();
    await test.startAndStop();
    await test.leftoverNode();
    final skipped = walletStorage ? await test.walletStorage() : null;
    print(skipped == null ? 'OK' : 'OK, but for the wallet check, which could not be tried here');
  } on _Failed catch (e) {
    print('FAILED: ${e.what}');
    for (final line in await test.report()) {
      print('  $line');
    }
    exitCode = 1;
  } finally {
    await test.stopEverything();
    desktop.cleanUp();
  }
  // Streams of processes this started may still be open.
  exit(exitCode);
}

class _Failed implements Exception {
  _Failed(this.what);
  final String what;
}

/// A running process: its id, its parent's, and its program.
class Proc {
  Proc(this.pid, this.parent, this.program);
  final int pid, parent;
  final String program;

  @override
  String toString() => '$pid (parent $parent, $program)';
}

/// The three checks, the same on every system.
class _SmokeTest {
  _SmokeTest(this.desktop, this.bundle);

  final Desktop desktop;
  final String bundle;

  Process? _app;
  int? _appExit;
  final _said = <String>[];

  String get _appProgram => '$bundle$_sep${desktop.app}';
  String get _nodeProgram => '$bundle$_sep${desktop.node}';

  Future<void> _waitFor(int seconds, String what, FutureOr<bool> Function() done) async {
    final deadline = DateTime.now().add(Duration(seconds: seconds));
    while (!await done()) {
      if (DateTime.now().isAfter(deadline)) throw _Failed(what);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<bool> _alive(int pid) async => Platform.isWindows
      ? (await Process.run('tasklist', ['/FI', 'PID eq $pid', '/NH'])).stdout.toString().contains(' $pid ')
      : Directory('/proc/$pid').existsSync();

  /// The app's own node: the bundled program, started by this app.
  Future<Proc?> _nodeOf(int app) async =>
      (await desktop.nodes(_nodeProgram)).where((n) => n.parent == app).firstOrNull;

  /// Starts the app and waits for its window and its node, whose id it
  /// returns.
  Future<int> _start() async {
    _said.clear();
    _appExit = null;
    final app = _app = await Process.start(_appProgram, const [], workingDirectory: bundle);
    for (final stream in [app.stdout, app.stderr]) {
      stream.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter()).listen(_said.add);
    }
    unawaited(app.exitCode.then((code) => identical(_app, app) ? _appExit = code : null));
    await _waitFor(60, 'the app made no window titled Murmur',
        () => _appExit != null ? throw _Failed('the app stopped by itself') : desktop.window(app.pid, 'Murmur') != null);
    await _waitFor(60, "the node didn't start as the app's child",
        () async => _appExit != null ? throw _Failed('the app stopped by itself') : await _nodeOf(app.pid) != null);
    return (await _nodeOf(app.pid))!.pid;
  }

  Future<void> _close(int node) async {
    final app = _app!;
    desktop.closeWindow(app.pid, 'Murmur');
    await _waitFor(20, "the app didn't exit after its window was closed", () => _appExit != null);
    await _waitFor(10, 'the node kept running after the app closed', () async => !await _alive(node));
  }

  Future<void> startAndStop() async {
    print('== 1. start, and stop with the window');
    final node = await _start();
    print('window: Murmur (${desktop.window(_app!.pid, 'Murmur')})');
    print('node: pid $node, child of the app (${_app!.pid})');
    await _close(node);
    print('closing the window stopped the app and its node');
  }

  Future<void> leftoverNode() async {
    print('== 2. a node left by a killed app is replaced');
    final left = await _start();
    final killed = _app!;
    killed.kill(ProcessSignal.sigkill);
    await _waitFor(10, 'the killed app is still there', () => _appExit != null);
    if (!await _alive(left)) throw _Failed("the node died with the killed app, so there's nothing to clean up");
    await _start();
    await _waitFor(15, 'the node left by the killed app is still running', () async => !await _alive(left));
    // One node in the end, and it's this app's: looked at over a few
    // seconds, since the app stops the old one and starts its own.
    late Proc node;
    await _waitFor(15, "there isn't exactly one node running, this app's", () async {
      final nodes = await desktop.nodes(_nodeProgram);
      if (nodes.length != 1 || nodes.single.parent != _app!.pid) return false;
      node = nodes.single;
      return true;
    });
    print('node $left was left behind; the next start stopped it and runs ${node.pid}');
    await _close(node.pid);
  }

  /// Returns why it wasn't tried, or null if it ran (and passed).
  Future<String?> walletStorage() async {
    final refusal = await desktop.walletStorageRefusal();
    if (refusal != null) {
      print('== 3. a wallet through the real secure storage: NOT TRIED HERE');
      print('  $refusal');
      return refusal;
    }
    print('== 3. a wallet through the real secure storage');
    final r = await Process.run(
      Platform.isWindows ? 'flutter.bat' : 'flutter',
      ['test', 'integration_test/wallet_storage_test.dart', '-d', Platform.operatingSystem],
      environment: desktop.debugBuildNeeds(bundle),
      runInShell: Platform.isWindows,
    );
    final lines = const LineSplitter().convert('${r.stdout}${r.stderr}').where((l) => l.trim().isNotEmpty).toList();
    // All of it on a failure (the reason is at the top), its end otherwise.
    lines.skip(r.exitCode == 0 ? (lines.length - 3).clamp(0, lines.length) : 0).forEach(print);
    if (r.exitCode != 0) throw _Failed('the wallet storage test');
    return null;
  }

  /// What the app is doing and what the system has, for a failure.
  Future<List<String>> report() async {
    final app = _app;
    return [
      if (app == null)
        'the app was not started'
      else
        'app ${app.pid}: ${_appExit == null ? 'running' : 'exited with code $_appExit'}; '
            'its Murmur window: ${desktop.window(app.pid, 'Murmur') ?? 'none'}; '
            'every bundled node running: ${(await desktop.nodes(_nodeProgram)).join('; ')}',
      if (_said.isNotEmpty) "the app's output:",
      for (final line in _said.skip((_said.length - 25).clamp(0, _said.length))) '    $line',
      ...desktop.system(),
    ];
  }

  Future<void> stopEverything() async {
    _app?.kill(ProcessSignal.sigkill);
    for (final node in await desktop.nodes(_nodeProgram)) {
      Process.killPid(node.pid, ProcessSignal.sigkill);
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}

/// What differs between the systems.
abstract class Desktop {
  /// The app's and the node's program files.
  String get app;
  String get node;

  /// Why the test must not run here (it would change a user's own app), or
  /// null.
  String? refusal();

  /// Writes the app's settings (shared_preferences) with its own node
  /// switched on, as the Chain tab's switch would.
  void switchOwnNodeOn();

  /// Removes what the test made, where it isn't thrown away with the
  /// session.
  void cleanUp();

  /// The running processes of the program `node`.
  Future<List<Proc>> nodes(String node);

  /// The window of `pid` titled `title`, as "shown" or "hidden", or null.
  String? window(int pid, String title);

  /// Asks that window to close, as its close button does.
  void closeWindow(int pid, String title);

  /// Libraries the programs in `bundle` load at start that are neither
  /// beside them nor in the system.
  Future<List<String>> missingLibraries(String bundle);

  /// Why the system's secure storage can't be used by this account, in the
  /// system's own words, or null if it can.
  Future<String?> walletStorageRefusal();

  /// The environment the wallet test's debug build needs to start (after
  /// putting beside it what must be there), or null for this one.
  Map<String, String>? debugBuildNeeds(String bundle);

  /// What this system has that the app draws with, for a failure's report.
  List<String> system();
}

class _Linux extends Desktop {
  @override
  String get app => 'murmur_client';
  @override
  String get node => 'murmur-node';

  // The app's settings folder is named by its application id.
  File get _settings =>
      File('${Platform.environment['XDG_DATA_HOME']}/info.murmur.client/shared_preferences.json');

  @override
  String? refusal() => Platform.environment['MURMUR_SMOKE_SESSION'] == null
      ? 'Run this through tool/linux_smoke_test.sh, which gives it a home folder, session and keyring of its own.'
      : _settings.existsSync()
          ? "${_settings.path} exists: this isn't a fresh home folder."
          : null;

  @override
  void switchOwnNodeOn() => _settings
    ..createSync(recursive: true)
    ..writeAsStringSync('{"flutter.run_local_node":true}');

  @override
  void cleanUp() {} // linux_smoke_test.sh removes the whole home folder

  @override
  Future<List<Proc>> nodes(String node) async {
    final program = File(node).resolveSymbolicLinksSync();
    final found = <Proc>[];
    for (final dir in Directory('/proc').listSync().whereType<Directory>()) {
      final pid = int.tryParse(dir.uri.pathSegments.lastWhere((s) => s.isNotEmpty));
      if (pid == null) continue;
      try {
        if (Link('${dir.path}/exe').resolveSymbolicLinksSync() != program) continue;
        // "pid (name) state parent …": the name may hold spaces and brackets.
        final stat = File('${dir.path}/stat').readAsStringSync();
        found.add(Proc(pid, int.parse(stat.substring(stat.lastIndexOf(')') + 2).split(' ')[1]), program));
      } on FileSystemException {
        // Gone meanwhile, or not ours to read.
      }
    }
    return found;
  }

  /// The window's id, from the window manager's list: "id desktop pid host title".
  String? _windowId(int pid, String title) {
    final r = Process.runSync('wmctrl', ['-l', '-p']);
    for (final line in const LineSplitter().convert('${r.stdout}')) {
      final m = RegExp(r'^(\S+)\s+\S+\s+(\d+)\s+\S+\s(.*)$').firstMatch(line);
      if (m != null && int.parse(m[2]!) == pid && m[3] == title) return m[1];
    }
    return null;
  }

  // Listed by the window manager means mapped: there's a display here, real or not.
  @override
  String? window(int pid, String title) => _windowId(pid, title) == null ? null : 'shown';

  @override
  void closeWindow(int pid, String title) {
    final id = _windowId(pid, title);
    if (id != null) Process.runSync('wmctrl', ['-i', '-c', id]);
  }

  // The archive carries the app's own libraries; the rest are the desktop's.
  @override
  Future<List<String>> missingLibraries(String bundle) async => const [];

  // linux_smoke_test.sh gives the session an unlocked keyring.
  @override
  Future<String?> walletStorageRefusal() async => null;

  @override
  Map<String, String>? debugBuildNeeds(String bundle) => null;

  @override
  List<String> system() => const [];
}

class _Windows extends Desktop {
  @override
  String get app => 'murmur_client.exe';
  @override
  String get node => 'murmur-node.exe';

  // Where the app keeps its settings and wallet (named by its company and
  // product), and its node's data.
  final _settings = Directory('${Platform.environment['APPDATA']}\\Murmur Association');
  final _data = Directory('${Platform.environment['APPDATA']}\\murmur-client');
  final _system32 = '${Platform.environment['SystemRoot']}\\System32';

  /// The software graphics a tried copy may be given (fetch_test_graphics.ps1).
  static const _testGraphics = ['opengl32.dll', 'libgallium_wgl.dll', 'd3d10warp.dll'];

  @override
  String? refusal() {
    for (final dir in [_settings, _data]) {
      if (dir.existsSync()) {
        return '${dir.path} exists: the app has been used here, and this test would change its settings.';
      }
    }
    return null;
  }

  @override
  void switchOwnNodeOn() => File('${_settings.path}\\Murmur\\shared_preferences.json')
    ..createSync(recursive: true)
    ..writeAsStringSync('{"flutter.run_local_node":true}');

  // Only what this run made: both folders were absent when it began.
  @override
  void cleanUp() {
    for (final dir in [_settings, _data]) {
      try {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Still held by a process on its way out.
      }
    }
  }

  Future<String> _powershell(String script) async =>
      '${(await Process.run('powershell', ['-NoProfile', '-Command', script])).stdout}'.trim();

  @override
  Future<List<Proc>> nodes(String node) async {
    final out = await _powershell("Get-CimInstance Win32_Process -Filter \"Name='${this.node}'\" | "
        r'ForEach-Object { "$($_.ProcessId)|$($_.ParentProcessId)|$($_.ExecutablePath)" }');
    return [
      for (final line in const LineSplitter().convert(out))
        if (line.split('|') case [final pid, final parent, final program]
            when program.toLowerCase() == node.toLowerCase())
          Proc(int.parse(pid), int.parse(parent), program),
    ];
  }

  static final _user32 = DynamicLibrary.open('user32.dll');
  static final _findWindowEx = _user32.lookupFunction<
      IntPtr Function(IntPtr, IntPtr, Pointer<Utf16>, Pointer<Utf16>),
      int Function(int, int, Pointer<Utf16>, Pointer<Utf16>)>('FindWindowExW');
  static final _windowProcess = _user32.lookupFunction<Uint32 Function(IntPtr, Pointer<Uint32>),
      int Function(int, Pointer<Uint32>)>('GetWindowThreadProcessId');
  static final _windowText = _user32.lookupFunction<Int32 Function(IntPtr, Pointer<Utf16>, Int32),
      int Function(int, Pointer<Utf16>, int)>('GetWindowTextW');
  static final _isVisible = _user32.lookupFunction<Int32 Function(IntPtr), int Function(int)>('IsWindowVisible');
  static final _postMessage = _user32.lookupFunction<Int32 Function(IntPtr, Uint32, IntPtr, IntPtr),
      int Function(int, int, int, int)>('PostMessageW');

  /// The handle of the top-level window of `pid` titled `title`, shown or
  /// not. A release runner has no desktop to show a window on, but the app
  /// still makes its window there, and takes a close request on it.
  int _windowHandle(int pid, String title) => using((arena) {
        final owner = arena<Uint32>();
        final text = arena<Uint16>(256).cast<Utf16>();
        for (var h = _findWindowEx(0, 0, nullptr, nullptr); h != 0; h = _findWindowEx(0, h, nullptr, nullptr)) {
          _windowProcess(h, owner);
          if (owner.value != pid) continue;
          _windowText(h, text, 256);
          if (text.toDartString() == title) return h;
        }
        return 0;
      });

  @override
  String? window(int pid, String title) {
    final h = _windowHandle(pid, title);
    return h == 0 ? null : (_isVisible(h) != 0 ? 'shown' : 'hidden: no desktop here');
  }

  @override
  void closeWindow(int pid, String title) {
    final h = _windowHandle(pid, title);
    if (h != 0) _postMessage(h, 0x0010 /* WM_CLOSE */, 0, 0);
  }

  /// The Visual Studio (or its build tools) on this machine, if any.
  Future<String?> _visualStudio() async {
    final vswhere =
        File('${Platform.environment['ProgramFiles(x86)']}\\Microsoft Visual Studio\\Installer\\vswhere.exe');
    if (!vswhere.existsSync()) return null;
    final r = await Process.run(vswhere.path, ['-latest', '-products', '*', '-property', 'installationPath']);
    final path = '${r.stdout}'.trim();
    return r.exitCode == 0 && path.isNotEmpty ? path : null;
  }

  List<Directory> _matching(String parent, String Function(String name) child) => !Directory(parent).existsSync()
      ? const []
      : [
          for (final dir in Directory(parent).listSync().whereType<Directory>().toList()
            ..sort((a, b) => a.path.compareTo(b.path)))
            if (Directory(child(dir.path)).existsSync()) Directory(child(dir.path)),
        ];

  // Read from the files with dumpbin (the build tools'), so nothing is
  // started; without dumpbin, nothing is known. From the two programs,
  // through the libraries beside them that they load: not every library in
  // the folder (a plugin ships one for Java, dartjni.dll, that nothing loads
  // on Windows). With one missing, Windows won't start the app (exit code
  // -1073741515).
  @override
  Future<List<String>> missingLibraries(String bundle) async {
    final vs = await _visualStudio();
    final dumpbin = vs == null
        ? null
        : _matching('$vs\\VC\\Tools\\MSVC', (v) => '$v\\bin\\Hostx64\\x64')
            .map((d) => File('${d.path}\\dumpbin.exe'))
            .where((f) => f.existsSync())
            .lastOrNull;
    if (dumpbin == null) return const [];
    final missing = <String, String>{};
    final seen = <String>{};
    final queue = ['$bundle\\$app', '$bundle\\$node'];
    while (queue.isNotEmpty) {
      final file = queue.removeLast();
      if (!seen.add(file.toLowerCase())) continue;
      final r = await Process.run(dumpbin.path, ['/nologo', '/dependents', file]);
      for (final line in const LineSplitter().convert('${r.stdout}')) {
        final name = line.trim();
        // API sets (api-ms-win-…, ext-ms-…) are names the system resolves, not files.
        if (!RegExp(r'^[\w.+-]+\.dll$', caseSensitive: false).hasMatch(name) ||
            RegExp(r'^(api|ext)-ms-', caseSensitive: false).hasMatch(name)) {
          continue;
        }
        if (File('$bundle\\$name').existsSync()) {
          queue.add('$bundle\\$name');
        } else if (!File('$_system32\\$name').existsSync()) {
          missing[name.toLowerCase()] = '$name (for ${file.split('\\').last})';
        }
      }
    }
    return missing.values.toList()..sort();
  }

  // The wallet's storage encrypts with Windows' data protection (DPAPI),
  // under the account's own key. An account that isn't logged on with its
  // profile, as a release runner's is, has no such key: Windows refuses, for
  // any program. Asked of Windows itself, apart from the app, so that a
  // refusal isn't taken for a fault of the app's, nor the other way.
  @override
  Future<String?> walletStorageRefusal() async {
    final answer = await _powershell('Add-Type -AssemblyName System.Security; '
        r"try { [void][Security.Cryptography.ProtectedData]::Protect([byte[]](1, 2, 3), $null, 'CurrentUser'); 'works' } "
        r'catch { $_.Exception.GetBaseException().Message }');
    return answer == 'works'
        ? null
        : "Windows' data protection doesn't work for this account (${Platform.environment['USERNAME']}): $answer "
            "The wallet's storage needs it, so this check needs a logged-on user's account.";
  }

  // The debug app needs the debug runtime: on a machine with only the build
  // tools, that's in their folders, not the system's. And beside it, the
  // software graphics the tried copy was given, if any: Windows' Direct3D
  // takes its software renderer from beside the program, not from the
  // search path. The build leaves other files in its folder alone, and
  // that folder is the debug one; what's released is built and packaged
  // from the release one.
  @override
  Map<String, String>? debugBuildNeeds(String bundle) {
    final debug = Directory('build\\windows\\x64\\runner\\Debug');
    for (final name in _testGraphics) {
      final given = File('$bundle\\$name');
      if (given.existsSync()) {
        debug.createSync(recursive: true);
        given.copySync('${debug.path}\\$name');
      }
    }
    final kits = '${Platform.environment['ProgramFiles(x86)']}\\Windows Kits\\10\\bin';
    final vs = Process.runSync(
            '${Platform.environment['ProgramFiles(x86)']}\\Microsoft Visual Studio\\Installer\\vswhere.exe',
            ['-latest', '-products', '*', '-property', 'installationPath'],
            runInShell: false)
        .stdout
        .toString()
        .trim();
    final extra = [
      bundle,
      for (final version in _matching('$vs\\VC\\Redist\\MSVC', (v) => '$v\\debug_nonredist\\x64'))
        for (final crt in version.listSync().whereType<Directory>())
          if (crt.path.endsWith('.DebugCRT')) crt.path,
      ..._matching(kits, (v) => '$v\\x64\\ucrt').map((d) => d.path).toList().reversed.take(1),
    ];
    return {'PATH': '${extra.join(';')};${Platform.environment['PATH']}'};
  }

  // The engine draws through Direct3D, and a server system may lack parts.
  @override
  List<String> system() => [
        'graphics libraries in the system: ${[
          for (final name in [
            'd3d11.dll', 'dxgi.dll', 'd3dcompiler_47.dll', 'd3d10warp.dll', 'dcomp.dll', 'dwmapi.dll', 'opengl32.dll' //
          ])
            '$name ${File('$_system32\\$name').existsSync() ? 'yes' : 'NO'}',
        ].join(', ')}',
      ];
}
