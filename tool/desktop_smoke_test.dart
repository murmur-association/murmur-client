// Tries the packaged desktop app as a user would start it, the same way on
// Windows, Linux and macOS. Run on the folder a user unpacks (see
// package_desktop.dart), built with --dart-define=MURMUR_LOCAL_NODE_SPEC=demo
// so its node stays off the public network:
//
//   dart run tool/desktop_smoke_test.dart [--wallet-storage] <folder>
//   tool/linux_session.sh dart run tool/desktop_smoke_test.dart [--wallet-storage] <folder>     # on Linux
//   dart run tool/desktop_smoke_test.dart --packaged <family> <install folder>     # an installed MSIX
//
// 1. The app starts, makes its window, and runs its own node as a child
//    when that's switched on; closing the window stops both. The app
//    never connects to that node: it reads from the node the user chose,
//    and its own only takes part in the network.
// 2. After the app is killed, its node is left running; the next start
//    stops that one and runs a new one.
// 3. With --wallet-storage (needs flutter, in the project folder): a wallet
//    is saved through the system's secure storage, found again, unlocked
//    and removed (integration_test/wallet_storage_test.dart, inside the
//    app).
// 4. With --packaged (Windows: the Microsoft Store's package, installed by
//    tool/msix_package.ps1 -Smoke): the app is started as the Start menu
//    starts it, and checks 1 and 2 run on it beside a node of the
//    installer's copy, recorded in the real %APPDATA%; the package must
//    leave that node and its pid file alone and write only in its own
//    folder. 5. A notification's click (its activator, asked for over COM)
//    starts the app in its package.
//
// What differs between the systems is in [Desktop]: where the app keeps its
// settings, how its window and its node are found, and what each system
// must have for the app to start at all.
//
// The test switches the app's own node on in its settings and may store a
// wallet, so it must not run over a user's own: on Linux it runs in a
// throwaway home folder and session (linux_session.sh makes them, and
// this refuses without); Windows and macOS have no such thing, so there it
// refuses where the app's settings or folders exist, and removes them when
// done.
//
// On macOS, where nothing outside the app may press its window's buttons
// without Accessibility (which a runner hasn't), "closing the window" is a
// quit request instead, as the app menu's Quit sends: the app takes the
// same way out, and the app delegate quits after its last window anyway.
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
  String? family;
  if (rest.length == 3 && rest[0] == '--packaged') {
    if (!Platform.isWindows) {
      stderr.writeln('--packaged tries an installed MSIX package, on Windows');
      exit(2);
    }
    family = rest[1];
    rest.removeRange(0, 2);
  }
  final desktop = Platform.isWindows
      ? (family == null ? _Windows() : _WindowsPackage(family))
      : Platform.isMacOS
          ? _Mac()
          : _Linux() as Desktop;
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
  if (rest.length == 2 && rest[0] == '--clients-of') {
    // Who is connected to the ports this process listens on, as the test
    // looks for the app among its node's clients.
    final ports = await desktop.listening(int.parse(rest[1]));
    print('ports ${rest[1]} listens on: $ports');
    print('processes connected to them from this machine: ${await desktop.connectedTo(ports)}');
    return;
  }
  if (rest.length != 1) {
    stderr.writeln('usage: dart run tool/desktop_smoke_test.dart [--wallet-storage | --packaged <family>] <app folder>');
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
  Process? planted;
  try {
    desktop.switchOwnNodeOn();
    if (desktop is _WindowsPackage) planted = await desktop.plantInstallersNode(bundle);
    await test.startAndStop();
    await test.leftoverNode();
    if (desktop is _WindowsPackage) {
      await desktop.checkApart(planted!, test.alive);
      await desktop.toastActivation(bundle);
    }
    final skipped = walletStorage ? await test.walletStorage() : null;
    print(skipped == null ? 'OK' : 'OK, but for the wallet check, which could not be tried here');
  } on _Failed catch (e) {
    print('FAILED: ${e.what}');
    for (final line in await test.report()) {
      print('  $line');
    }
    exitCode = 1;
  } finally {
    planted?.kill(ProcessSignal.sigkill);
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

  /// The app's process id: started by this test, or by Windows for a
  /// package (Desktop.launch).
  int? _app;
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

  Future<bool> alive(int pid) => _alive(pid);

  Future<bool> _alive(int pid) async => Platform.isWindows
      ? (await Process.run('tasklist', ['/FI', 'PID eq $pid', '/NH'])).stdout.toString().contains(' $pid ')
      : Platform.isMacOS
          // No /proc on a Mac: signal 0 only asks whether the process is there.
          ? (await Process.run('kill', ['-0', '$pid'])).exitCode == 0
          : Directory('/proc/$pid').existsSync();

  /// The app's own node: the bundled program, started by this app.
  Future<Proc?> _nodeOf(int app) async =>
      (await desktop.nodes(_nodeProgram)).where((n) => n.parent == app).firstOrNull;

  /// Starts the app and waits for its window and its node, whose id it
  /// returns.
  Future<int> _start() async {
    _said.clear();
    _appExit = null;
    final int app;
    final launched = await desktop.launch(bundle);
    if (launched == null) {
      final process = await Process.start(_appProgram, const [], workingDirectory: bundle);
      app = _app = process.pid;
      for (final stream in [process.stdout, process.stderr]) {
        stream.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter()).listen(_said.add);
      }
      unawaited(process.exitCode.then((code) => _app == app ? _appExit = code : null));
    } else {
      // Not this test's child: its end is watched for instead.
      app = _app = launched;
      unawaited(() async {
        // Gone at two looks in a row, so one failed look isn't an exit.
        var missed = 0;
        while (_app == app && _appExit == null) {
          missed = await _alive(app) ? 0 : missed + 1;
          if (missed >= 2) _appExit = -1;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }());
    }
    await _waitFor(60, 'the app made no window titled Murmur',
        () => _appExit != null ? throw _Failed('the app stopped by itself') : desktop.window(app, 'Murmur') != null);
    await _waitFor(60, "the node didn't start as the app's child",
        () async => _appExit != null ? throw _Failed('the app stopped by itself') : await _nodeOf(app) != null);
    return (await _nodeOf(app))!.pid;
  }

  Future<void> _close(int node) async {
    desktop.closeWindow(_app!, 'Murmur');
    await _waitFor(20, "the app didn't exit after its window was closed", () => _appExit != null);
    await _waitFor(10, 'the node kept running after the app closed', () async => !await _alive(node));
  }

  Future<void> startAndStop() async {
    print('== 1. start, and stop with the window');
    final node = await _start();
    print('window: Murmur (${desktop.window(_app!, 'Murmur')})');
    print('node: pid $node, child of the app (${_app!})');
    await _leftAlone(node);
    await _close(node);
    print('closing the window stopped the app and its node');
  }

  /// The app never connects to its own node, which keeps nobody else's
  /// messages: the client reads from the node the user chose. Watched for
  /// a while after the node listens, which is when an app that did would
  /// connect.
  Future<void> _leftAlone(int node) async {
    var ports = <int>{};
    await _waitFor(30, "the app's node listens on no port", () async => (ports = await desktop.listening(node)).isNotEmpty);
    // A connection of this test's own must be seen, or seeing none of the
    // app's would say nothing.
    final probe = await Socket.connect(InternetAddress.loopbackIPv4, ports.first);
    try {
      await _waitFor(10, "a connection to the node's port ${ports.first} isn't seen, so the app's couldn't be either",
          () async => (await desktop.connectedTo(ports)).contains(pid));
    } finally {
      probe.destroy();
    }
    final until = DateTime.now().add(const Duration(seconds: 10));
    while (DateTime.now().isBefore(until)) {
      if ((await desktop.connectedTo(ports)).contains(_app!)) {
        throw _Failed('the app connected to its own node (ports $ports) instead of leaving it alone');
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    print('the node listens on $ports, and the app never connected to it');
  }

  Future<void> leftoverNode() async {
    print('== 2. a node left by a killed app is replaced');
    final left = await _start();
    Process.killPid(_app!, ProcessSignal.sigkill);
    await _waitFor(10, 'the killed app is still there', () => _appExit != null);
    if (!await _alive(left)) throw _Failed("the node died with the killed app, so there's nothing to clean up");
    await _start();
    await _waitFor(15, 'the node left by the killed app is still running', () async => !await _alive(left));
    // One node in the end, and it's this app's: looked at over a few
    // seconds, since the app stops the old one and starts its own.
    late Proc node;
    await _waitFor(15, "there isn't exactly one node running, this app's", () async {
      final nodes = await desktop.nodes(_nodeProgram);
      if (nodes.length != 1 || nodes.single.parent != _app!) return false;
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
        'app $app: ${_appExit == null ? 'running' : 'exited with code $_appExit'}; '
            'its Murmur window: ${desktop.window(app, 'Murmur') ?? 'none'}; '
            'every bundled node running: ${(await desktop.nodes(_nodeProgram)).join('; ')}',
      if (_said.isNotEmpty) "the app's output:",
      for (final line in _said.skip((_said.length - 25).clamp(0, _said.length))) '    $line',
      ...desktop.system(),
    ];
  }

  Future<void> stopEverything() async {
    if (_app case final app?) Process.killPid(app, ProcessSignal.sigkill);
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

  /// Starts the app the system's way and returns its process id, or null
  /// when the test starts the program in `bundle` itself (all but a
  /// package, which only Windows may start, for it to have its identity).
  Future<int?> launch(String bundle) async => null;

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

  /// The TCP ports the process `pid` listens on.
  Future<Set<int>> listening(int pid);

  /// The processes with a connection from this machine (127.0.0.1) to one
  /// of `ports`.
  Future<Set<int>> connectedTo(Set<int> ports);

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
  String? refusal() => Platform.environment['MURMUR_TEST_SESSION'] == null
      ? 'Run this through tool/linux_session.sh, which gives it a home folder, session and keyring of its own.'
      : _settings.existsSync()
          ? "${_settings.path} exists: this isn't a fresh home folder."
          : null;

  @override
  void switchOwnNodeOn() => _settings
    ..createSync(recursive: true)
    ..writeAsStringSync('{"flutter.run_local_node":true}');

  @override
  void cleanUp() {} // linux_session.sh removes the whole home folder

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

  /// The sockets (inode numbers) each process holds, of those this account
  /// may look at.
  Map<String, int> _socketOwners() {
    final owners = <String, int>{};
    for (final dir in Directory('/proc').listSync().whereType<Directory>()) {
      final pid = int.tryParse(dir.uri.pathSegments.lastWhere((s) => s.isNotEmpty));
      if (pid == null) continue;
      try {
        for (final fd in Directory('${dir.path}/fd').listSync()) {
          final m = RegExp(r'^socket:\[(\d+)\]$').firstMatch(Link(fd.path).targetSync());
          if (m != null) owners[m.group(1)!] = pid;
        }
      } on FileSystemException {
        // Gone meanwhile, or not ours to read.
      }
    }
    return owners;
  }

  /// The system's TCP sockets over IPv4: "sl local remote state … inode",
  /// addresses as hex "address:port". State 0A listens, 01 is connected.
  Iterable<({String local, String remote, String state, String inode})> _tcp() sync* {
    for (final line in File('/proc/net/tcp').readAsLinesSync().skip(1)) {
      final f = line.trim().split(RegExp(r'\s+'));
      if (f.length > 9) yield (local: f[1], remote: f[2], state: f[3], inode: f[9]);
    }
  }

  static int _port(String hexAddress) => int.parse(hexAddress.split(':').last, radix: 16);

  @override
  Future<Set<int>> listening(int pid) async {
    final owners = _socketOwners();
    return {
      for (final s in _tcp())
        if (s.state == '0A' && owners[s.inode] == pid) _port(s.local),
    };
  }

  @override
  Future<Set<int>> connectedTo(Set<int> ports) async {
    final owners = _socketOwners();
    return {
      for (final s in _tcp())
        // 127.0.0.1, in the kernel's byte order.
        if (s.state == '01' && s.remote.startsWith('0100007F:') && ports.contains(_port(s.remote)))
          if (owners[s.inode] case final pid?) pid,
    };
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

  // linux_session.sh gives the session an unlocked keyring.
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
  Future<List<Proc>> nodes(String node) => _processes(node);

  /// The running processes of `program` (a full path).
  Future<List<Proc>> _processes(String program) async {
    final name = program.split('\\').last;
    final out = await _powershell("Get-CimInstance Win32_Process -Filter \"Name='$name'\" | "
        r'ForEach-Object { "$($_.ProcessId)|$($_.ParentProcessId)|$($_.ExecutablePath)" }');
    return [
      for (final line in const LineSplitter().convert(out))
        if (line.split('|') case [final pid, final parent, final path]
            when path.toLowerCase() == program.toLowerCase())
          Proc(int.parse(pid), int.parse(parent), path),
    ];
  }

  /// The command line `pid` was started with.
  Future<String> _commandLine(int pid) =>
      _powershell("(Get-CimInstance Win32_Process -Filter \"ProcessId=$pid\").CommandLine");

  Set<int> _numbers(String out) => {
        for (final line in const LineSplitter().convert(out))
          if (int.tryParse(line.trim()) case final n?) n,
      };

  @override
  Future<Set<int>> listening(int pid) async => _numbers(await _powershell(
      'Get-NetTCPConnection -State Listen -OwningProcess $pid -ErrorAction SilentlyContinue | '
      r'ForEach-Object { $_.LocalPort }'));

  @override
  Future<Set<int>> connectedTo(Set<int> ports) async => ports.isEmpty
      ? const {}
      : _numbers(await _powershell('\$ports = ${ports.join(',')}; '
          r"Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | "
          r"Where-Object { $_.RemoteAddress -eq '127.0.0.1' -and $ports -contains $_.RemotePort } | "
          r'ForEach-Object { $_.OwningProcess }'));

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
        ..._crashes(),
      ];

  /// What Windows recorded of the app or its node crashing in the last
  /// quarter of an hour (Windows Error Reporting, in the Application log):
  /// the faulting module and exception code, which a packaged app, whose
  /// output nobody reads, says nowhere else.
  List<String> _crashes() {
    final r = Process.runSync('powershell', [
      '-NoProfile', '-Command', //
      r"Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='Application Error','Windows Error Reporting','.NET Runtime'; StartTime=(Get-Date).AddMinutes(-15)} -ErrorAction SilentlyContinue | "
          r"Where-Object { $_.Message -match 'murmur' } | Select-Object -First 4 | "
          r"ForEach-Object { '--- ' + $_.TimeCreated.ToString('HH:mm:ss') + ' ' + $_.ProviderName + ' ' + $_.Id; $_.Message }",
    ]);
    final lines = const LineSplitter().convert('${r.stdout}').where((l) => l.trim().isNotEmpty).take(80).toList();
    return lines.isEmpty ? ['no crash of the app or its node recorded by Windows'] : ['crashes Windows recorded:', ...lines.map((l) => '    $l')];
  }
}

class _Mac extends Desktop {
  // The bundle as flutter builds it (PRODUCT_NAME), its programs inside.
  @override
  String get app => 'murmur_client.app/Contents/MacOS/murmur_client';
  @override
  String get node => 'murmur_client.app/Contents/MacOS/murmur-node';

  /// The app's settings are its user defaults, a domain named by its bundle
  /// id; its node's data is under ~/.local/share, as local_node_io.dart
  /// finds it without XDG variables.
  static const _domain = 'info.murmur.client';
  final _data = Directory('${Platform.environment['HOME']}/.local/share/murmur-client');

  bool get _hasSettings => Process.runSync('defaults', ['read', _domain]).exitCode == 0;

  @override
  String? refusal() => _hasSettings
      ? "the user defaults $_domain exist: the app has been used here, and this test would change its settings."
      : _data.existsSync()
          ? '${_data.path} exists: the app has been used here.'
          : null;

  @override
  void switchOwnNodeOn() => Process.runSync('defaults', ['write', _domain, 'flutter.run_local_node', '-bool', 'true']);

  // Only what this run made: both were absent when it began.
  @override
  void cleanUp() {
    Process.runSync('defaults', ['delete', _domain]);
    try {
      if (_data.existsSync()) _data.deleteSync(recursive: true);
    } on FileSystemException {
      // Still held by a process on its way out.
    }
  }

  @override
  Future<List<Proc>> nodes(String node) async {
    final program = File(node).resolveSymbolicLinksSync();
    final r = await Process.run('ps', ['-axo', 'pid=,ppid=,comm=']);
    final found = <Proc>[];
    for (final line in const LineSplitter().convert('${r.stdout}')) {
      final m = RegExp(r'^\s*(\d+)\s+(\d+)\s+(.+)$').firstMatch(line);
      if (m == null) continue;
      try {
        if (File(m[3]!).resolveSymbolicLinksSync() != program) continue;
      } on FileSystemException {
        continue; // not a path (a process named otherwise), or gone
      }
      found.add(Proc(int.parse(m[1]!), int.parse(m[2]!), program));
    }
    return found;
  }

  /// lsof's fields (-F): "p<pid>" starts a process, "n<name>" is a socket's
  /// addresses, "local" or "local->remote".
  Future<List<({int pid, String name})>> _lsof(List<String> args) async {
    final r = await Process.run('lsof', ['-nP', ...args]);
    final out = <({int pid, String name})>[];
    var pid = 0;
    for (final line in const LineSplitter().convert('${r.stdout}')) {
      if (line.startsWith('p')) pid = int.tryParse(line.substring(1)) ?? 0;
      if (line.startsWith('n')) out.add((pid: pid, name: line.substring(1)));
    }
    return out;
  }

  static int? _port(String address) => int.tryParse(address.substring(address.lastIndexOf(':') + 1));

  @override
  Future<Set<int>> listening(int pid) async => {
        for (final s in await _lsof(['-a', '-p', '$pid', '-iTCP', '-sTCP:LISTEN', '-Fpn']))
          if (_port(s.name) case final port?) port,
      };

  @override
  Future<Set<int>> connectedTo(Set<int> ports) async => {
        for (final s in await _lsof(['-iTCP', '-sTCP:ESTABLISHED', '-Fpn']))
          if (s.name.split('->') case [_, final remote]
              when remote.startsWith('127.0.0.1:') && ports.contains(_port(remote)))
            s.pid,
      };

  /// The window server's windows (CGWindowListCopyWindowInfo, through
  /// JavaScript for Automation): owner, layer, title, on screen. Asking needs
  /// no permission, but titles come only with Screen Recording's: without
  /// it a title is null.
  List<({int pid, int layer, String? title, bool shown})> _windows() {
    const script = "ObjC.import('CoreGraphics');"
        r'JSON.stringify(ObjC.deepUnwrap(ObjC.castRefToObject($.CGWindowListCopyWindowInfo(0, 0)))'
        '.map(w => [w.kCGWindowOwnerPID, w.kCGWindowLayer, w.kCGWindowName === undefined ? null : w.kCGWindowName,'
        ' w.kCGWindowIsOnscreen ? 1 : 0]))';
    final r = Process.runSync('osascript', ['-l', 'JavaScript', '-e', script]);
    if (r.exitCode != 0) return const [];
    return [
      for (final w in jsonDecode('${r.stdout}') as List)
        if (w case [final int pid, final int layer, final String? title, final int shown])
          (pid: pid, layer: layer, title: title, shown: shown == 1),
    ];
  }

  @override
  String? window(int pid, String title) {
    // Layer 0: an app's ordinary windows, not its menu bar or status items.
    final own = _windows().where((w) => w.pid == pid && w.layer == 0).toList();
    final named = own.where((w) => w.title == title).firstOrNull;
    if (named != null) return named.shown ? 'shown' : 'hidden';
    // Titles can't be read here: a window of the app's is what can be told.
    final untitled = own.where((w) => w.title == null).firstOrNull;
    if (untitled != null) return '${untitled.shown ? 'shown' : 'hidden'} (its title unread: no Screen Recording here)';
    return null;
  }

  // A quit request to that process (NSRunningApplication.terminate, a quit
  // Apple Event, as the app menu's Quit sends): the window's close button
  // can't be pressed from outside without Accessibility.
  @override
  void closeWindow(int pid, String title) {
    final r = Process.runSync('osascript', [
      '-l', 'JavaScript', '-e',
      "ObjC.import('AppKit'); const a = \$.NSRunningApplication.runningApplicationWithProcessIdentifier($pid);"
          " a.isNil() ? 'not an app' : (a.terminate ? 'asked to quit' : 'refused')",
    ]);
    print('quit request to $pid: ${'${r.stdout}${r.stderr}'.trim()}');
  }

  // The bundle carries the app's frameworks; the rest is the system's.
  @override
  Future<List<String>> missingLibraries(String bundle) async => const [];

  // The device's key store asks for the login password in a dialog of the
  // system's, which nobody answers on a runner (the acceptance tests keep the
  // vault to a passphrase there for the same reason).
  @override
  Future<String?> walletStorageRefusal() async => Platform.environment['CI'] != null
      ? "the Mac's key store asks for the login password in a dialog, and nobody is there to answer it."
      : null;

  @override
  Map<String, String>? debugBuildNeeds(String bundle) => null;

  // (The bundle's signature is checked when it's packaged.)
  @override
  List<String> system() {
    final version = Process.runSync('sw_vers', ['-productVersion']);
    return ['macOS ${'${version.stdout}'.trim()}'];
  }
}

/// The Microsoft Store's package (windows/msix/), installed: started as the
/// Start menu starts it, through its identity, from its install folder.
/// What it writes under %APPDATA% goes to a folder of the package's own
/// (LocalCache\Roaming), removed with it, and it reads the real %APPDATA%
/// merged with that. So beside the first two checks it's tried living
/// beside the installer's copy, and being started by a notification's click.
class _WindowsPackage extends _Windows {
  _WindowsPackage(this.family);

  /// The package's family name (Get-AppxPackage's PackageFamilyName).
  final String family;

  String get _private => '${Platform.environment['LOCALAPPDATA']}\\Packages\\$family\\LocalCache\\Roaming';
  File get _plantedPid => File('${_data.path}\\node\\app-node.pid');

  Future<Set<int>> _apps(String bundle) async => {for (final p in await _processes('$bundle\\$app')) p.pid};

  @override
  Future<int?> launch(String bundle) async {
    final before = await _apps(bundle);
    // ShellExecute of the app's entry in the Start menu's folder: Windows
    // starts it in its package, as a click there does.
    await _powershell("Start-Process 'shell:AppsFolder\\$family!Murmur'");
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (DateTime.now().isBefore(deadline)) {
      final started = (await _apps(bundle)).difference(before);
      if (started.isNotEmpty) return started.first;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw _Failed('Windows started no $app from the package $family');
  }

  @override
  void switchOwnNodeOn() => File('$_private\\Murmur Association\\Murmur\\shared_preferences.json')
    ..createSync(recursive: true)
    ..writeAsStringSync('{"flutter.run_local_node":true}');

  /// Starts a node as the installer's copy runs its own: from a copy of the
  /// program outside the package, recorded in the real %APPDATA%'s pid file.
  /// The package reads that folder, so without a node folder of its own
  /// (localNodeDataDir) its start would take this node for one a crash left,
  /// and stop it.
  Future<Process> plantInstallersNode(String bundle) async {
    final dir = Directory.systemTemp.createTempSync('murmur-installers-node-');
    final program = File('$bundle\\$node').copySync('${dir.path}\\$node').path;
    final started = await Process.start(program, [
      '--daemon', '--spec', 'demo', '--data-dir', '${dir.path}\\data', //
      '--port', '127.0.0.1:0', '--rpc-port', '0',
    ]);
    started.stdout.drain<void>();
    started.stderr.drain<void>();
    _plantedPid
      ..createSync(recursive: true)
      ..writeAsStringSync('${started.pid}');
    print("the installer's copy's node: pid ${started.pid}, in ${_plantedPid.path}");
    return started;
  }

  /// After the first two checks: the installer's copy's node and its pid
  /// file were left alone, and what the package wrote went to its own folder.
  Future<void> checkApart(Process planted, Future<bool> Function(int pid) alive) async {
    print("== 4. beside the installer's copy");
    if (!await alive(planted.pid)) throw _Failed("the package stopped the installer's copy's node (its pid file)");
    if (!_plantedPid.existsSync() || _plantedPid.readAsStringSync().trim() != '${planted.pid}') {
      throw _Failed("the package changed the installer's copy's pid file ${_plantedPid.path}");
    }
    for (final path in [_settings.path, '${_data.path}\\node-store']) {
      if (FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound) {
        throw _Failed('the package wrote $path in the real %APPDATA%, not in its own folder');
      }
    }
    if (!File('$_private\\Murmur Association\\Murmur\\shared_preferences.json').existsSync()) {
      throw _Failed('the settings are missing from $_private: the package kept them elsewhere');
    }
    if (!Directory('$_private\\murmur-client\\node-store').existsSync()) {
      throw _Failed("the package's node kept no data in $_private\\murmur-client\\node-store");
    }
    print("its node ran in its own folder ($_private\\murmur-client\\node-store), the installer's was left "
        'running, and nothing was written in the real %APPDATA%');
  }

  /// A notification's click while the app is closed: Windows starts the
  /// app through the COM class the package declares (its activator), in the
  /// package, with the manifest's argument. Asked for here as Windows asks:
  /// by creating an object of that class.
  Future<void> toastActivation(String bundle) async {
    print("== 5. a notification's click starts the app");
    final manifest = File('$bundle\\AppxManifest.xml').readAsStringSync();
    final clsid = RegExp(r'ToastActivatorCLSID="([0-9a-fA-F-]{36})"').firstMatch(manifest)?.group(1);
    if (clsid == null) throw _Failed('the installed manifest declares no notification activator');
    final before = await _apps(bundle);
    final asking = await Process.start('powershell', [
      '-NoProfile', '-Command', "[Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]'$clsid'))",
    ]);
    asking.stdout.drain<void>();
    asking.stderr.drain<void>();
    try {
      final deadline = DateTime.now().add(const Duration(seconds: 60));
      while (true) {
        final started = (await _apps(bundle)).difference(before);
        if (started.isNotEmpty) {
          final line = await _commandLine(started.first);
          if (!line.contains('-ToastActivated')) throw _Failed('the app was started as "$line", not by the activator');
          print('activator $clsid started the app ${started.first}: $line');
          Process.killPid(started.first, ProcessSignal.sigkill);
          return;
        }
        if (DateTime.now().isAfter(deadline)) throw _Failed('asking for activator $clsid started no app');
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    } finally {
      asking.kill(ProcessSignal.sigkill);
    }
  }
}
