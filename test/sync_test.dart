// Syncing against a fake node serving a generated demo chain (see
// support/fake_node.dart), offline: a checkpoint start and its back-fill to
// genesis (Section 7.7), the back-fill resuming from the local copy, and a
// reorganization rebuilding the header history from the nearest mark.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/services/node_client.dart';

import 'support/fake_node.dart';

Future<void> _until(MurmurClient c, bool Function() done, {Duration timeout = const Duration(seconds: 60)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!done()) {
    if (c.error != null) fail('client error: ${c.error} (${c.error!.cause} ${c.error!.detail})');
    if (DateTime.now().isAfter(deadline)) fail('timed out');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<MurmurClient> _synced(FakeNode node, MurmurClient client) async {
  await client.connect('127.0.0.1', node.port);
  await _until(client, () => client.state == LinkState.live && client.height == node.chain.length);
  return client;
}

void main() {
  // More than one back-fill batch (2,000 headers) below the checkpoint.
  late final List<BlockHeader> chain;
  late final Checkpoint cp;
  setUpAll(() {
    chain = demoChain(2600);
    cp = Checkpoint(2570, chain[2569].id);
  });

  Future<FakeNode> serve(List<BlockHeader> headers) async {
    final node = await FakeNode.bind(InternetAddress.loopbackIPv4, 0, chain: headers);
    addTearDown(node.close);
    return node;
  }

  MurmurClient client({Checkpoint? checkpoint, MemoryCache? cache}) {
    final c = MurmurClient(checkpoint: checkpoint)..useCache(cache);
    addTearDown(c.dispose);
    return c;
  }

  test('starts from a checkpoint, checks back to genesis, and stores the back-fill batch by batch', () async {
    final node = await serve(chain);
    final cache = MemoryCache();
    final c = await _synced(node, client(checkpoint: cp, cache: cache));
    expect(c.headerAt(cp.height)!.id, cp.hash);
    expect(node.headersServedFrom.first, cp.height + 1, reason: 'the headers after the checkpoint come first');
    await _until(c, () => c.checkingFromCheckpoint == null);
    expect(c.headerAt(1)!.id, chain.first.id);
    expect(c.headerAt(2000)!.id, chain[1999].id);
    // The first batch was stored before the back-fill joined.
    expect(cache.saves, contains((1, 2000)));
    expect(cache.headers.length, chain.length, reason: 'the joined chain is stored');
  });

  test('a checkpoint that is not on the chain stops the client', () async {
    final node = await serve(chain);
    final c = client(checkpoint: Checkpoint(cp.height, '00' * 32));
    await c.connect('127.0.0.1', node.port);
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (c.error == null && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    final kind = c.error?.kind == LinkErrorKind.syncFailed ? c.error?.cause?.kind : c.error?.kind;
    expect(kind, LinkErrorKind.checkpointMismatch);
  });

  test('an interrupted back-fill resumes after the headers in the local copy', () async {
    final node = await serve(chain);
    // What an interrupted back-fill leaves: the first 500 headers.
    final cache = MemoryCache(chain.take(500).toList());
    var fromCheckpoint = false;
    final c = client(checkpoint: cp, cache: cache);
    c.addListener(() => fromCheckpoint |= c.checkingFromCheckpoint != null);
    await _synced(node, c);
    await _until(c, () => c.checkingFromCheckpoint == null);
    expect(fromCheckpoint, isTrue, reason: 'started from the checkpoint, not from the stored headers');
    expect(node.headersServedFrom, contains(501), reason: 'resumed after the stored headers');
    expect(node.headersServedFrom, isNot(contains(1)), reason: 'headers 1 to 500 were not fetched again');
    expect(c.headerAt(500)!.id, chain[499].id);
    expect(c.headerAt(501)!.id, chain[500].id);
    expect(cache.headers.length, chain.length);
  });

  test('stored headers of another chain are dropped, and the back-fill starts over from genesis', () async {
    final node = await serve(chain);
    final other = demoChain(500, miner: 2);
    final c = client(checkpoint: cp, cache: MemoryCache(other));
    await _synced(node, c);
    await _until(c, () => c.checkingFromCheckpoint == null);
    expect(node.headersServedFrom, contains(1));
    expect(c.headerAt(1)!.id, chain.first.id);
    expect(c.headerAt(cp.height)!.id, cp.hash);
  });

  test('a reorganization rebuilds the header history from the nearest mark', () async {
    // From genesis (no checkpoint), past the mark at 1,024 and 2,048.
    final before = chain.sublist(0, 2100);
    final node = await serve(before);
    final c = await _synced(node, client());
    // A heavier fork from block 2,060: the client rolls back to it, rebuilds
    // the history through it from the mark at 2,048, and checks every new
    // header's history root against it.
    final fork = demoChain(2130, miner: 3, after: before, forkAt: 2060);
    node.switchTo(fork);
    await _until(c, () => c.height == 2130 && c.headerAt(2130)?.id == fork.last.id);
    expect(c.headerAt(2060)!.id, before[2059].id);
    expect(c.headerAt(2061)!.id, fork[2060].id);
    expect(c.headerAt(2061)!.id, isNot(before[2060].id));
    // A second reorganization, below the newest mark, uses the one before.
    final deeper = demoChain(2160, miner: 4, after: fork, forkAt: 2040);
    node.switchTo(deeper);
    await _until(c, () => c.height == 2160 && c.headerAt(2160)?.id == deeper.last.id);
    expect(c.headerAt(2041)!.id, deeper[2040].id);
  });
}
