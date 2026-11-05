// The app's own node as a child process (Windows, Linux, macOS). The binary
// is `murmur-node` (`.exe` on Windows) next to the app's executable, put
// there by tool/bundle_node.dart; MURMUR_NODE_BIN overrides it (tests). The
// data folder is murmur-client/node in the user's application data folder,
// beside the chain cache.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'chain_cache_io.dart' show chainCacheBase;
import 'local_node.dart';

LocalNode createLocalNode() {
  final desktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  return ProcessLocalNode(binary: desktop ? _findBinary() : null, dataDir: _dataDir());
}

String? _findBinary() {
  final name = Platform.isWindows ? 'murmur-node.exe' : 'murmur-node';
  final override = Platform.environment['MURMUR_NODE_BIN'];
  final candidates = [
    if (override != null) override,
    '${File(Platform.resolvedExecutable).parent.path}${Platform.pathSeparator}$name',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }
  return null;
}

String _dataDir() {
  final env = Platform.environment;
  // Another folder, for tests of the app that must leave the user's alone.
  final override = env['MURMUR_NODE_DATA'];
  if (override != null) return override;
  // Beside the chain cache, wherever that goes (MURMUR_DATA_HOME included).
  final base = chainCacheBase(phone: false, env: env, temp: Directory.systemTemp.path);
  final sep = Platform.pathSeparator;
  return '$base${sep}murmur-client${sep}node';
}

/// A node run as a child process (public so tests can point it anywhere).
class ProcessLocalNode extends LocalNode {
  ProcessLocalNode({required this.binary, required this.dataDir}) : super.base() {
    _state = binary == null ? LocalNodeState.unavailable : LocalNodeState.stopped;
  }

  /// The node program, or null when there's none.
  final String? binary;

  @override
  final String dataDir;

  late LocalNodeState _state;
  Process? _process;
  int? _port;
  String? _problem;
  GpuMining? _gpu;
  NodeSync _sync = const NodeSync();
  bool _stopping = false;

  @override
  GpuMining? get gpu => _gpu;

  @override
  NodeSync get sync => _sync;

  // murmur-miner, which the node runs from its own folder.
  @override
  bool get canMineOnGpu {
    final bin = binary;
    if (bin == null) return false;
    final miner = Platform.isWindows ? 'murmur-miner.exe' : 'murmur-miner';
    return File('${File(bin).parent.path}${Platform.pathSeparator}$miner').existsSync();
  }

  @override
  LocalNodeState get state => _state;

  @override
  int? get port => _port;

  @override
  String? get problem => _problem;

  File get _pidFile => File('$dataDir${Platform.pathSeparator}app-node.pid');

  void _set(LocalNodeState s) {
    _state = s;
    notifyListeners();
  }

  @override
  Future<void> start(List<String> args) async {
    final bin = binary;
    if (bin == null) return;
    await stop();
    _problem = null;
    _port = null;
    // Asked to mine on the card: starting, until the node says more.
    _gpu = args.contains('--gpu') ? const GpuMining(GpuMiningState.starting) : null;
    _sync = const NodeSync();
    _set(LocalNodeState.starting);
    await Directory(dataDir).create(recursive: true);
    // A node left running by a session that crashed would share this data
    // folder: stop it first.
    await _stopStale();
    final Process process;
    try {
      process = await Process.start(bin, args);
    } on ProcessException catch (e) {
      _problem = e.message;
      _set(LocalNodeState.failed);
      return;
    }
    _process = process;
    _stopping = false;
    await _pidFile.writeAsString('${process.pid}');
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (!identical(_process, process)) return;
      final p = listeningPort(line);
      if (p != null) {
        _port = p;
        _set(LocalNodeState.running);
      }
      final sync = _sync.after(line);
      if (sync != _sync) {
        _sync = sync;
        notifyListeners();
      }
      final gpu = _gpu == null ? null : gpuMiningOf(line);
      if (gpu != null && gpu != _gpu) {
        _gpu = gpu;
        notifyListeners();
      }
    });
    process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (line.trim().isNotEmpty) _problem = line.trim();
    });
    unawaited(process.exitCode.then((_) => _exited(process, asked: _stopping)));
  }

  /// Records that `process` ended: stopped if asked to, failed otherwise.
  void _exited(Process process, {required bool asked}) {
    if (!identical(_process, process)) return;
    _process = null;
    _port = null;
    _gpu = null;
    _sync = const NodeSync();
    try {
      _pidFile.deleteSync();
    } on FileSystemException {
      // Already gone.
    }
    _set(asked ? LocalNodeState.stopped : LocalNodeState.failed);
  }

  @override
  Future<void> stop() async {
    final process = _process;
    if (process == null) return;
    _stopping = true;
    process.kill();
    try {
      await process.exitCode.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      await process.exitCode;
    }
    _exited(process, asked: true);
  }

  /// Stops a node left running in this data folder by a session that
  /// crashed.
  Future<void> _stopStale() => stopLeftNode(dataDir);
}

/// Stops the node recorded in `dataDir`'s pid file, if that process is
/// still a murmur-node (the pid may have been reused by something else
/// since), and removes the file. A starting app does it, and so does the
/// acceptance runner after a run (tool/acceptance_test.dart), for a node a
/// failed test never switched off.
Future<void> stopLeftNode(String dataDir) async {
  final pidFile = File('$dataDir${Platform.pathSeparator}app-node.pid');
  final int? pid;
  try {
    pid = int.tryParse((await pidFile.readAsString()).trim());
    await pidFile.delete();
  } on FileSystemException {
    return;
  }
  if (pid == null || !await _isNodeProcess(pid)) return;
  Process.killPid(pid);
  await Future<void>.delayed(const Duration(seconds: 1));
}

Future<bool> _isNodeProcess(int pid) async {
  try {
    if (Platform.isWindows) {
      final r = await Process.run('tasklist', ['/FI', 'PID eq $pid', '/FO', 'CSV', '/NH']);
      return '${r.stdout}'.toLowerCase().contains('murmur-node');
    }
    if (Platform.isLinux) {
      final cmdline = File('/proc/$pid/cmdline');
      return await cmdline.exists() && (await cmdline.readAsString()).contains('murmur-node');
    }
    final r = await Process.run('ps', ['-p', '$pid', '-o', 'comm=']);
    return '${r.stdout}'.contains('murmur-node');
  } on ProcessException {
    return false;
  }
}
