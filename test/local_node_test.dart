// The app's own node: the options it's started with, reading the port it
// reports, and (with the pinned murmur-node release, see support/test_node.dart) running a
// real one and syncing a client from it.

// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/services/local_node.dart';
import 'package:murmur_client/services/local_node_io.dart';
import 'package:murmur_client/services/local_node_link.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/brand.dart';
import 'package:murmur_client/ui/chain_tab.dart';
import 'package:murmur_client/ui/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_node.dart';

void main() {
  test('options: short-retention, pruned, local-only, and the wallet kept and paid only when given', () {
    final bare = localNodeArgs(dataDir: '/d', spec: 'whitepaper');
    expect(bare, containsAllInOrder(['--port', '127.0.0.1:0']));
    expect(bare, containsAll(['--prune-content', '--prune-retracted', '--prune-blocks', '--daemon']));
    expect(bare, isNot(contains('--checkpoint')), reason: 'none given');
    // The app's own checkpoint, as the node takes one; never a malformed one.
    const at = Checkpoint(2500, '000002cee4bc1f9e4da32c87c389b9144cba8df6bc0b1f1f34e955f11e0fb208');
    expect(localNodeArgs(dataDir: '/d', checkpoint: at), containsAllInOrder(['--checkpoint', '2500:${at.hash}']));
    expect(localNodeArgs(dataDir: '/d', checkpoint: const Checkpoint(0, 'x')), isNot(contains('--checkpoint')));
    expect(localNodeNetwork.checkpoint, NetworkInfo.whitepaper.checkpoint, reason: 'the testnet unless built for demo');
    expect(bare, isNot(contains('--keep-author')));
    expect(bare, isNot(contains('--mine-to')));
    // Mining needs an address to pay.
    expect(localNodeArgs(dataDir: '/d', mine: true), isNot(contains('--mine-to')));

    final a = 'ab' * 32;
    final full = localNodeArgs(dataDir: '/d', address: a, mine: true, cpuPct: 250);
    expect(full, containsAllInOrder(['--keep-author', a]));
    expect(full, containsAllInOrder(['--mine-to', a, '--mine-cpu', '100']));
    expect(localNodeArgs(dataDir: '/d', address: a), isNot(contains('--mine-to')));

    // The graphics card: only with mining, which the node needs for it.
    expect(localNodeArgs(dataDir: '/d', address: a, mine: true, gpu: true), contains('--gpu'));
    expect(full, isNot(contains('--gpu')), reason: 'off unless asked');
    expect(localNodeArgs(dataDir: '/d', address: a, gpu: true), isNot(contains('--gpu')));
    expect(localNodeArgs(dataDir: '/d', mine: true, gpu: true), isNot(contains('--gpu')), reason: 'no address to pay');
    // A Microsoft Store build never mines, whatever the settings say; the
    // rest of the node (its wallet's messages kept) is the same.
    final store = localNodeArgs(dataDir: '/d', address: a, mine: true, gpu: true, allowMining: false);
    expect(store, isNot(contains('--mine-to')));
    expect(store, isNot(contains('--gpu')));
    expect(store, containsAllInOrder(['--keep-author', a]));
    expect(localNodeMiningAllowed, isTrue, reason: 'a build without MURMUR_STORE mines when asked');
  });

  test("a Store build's node keeps a data folder of its own, apart from the installer's", () {
    // Both copies may be installed; the package reads the real folder
    // merged with its own, so sharing one would let it stop the other's node.
    expect(localNodeDataDir(r'C:\a', r'\', store: false), r'C:\a\murmur-client\node');
    expect(localNodeDataDir(r'C:\a', r'\', store: true), r'C:\a\murmur-client\node-store');
  });

  test("how far the node has come is read from its output's stable lines", () {
    // A start from the checkpoint, its catching up, and the check from genesis
    // behind it, in the node's words (node v0.16.0, README and fast_start.rs).
    final lines = [
      '[net] listening for peers on 127.0.0.1:49272',
      '[start] starting from the checkpoint at height 2500 (000002cee4bc1f9e)',
      '[start] started at height 16883: its state, from a peer, is the one its block commits to, on headers '
          'checked from the checkpoint; checking the chain from the genesis block in the background',
      '[sync] at height 16900 of 17000 from 1.2.3.4:7878\r',
      '[check] checked the chain from the genesis block to height 4000 of 16883',
      '[sync] synced from 1.2.3.4:7878 to height 17000',
      '[chain] accepted block at height 17001 (3 tx)',
      '[check] checked every block from the genesis block to height 16883: the checkpoint and the state this '
          'node started from are the chain\'s',
    ];
    final seen = <NodeSync>[];
    var sync = const NodeSync();
    for (final line in lines) {
      sync = sync.after(line);
      seen.add(sync);
    }
    expect(seen, [
      const NodeSync(),
      const NodeSync(fromCheckpoint: true),
      const NodeSync(history: (0, 16883)),
      const NodeSync(catchingUp: (16900, 17000), history: (0, 16883)),
      const NodeSync(catchingUp: (16900, 17000), history: (4000, 16883)),
      const NodeSync(history: (4000, 16883)),
      const NodeSync(history: (4000, 16883)),
      const NodeSync(),
    ]);

    // No peer could start it: it syncs from genesis like any node.
    final fallback = const NodeSync(fromCheckpoint: true)
        .after('[start] no peer could start this node from the checkpoint; syncing from the genesis block instead');
    expect(fallback, const NodeSync());
    // A restart, or another peer, checks from genesis again.
    expect(const NodeSync(history: (9000, 16883)).after('[check] checking the chain from the genesis block to height 16883 again'),
        const NodeSync(history: (0, 16883)));
  });

  test('a peer on a newer protocol is read from the output: the app needs updating', () {
    // The node's own words (v0.16.0), with the address it dropped.
    expect(newerPeerProtocol('[net] peer 203.0.113.7:7878 speaks protocol v18 (we speak v17); disconnecting'), 18);
    expect(newerPeerProtocol('[net] peer [2001:db8::1]:7878 speaks protocol v19 (we speak v17); disconnecting\r'), 19);
    // An older peer is its own problem, not this node's.
    expect(newerPeerProtocol('[net] peer 203.0.113.7:7878 speaks protocol v16 (we speak v17); disconnecting'), isNull);
    expect(newerPeerProtocol('[net] peer 203.0.113.7:7878 is on a different network; disconnecting'), isNull);
    expect(newerPeerProtocol('[sync] at height 12 of 40 from 203.0.113.7:7878'), isNull);
  });

  test('what the node says of its GPU miner is read from its output', () {
    expect(gpuMiningOf('[gpu] mining on NVIDIA GeForce RTX 3060'),
        const GpuMining(GpuMiningState.mining, device: 'NVIDIA GeForce RTX 3060'));
    expect(gpuMiningOf('[gpu] mining on the GPU\r'), const GpuMining(GpuMiningState.mining));
    expect(
        gpuMiningOf("[gpu] not available (murmur-miner isn't in murmur-node's folder); mining on the CPU"),
        const GpuMining(GpuMiningState.unavailable, reason: "murmur-miner isn't in murmur-node's folder"));
    // A reason with brackets of its own.
    expect(
        gpuMiningOf('[gpu] not available (no GPU with an OpenCL driver on this machine (none found)); mining on the CPU'),
        const GpuMining(GpuMiningState.unavailable, reason: 'no GPU with an OpenCL driver on this machine (none found)'));
    expect(gpuMiningOf('[gpu] murmur-miner stopped; starting it again'),
        const GpuMining(GpuMiningState.starting, reason: 'murmur-miner stopped'));
    for (final other in [
      '[net] listening for peers on 127.0.0.1:49272',
      '[miner] mined block 12',
      '[gpu] something new the app does not know',
      'mining on the GPU',
    ]) {
      expect(gpuMiningOf(other), isNull, reason: other);
    }
  });

  test('the listening port is read from the node\'s startup line', () {
    expect(listeningPort('[net] listening for peers on 127.0.0.1:49272'), 49272);
    expect(listeningPort('[net] listening for peers on 127.0.0.1:49272\r'), 49272);
    expect(listeningPort('[net] listening for websocket on 127.0.0.1:7880'), isNull);
    expect(listeningPort('[net] listening for peers on 0.0.0.0:7878'), isNull);
    expect(listeningPort('[rpc] control interface on 127.0.0.1:49273'), isNull);
  });

  test('the settings start, restart and stop the node, and nothing else: the client is left alone', () async {
    SharedPreferences.setMockInitialValues({});
    final node = _RecordingNode();
    final prefs = Preferences(), wallets = WalletController();
    // The link is given no client: it can't move one to the app's node.
    final link = LocalNodeLink(node: node, prefs: prefs, wallets: wallets);
    Future<void> settled() => Future<void>.delayed(Duration.zero);
    expect(node.calls, isEmpty, reason: 'off by default');

    await prefs.setRunLocalNode(true);
    await settled();
    expect(node.calls, hasLength(1));
    expect(node.calls.single, containsAll(['--prune-content', '--prune-retracted']));
    expect(node.calls.single, isNot(contains('--mine-to')));

    // A wallet: its own messages are kept. Mining: it's paid.
    final address = Uint8List(32)..fillRange(0, 32, 7);
    wallets.wallet = WalletId(address, Uint8List(32));
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    wallets.notifyListeners();
    await prefs.setLocalNodeMining(true);
    await settled();
    expect(node.calls, hasLength(3));
    expect(node.calls[1], containsAllInOrder(['--keep-author', '07' * 32]));
    expect(node.calls[2], containsAllInOrder(['--mine-to', '07' * 32]));

    // A change that asks for the same options doesn't restart it.
    await prefs.setStarredOnly(true);
    await settled();
    expect(node.calls, hasLength(3));

    // The graphics card: asked of a node that has its miner, never of one
    // that hasn't (it would refuse to start).
    await prefs.setLocalNodeGpu(true);
    await settled();
    expect(node.calls, hasLength(3), reason: 'no miner beside this node: nothing changes');
    node.canMineOnGpu = true;
    await prefs.setLocalNodeCpu(60);
    await settled();
    expect(node.calls, hasLength(4));
    expect(node.calls[3], containsAllInOrder(['--mine-cpu', '60', '--gpu']));
    await prefs.setLocalNodeGpu(false);
    await settled();
    expect(node.calls[4], isNot(contains('--gpu')));

    await prefs.setRunLocalNode(false);
    await settled();
    expect(node.calls.last, isNull, reason: 'stopped');
    await link.close();
  });

  testWidgets('the Chain tab says where the running node listens', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final node = _RecordingNode();
    final prefs = Preferences(), wallets = WalletController();
    final client = MurmurClient();
    addTearDown(client.dispose);
    await tester.pumpWidget(AppScope(
      client: client,
      wallets: wallets,
      prefs: prefs,
      localNode: node,
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ChainTab()),
      ),
    ));
    expect(find.textContaining('127.0.0.1'), findsNothing, reason: 'switched off');
    await prefs.setRunLocalNode(true);
    await node.start(const []);
    await tester.pump();
    expect(find.textContaining('127.0.0.1:49272'), findsOneWidget);

    // On a long chain the first start takes a while: the card shows it moving.
    final words = tester.element(find.byType(ChainTab)).l10n;
    expect(find.byType(LinearProgressIndicator), findsNothing, reason: 'at the tip');
    node.sync = const NodeSync(catchingUp: (16900, 17000), history: (4000, 16883));
    node.say(null);
    await tester.pump();
    expect(find.text(words.localNodeCatchingUp('16,900', '17,000')), findsOneWidget);
    expect(find.text(words.localNodeCheckingHistory('4,000', '16,883')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    node.sync = const NodeSync();
    node.say(null);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing);

    // Mining: the address it pays, in full, once there's a wallet to pay.
    final paid = '07' * 32;
    await prefs.setLocalNodeMining(true);
    await tester.pump();
    expect(find.text(paid), findsNothing, reason: 'no wallet');
    wallets.wallet = WalletId(Uint8List(32)..fillRange(0, 32, 7), Uint8List(32));
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    wallets.notifyListeners();
    await tester.pump();
    expect(find.text(paid), findsOneWidget);
    // The graphics card: offered only where the node has its miner.
    final l = tester.element(find.byType(ChainTab)).l10n;
    expect(find.text(l.localNodeGpu), findsNothing);
    node.canMineOnGpu = true;
    node.say(null);
    await tester.pump();
    expect(find.text(l.localNodeGpu), findsOneWidget);
    expect(prefs.localNodeGpu, isFalse, reason: 'off until chosen');
    final gpuSwitch =
        find.descendant(of: find.widgetWithText(SwitchListTile, l.localNodeGpu), matching: find.byType(Switch));
    await tester.ensureVisible(gpuSwitch);
    await tester.pumpAndSettle();
    await tester.tap(gpuSwitch);
    await tester.pump();
    expect(prefs.localNodeGpu, isTrue);
    // What the node says of the card, as it changes.
    bool shows(String text) => find.byWidgetPredicate((w) => w is Emphasized && w.text == text).evaluate().isNotEmpty;
    node.say(const GpuMining(GpuMiningState.starting));
    await tester.pump();
    expect(shows(l.localNodeGpuStarting), isTrue);
    node.say(const GpuMining(GpuMiningState.mining, device: 'NVIDIA GeForce RTX 3060'));
    await tester.pump();
    expect(shows(l.localNodeGpuMining('NVIDIA GeForce RTX 3060')), isTrue);
    expect(shows(l.localNodeGpuStarting), isFalse);
    // Not usable: the switch stays on, mining goes on with the processor,
    // and the node's own words are a detail.
    node.say(const GpuMining(GpuMiningState.unavailable, reason: 'no GPU with an OpenCL driver on this machine'));
    await tester.pump();
    expect(shows(l.localNodeGpuUnavailable), isTrue);
    expect(find.text(l.localNodeGpuDetail('no GPU with an OpenCL driver on this machine')), findsOneWidget);
    expect(prefs.localNodeGpu, isTrue);

    await prefs.setLocalNodeMining(false);
    await tester.pump();
    expect(find.text(paid), findsNothing);
    expect(find.text(l.localNodeGpu), findsNothing, reason: 'no mining, no card');

    await node.stop();
    await tester.pump();
    expect(find.textContaining('127.0.0.1'), findsNothing);
  });

  test('a real node asked to mine on the graphics card says whether it does, in words the app reads', () async {
    final dir = await Directory.systemTemp.createTemp('murmur-local-node-gpu');
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        // Windows may still hold a file for a moment.
      }
    });
    final node = ProcessLocalNode(binary: nodeBinary, dataDir: dir.path);
    expect(node.canMineOnGpu, isTrue, reason: 'the pinned release ships murmur-miner beside the node');
    final wallet = await MurmurWallet.generate();
    await node.start(localNodeArgs(dataDir: dir.path, spec: 'demo', address: wallet.addressHex, mine: true, cpuPct: 5, gpu: true));
    addTearDown(node.stop);
    expect(node.gpu, const GpuMining(GpuMiningState.starting));
    // Whatever this machine has: the card mines, or it can't be used and
    // the node says why. Either way the node runs.
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (node.gpu?.state == GpuMiningState.starting || node.state != LocalNodeState.running) {
      if (node.state == LocalNodeState.failed) fail('node failed: ${node.problem}');
      if (DateTime.now().isAfter(deadline)) fail('the node said nothing of its GPU miner: ${node.gpu}');
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final gpu = node.gpu!;
    print('GPU mining here: $gpu');
    if (gpu.state == GpuMiningState.unavailable) expect(gpu.reason, isNotEmpty);
    await node.stop();
    expect(node.gpu, isNull);
  }, skip: nodeSkip, timeout: const Timeout(Duration(minutes: 2)));

  test('runs a real node, syncs a client from it, and stops it', () async {
    final dir = await Directory.systemTemp.createTemp('murmur-local-node');
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        // Windows may still hold a file for a moment.
      }
    });
    final node = ProcessLocalNode(binary: nodeBinary, dataDir: dir.path);
    final wallet = await MurmurWallet.generate();
    await node.start(localNodeArgs(dataDir: dir.path, spec: 'demo', address: wallet.addressHex, mine: true, cpuPct: 50));
    addTearDown(node.stop);
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (node.state != LocalNodeState.running) {
      if (node.state == LocalNodeState.failed) fail('node failed: ${node.problem}');
      if (DateTime.now().isAfter(deadline)) fail('node did not start');
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    print('node listening on 127.0.0.1:${node.port}');

    final client = MurmurClient();
    addTearDown(client.dispose);
    await client.connect('127.0.0.1', node.port!);
    final synced = DateTime.now().add(const Duration(seconds: 60));
    while (!(client.state == LinkState.live && client.height >= 3)) {
      if (client.error != null) fail('client error: ${client.error}');
      if (DateTime.now().isAfter(synced)) fail('client did not sync');
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    expect(client.network?.id, 'murmur-demo-15');
    print('client synced to height ${client.height} from the app\'s own node');

    await node.stop();
    expect(node.state, LocalNodeState.stopped);
    expect(node.port, isNull);
  }, skip: nodeSkip,
      timeout: const Timeout(Duration(minutes: 2)));
}
/// A node that only records what it's asked: the options of each start, and
/// null for each stop.
class _RecordingNode extends LocalNode {
  _RecordingNode() : super.base();

  final calls = <List<String>?>[];

  @override
  LocalNodeState state = LocalNodeState.stopped;

  @override
  int? get port => state == LocalNodeState.running ? 49272 : null;

  @override
  String? get problem => null;

  @override
  String get dataDir => '/d';

  @override
  bool canMineOnGpu = false;

  @override
  GpuMining? gpu;

  @override
  NodeSync sync = const NodeSync();

  @override
  int? peersNewer;

  /// The node reports on its GPU miner.
  void say(GpuMining? status) {
    gpu = status;
    notifyListeners();
  }

  @override
  Future<void> start(List<String> args) async {
    calls.add(args);
    state = LocalNodeState.running;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    if (state == LocalNodeState.stopped) return;
    calls.add(null);
    state = LocalNodeState.stopped;
    notifyListeners();
  }
}
