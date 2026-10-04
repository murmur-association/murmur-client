// Integration tests against a running node of this protocol version. Skipped unless
// MURMUR_NODE is set, e.g.:
//
//   murmur-node --spec demo --mine-to <address>
//   MURMUR_NODE=127.0.0.1:7878 MURMUR_SEED=<a funded key file's hex> flutter test test/live_node_test.dart
//
// With MURMUR_SEED (a funded wallet, such as the one the node mines to), it
// also sends transactions and waits for them to be mined.

// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/protocol/invite.dart';
import 'package:murmur_client/services/chain_cache_io.dart';
import 'package:murmur_client/services/invitations.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/storage.dart' show InviteRecord;

final _node = Platform.environment['MURMUR_NODE'];
final _seed = Platform.environment['MURMUR_SEED'];
final _skip = _node == null ? 'set MURMUR_NODE=host:port to run' : false;

Future<void> _until(MurmurClient c, bool Function() done, {Duration timeout = const Duration(seconds: 60)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!done()) {
    if (c.error != null) fail('client error: ${c.error}');
    if (DateTime.now().isAfter(deadline)) fail('timed out');
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

Future<MurmurClient> _connected({MurmurClient? client}) async {
  final parts = _node!.split(':');
  final c = client ?? MurmurClient();
  await c.connect(parts[0], int.parse(parts[1]));
  await _until(c, () => c.state == LinkState.live && c.height > 0);
  return c;
}

int _issuedThrough(MurmurClient c, int height) {
  var issued = 0;
  for (var h = 1; h <= height; h++) {
    issued += c.network!.subsidyAt(h);
  }
  return issued;
}

/// Asks the node's control port (MURMUR_CTL, e.g. 127.0.0.1:17879) for a
/// checkpoint at `height`, as a release would with `ctl checkpoint`: the
/// test's own doing; the client never uses the control port.
Future<Checkpoint> _checkpointAt(int height) async {
  final parts = Platform.environment['MURMUR_CTL']!.split(':');
  final socket = await Socket.connect(parts[0], int.parse(parts[1]));
  socket.write('checkpoint $height\n');
  await socket.flush();
  final reply = await socket.cast<List<int>>().transform(const SystemEncoding().decoder).join();
  socket.destroy();
  final words = reply.trim().split(RegExp(r'\s+'));
  return Checkpoint(int.parse(words[1]), words[2]);
}

void main() {
  test('starts from a checkpoint, then checks the headers back to genesis', () async {
    final probe = await _connected();
    final height = probe.height;
    probe.dispose();
    expect(height, greaterThan(60), reason: 'let the node mine a little first');
    final cp = await _checkpointAt(height - 30);

    final started = DateTime.now();
    final client = await _connected(client: MurmurClient(checkpoint: cp));
    addTearDown(client.dispose);
    final usableAfter = DateTime.now().difference(started);
    // Usable from the checkpoint: its context and what follows are known,
    // the first headers not yet.
    expect(client.headerAt(cp.height)!.id, cp.hash);
    await _until(client, () => client.provenIssued != null);
    // Then checked back to genesis in the background.
    await _until(client, () => client.checkingFromCheckpoint == null);
    expect(client.headerAt(1), isNotNull);
    expect(client.headerAt(cp.height)!.id, cp.hash);
    print('from checkpoint ${cp.height}: usable after ${usableAfter.inMilliseconds} ms, '
        'checked back to genesis after ${DateTime.now().difference(started).inMilliseconds} ms');

    // A checkpoint that isn't on the node's chain stops the client.
    final wrong = MurmurClient(checkpoint: Checkpoint(cp.height, '00' * 32));
    addTearDown(wrong.dispose);
    final parts = _node!.split(':');
    await wrong.connect(parts[0], int.parse(parts[1]));
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (wrong.error == null && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final kind = wrong.error?.kind == LinkErrorKind.syncFailed ? wrong.error?.cause?.kind : wrong.error?.kind;
    expect(kind, LinkErrorKind.checkpointMismatch);
  }, skip: _node == null || Platform.environment['MURMUR_CTL'] == null ? 'set MURMUR_NODE and MURMUR_CTL to run' : false,
      timeout: const Timeout(Duration(minutes: 2)));

  test('proves state, finds an address through filters, without the chain', () async {
    final started = DateTime.now();
    final client = await _connected();
    addTearDown(client.dispose);
    final headersAfter = DateTime.now().difference(started);

    // The supply and the burn pool, proven against the tip's state root.
    await _until(client, () => client.provenIssued != null && client.provenPool != null);
    final provedAfter = DateTime.now().difference(started);
    expect(client.provenIssued, _issuedThrough(client, client.headerAt(client.height)!.height));
    expect(client.circulating! + client.provenPool!, client.provenIssued);

    // The tip's miner: a balance and a nonce, proven.
    final miner = toHex(client.headerAt(client.height)!.miner);
    await _until(client, () => client.account(miner) != null);
    final account = client.account(miner)!;
    expect(account.balance, greaterThan(0));

    // Its history through filters: complete once every matching block is in.
    client.watchAddress(miner);
    await _until(client, () => !client.historyPending(miner), timeout: const Duration(minutes: 2));
    final historyAfter = DateTime.now().difference(started);
    print('${client.network!.id} at ${client.height}: headers ${headersAfter.inMilliseconds} ms, '
        'proofs ${provedAfter.inMilliseconds} ms, miner history ${historyAfter.inMilliseconds} ms '
        '(${client.fetchedBlocks} of ${client.height} blocks fetched); '
        'miner balance ${account.balance}, nonce ${account.nonce}');
    expect(client.fetchedBlocks, lessThanOrEqualTo(client.height));
    // (A short chain fits in the first newest-first batches anyway.)
    if (client.height > 4 * 128) {
      expect(client.complete, isFalse, reason: 'no local copy: the chain is not replayed');
    }

    final fees = await client.feeInfo();
    print('fees: ${fees.source.name}, suggested ${fees.suggested(264)} without content, ${fees.pending} pending');
    expect(fees.suggested(264), greaterThanOrEqualTo(1));
  }, skip: _skip, timeout: const Timeout(Duration(minutes: 3)));

  test('with a local copy, counts the chain and agrees with the state root; a second session starts from it', () async {
    final dir = await Directory.systemTemp.createTemp('murmur-cache-test');
    addTearDown(() => dir.delete(recursive: true));

    final started = DateTime.now();
    final first = await _connected(client: MurmurClient()..useCache(FileChainCache(dir)));
    // The client computes the state root at the counted tip and compares it
    // with the header's; a mismatch would be a client error.
    await _until(first, () => first.complete, timeout: const Duration(minutes: 3));
    final completeAfter = DateTime.now().difference(started);
    final height = first.height;
    first.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 500)); // last cache writes
    print('first session: all $height blocks counted and the state root checked after '
        '${completeAfter.inMilliseconds} ms');

    final again = DateTime.now();
    final second = await _connected(client: MurmurClient()..useCache(FileChainCache(dir)));
    addTearDown(second.dispose);
    await _until(second, () => second.complete && second.height >= height);
    print('second session: complete after ${DateTime.now().difference(again).inMilliseconds} ms');
    expect(second.fetchedBlocks, second.height);
    expect(second.error, isNull);
  }, skip: _skip, timeout: const Timeout(Duration(minutes: 5)));

  test('sends with proven nonces and gets transactions mined', () async {
    final client = await _connected();
    addTearDown(client.dispose);
    final wallet = await MurmurWallet.fromSeed(fromHex(_seed!));
    final me = wallet.addressHex;
    await _until(client, () => client.availableTo(me) != null);
    final start = client.account(me)!;
    print('wallet ${me.substring(0, 12)}… balance ${start.balance}, nonce ${start.nonce}');
    expect(start.balance, greaterThan(100), reason: 'MURMUR_SEED must be funded');

    final text = 'hello from the flutter client ${DateTime.now().toIso8601String()}';
    final orphan = await client.submit(
        wallet: wallet, kind: TxKind.orphan, amount: orphanBurn(2), fee: 2, message: MurmurClient.encodeText(text));
    final recipient = await MurmurWallet.generate();
    final raw = await client.submit(wallet: wallet, kind: TxKind.raw, to: recipient.address, amount: 5, fee: 1);
    expect((orphan.nonce, raw.nonce), (start.nonce, start.nonce + 1), reason: 'the second follows the pending first');
    // The Threads tab's fixed view shows your own new thread at once, and
    // keeps it once mined above the snapshot.
    final snapshot = client.height;
    expect(client.threads(upTo: snapshot).first.root.tx.id, orphan.id);
    await _until(client, () => client.statusOf(raw.id) != null);
    expect(client.statusOf(raw.id)!.code, TxStatusCode.accepted, reason: client.statusOf(raw.id)!.reason);

    await _until(client, () =>
        (client.lookupTx(orphan.id)?.confirmed ?? false) && (client.lookupTx(raw.id)?.confirmed ?? false));
    final mined = client.lookupTx(orphan.id)!;
    expect(String.fromCharCodes(messageOf(mined.content!)), text);
    expect(mined.height, greaterThan(snapshot));
    expect(client.threads(upTo: snapshot).any((t) => t.root.tx.id == orphan.id), isTrue);
    await _until(client, () => (client.account(recipient.addressHex)?.balance ?? 0) == 5);
    await _until(client, () => (client.account(me)?.nonce ?? 0) == start.nonce + 2);
    print('orphan mined in block ${mined.height}, transfer in block ${client.lookupTx(raw.id)!.height}');

    // Threads: a reply chain and a flag, proven not flagged before.
    Uint8List utf(String s) => MurmurClient.encodeText(s);
    final older = await client.submit(
        wallet: wallet, kind: TxKind.orphan, amount: orphanBurn(1), fee: 1, message: utf('older thread $text'));
    await _until(client, () => client.lookupTx(older.id)?.confirmed ?? false);
    final reply = await client.submit(
        wallet: wallet, kind: TxKind.reply, to: older.from, amount: 1, fee: 1, message: utf('a reply'), reference: older.id);
    await _until(client, () => client.provenFlagged(me, older.id) != null);
    final flag = await client.submit(wallet: wallet, kind: TxKind.flag, fee: 1, reference: older.id);
    expect(
        () => client.submit(wallet: wallet, kind: TxKind.flag, fee: 1, reference: older.id),
        throwsA(isA<TxProblem>().having((p) => p.kind, 'kind', TxProblemKind.alreadyFlagged)),
        reason: 'one flag per address per message');
    await _until(client, () =>
        (client.lookupTx(reply.id)?.confirmed ?? false) && (client.lookupTx(flag.id)?.confirmed ?? false));
    await _until(client, () => client.provenFlagged(me, older.id) == true);
    final thread = client.threads().firstWhere((t) => t.root.tx.id == older.id);
    expect((thread.replies, thread.flags), (1, 1));
    // That flag was the author's own: a retraction. Its text is deleted here
    // and never fetched again; the reply keeps its own.
    final withdrawn = client.lookupTx(older.id)!;
    expect(client.contentWithdrawn(withdrawn.tx), isTrue);
    expect(client.liveContent(withdrawn), isNull);
    expect(client.contentExpected(withdrawn.tx), isFalse);
    expect(client.liveContent(client.lookupTx(reply.id)!), isNotNull);
  }, skip: _node == null || _seed == null ? 'set MURMUR_NODE and MURMUR_SEED to run' : false,
      timeout: const Timeout(Duration(minutes: 3)));

  test('invitations: funded cards are claimed by a new wallet, or taken back', () async {
    final client = await _connected();
    addTearDown(client.dispose);
    final inviter = await MurmurWallet.fromSeed(fromHex(_seed!));
    await _until(client, () => client.availableTo(inviter.addressHex) != null);
    final costs = invitationCosts(await client.feeInfo());
    final kept = <InviteRecord>[];
    final cards = await createInvitations(
      client: client,
      wallet: inviter,
      keep: (r) async => kept.addAll(r),
      count: 2,
      perCard: costs.perCard,
      fundingFee: costs.fundingFee,
    );
    expect(kept, hasLength(2), reason: 'the keys are kept before the cards are funded');
    final invites = [for (final c in cards) Invite.parse(c.code)!];
    final addresses = [for (final i in invites) (await cardWallet(i)).addressHex];
    await _until(client, () => addresses.every((a) => (client.account(a)?.balance ?? 0) == costs.perCard));
    print('2 cards funded with ${costs.perCard} each');

    // A newcomer claims the first into a brand-new wallet.
    final newcomer = await MurmurWallet.generate();
    await sweepInvitation(client: client, invite: invites[0], to: newcomer.address);
    // The inviter takes back the second.
    await sweepInvitation(client: client, invite: invites[1], to: inviter.address);
    await _until(client, () => (client.account(newcomer.addressHex)?.balance ?? 0) > 0);
    await _until(client, () => addresses.every((a) => client.account(a)?.balance == 0));
    expect(client.account(newcomer.addressHex)!.balance, costs.perCard - costs.claimFee);
    expect(inviteState(client, cards[0], addresses[0]), InviteState.claimed);
    expect(inviterOf(client, addresses[0]), inviter.addressHex);
    print('claimed ${client.account(newcomer.addressHex)!.balance} into a new wallet: '
        '${costs.perCard - costs.claimFee} = five threads');
  }, skip: _node == null || _seed == null ? 'set MURMUR_NODE and MURMUR_SEED to run' : false,
      timeout: const Timeout(Duration(minutes: 3)));
}
