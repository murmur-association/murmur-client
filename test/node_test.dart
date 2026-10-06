// The client against the real node: the pinned murmur-node release
// (tool/node_release.dart, fetched with `dart run tool/bundle_node.dart
// --for-tests`), on demo chains the node builds itself (`murmur-node
// demo-chain`, through support/test_node.dart). Nothing to set up and
// nothing to wait for: no running node, no mining before the tests.

// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/invite.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/services/invitations.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/storage.dart' show InviteRecord;

import 'support/client_checks.dart';
import 'support/memory_cache.dart';
import 'support/test_node.dart';

void main() {
  // The wallet every built block pays, so it has tokens to send.
  late final MurmurWallet miner;
  setUpAll(() async => miner = await MurmurWallet.generate());

  Future<Uint8List> someoneElse() async => (await MurmurWallet.generate()).address;

  // Long enough for two back-fill batches (2,000 headers each) below the
  // checkpoint at 2,570.
  Future<TestNode> long() async {
    final node = await TestNode.build(2600, mineTo: miner.address);
    await node.start();
    return node;
  }

  Checkpoint checkpointOf(TestNode node) => Checkpoint(2570, node.hashAt(2570));

  /// The headers a client stores from `node` (from genesis, no checkpoint).
  Future<List<BlockHeader>> headersOf(TestNode node) async {
    final cache = MemoryCache();
    final c = await node.connect(MurmurClient()..useCache(cache));
    await until(c, () => cache.headers.length == node.height);
    return cache.headers;
  }

  group('sync', () {
    test('starts from a checkpoint, checks back to genesis, and stores the back-fill batch by batch', () async {
      final node = await long();
      final cp = checkpointOf(node);
      final cache = MemoryCache();
      final c = MurmurClient(checkpoint: cp)..useCache(cache);
      var fromCheckpoint = false;
      c.addListener(() => fromCheckpoint |= c.checkingFromCheckpoint != null);
      await node.connect(c);
      expect(c.headerAt(cp.height)!.id, cp.hash);
      await until(c, () => c.checkingFromCheckpoint == null);
      expect(fromCheckpoint, isTrue);
      expect(c.headerAt(1)!.id, node.hashAt(1));
      // The first batch was stored before the back-fill joined.
      expect(cache.saves, contains((1, 2000)));
      expect(cache.headers.length, node.height, reason: 'the joined chain is stored');
    });

    test('a checkpoint that is not on the chain stops the client', () async {
      final node = await long();
      final c = MurmurClient(checkpoint: Checkpoint(2570, '00' * 32));
      addTearDown(c.dispose);
      await c.connect('127.0.0.1', node.port);
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (c.error == null && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      final kind = c.error?.kind == LinkErrorKind.syncFailed ? c.error?.cause?.kind : c.error?.kind;
      expect(kind, LinkErrorKind.checkpointMismatch);
    });

    test('an interrupted back-fill resumes after the headers in the local copy', () async {
      final node = await long();
      // What an interrupted back-fill leaves: the chain's first 500 headers.
      final cache = MemoryCache((await headersOf(node)).take(500).toList());
      final c = await node.connect(MurmurClient(checkpoint: checkpointOf(node))..useCache(cache));
      await until(c, () => c.checkingFromCheckpoint == null);
      expect(c.headerAt(500)!.id, node.hashAt(500));
      expect(c.headerAt(501)!.id, node.hashAt(501));
      expect(c.headersFromNode, lessThanOrEqualTo(node.height - 500), reason: 'headers 1 to 500 were not fetched again');
      expect(cache.headers.length, node.height);
    });

    test('stored headers of another chain are dropped, and the back-fill starts over from genesis', () async {
      final other = await TestNode.build(500, mineTo: await someoneElse());
      await other.start();
      final stored = await headersOf(other);
      await other.stop();
      final node = await long();
      final cp = checkpointOf(node);
      final c = await node.connect(MurmurClient(checkpoint: cp)..useCache(MemoryCache(stored)));
      await until(c, () => c.checkingFromCheckpoint == null);
      expect(c.headersFromNode, greaterThan(cp.height - NetworkInfo.demo.lwmaWindow - 1), reason: 'checked from genesis');
      expect(c.headerAt(1)!.id, node.hashAt(1));
      expect(c.headerAt(cp.height)!.id, cp.hash);
    });

    test('a reorganization rebuilds the header history from the nearest mark', () async {
      // From genesis (the demo network has no checkpoint), past the marks
      // at 1,024 and 2,048. Ending ten minutes ago leaves the branches
      // room: demo-chain refuses a branch of n blocks without n × 2 s after
      // its fork point (120 blocks: four minutes).
      final node = await TestNode.build(2100,
          mineTo: miner.address, endTime: DateTime.now().subtract(const Duration(minutes: 10)));
      await node.start();
      final c = await node.connect(MurmurClient());
      final before = List.of(node.hashes);
      bool following(TestNode n) => c.height == n.height && toHex(c.hashAt(n.height)) == n.hashAt(n.height);
      // A heavier branch from block 2,060: the client rolls back to it,
      // rebuilds the history from the mark at 2,048, and checks every new
      // header's history root against it.
      await node.stop();
      await node.grow(2130, mineTo: await someoneElse(), forkAt: 2060);
      await node.start();
      await until(c, () => following(node), reconnecting: true);
      expect(c.headerAt(2060)!.id, before[2059]);
      expect(c.headerAt(2061)!.id, isNot(before[2060]));
      // A second one, below the newest mark: from the one before.
      await node.stop();
      await node.grow(2160, mineTo: miner.address, forkAt: 2040);
      await node.start();
      await until(c, () => following(node), reconnecting: true);
      expect(c.headerAt(2041)!.id, node.hashAt(2041));
    }, timeout: const Timeout(Duration(minutes: 2)));
  }, skip: nodeSkip);

  // A short chain ending now, for what doesn't need many blocks; the node
  // mines on top to the same wallet when transactions must be mined.
  Future<TestNode> short({bool mining = false}) async {
    final node = await TestNode.build(300, mineTo: miner.address);
    await node.start(mineTo: mining ? miner.address : null);
    return node;
  }

  group('state and sending', () {
    test('proves state, finds an address through filters, without the chain', () async {
      await checkProvenState((c) async => (await short()).connect(c));
    });

    test('with a local copy, counts the chain and agrees with the state root; a second session starts from it', () async {
      final node = await short();
      await checkLocalCopy(node.connect);
    });

    test('sends with proven nonces and gets transactions mined', () async {
      final node = await short(mining: true);
      final client = await node.connect(MurmurClient());
      final wallet = miner;
      final me = wallet.addressHex;
      await until(client, () => client.availableTo(me) != null);
      final start = client.account(me)!;
      print('wallet ${me.substring(0, 12)}… balance ${start.balance}, nonce ${start.nonce}');
      expect(start.balance, greaterThan(100), reason: 'the built chain pays this wallet');
  
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
      await until(client, what: 'status', () => client.statusOf(raw.id) != null);
      expect(client.statusOf(raw.id)!.code, TxStatusCode.accepted, reason: client.statusOf(raw.id)!.reason);
  
      await until(client, what: 'orphan and raw mined', () =>
          (client.lookupTx(orphan.id)?.confirmed ?? false) && (client.lookupTx(raw.id)?.confirmed ?? false));
      final mined = client.lookupTx(orphan.id)!;
      expect(String.fromCharCodes(messageOf(mined.content!)), text);
      expect(mined.height, greaterThan(snapshot));
      expect(client.threads(upTo: snapshot).any((t) => t.root.tx.id == orphan.id), isTrue);
      await until(client, what: 'recipient balance', () => (client.account(recipient.addressHex)?.balance ?? 0) == 5);
      await until(client, what: 'nonce +2', () => (client.account(me)?.nonce ?? 0) == start.nonce + 2);
      print('orphan mined in block ${mined.height}, transfer in block ${client.lookupTx(raw.id)!.height}');
  
      // Threads: a reply chain and a flag, proven not flagged before.
      Uint8List utf(String s) => MurmurClient.encodeText(s);
      final older = await client.submit(
          wallet: wallet, kind: TxKind.orphan, amount: orphanBurn(1), fee: 1, message: utf('older thread $text'));
      await until(client, what: 'older mined', () => client.lookupTx(older.id)?.confirmed ?? false);
      // Mined a moment ago, likely above the block the nonce proof is from:
      // the next nonce is past it all the same.
      expect(client.nextNonce(me), older.nonce + 1);
      final reply = await client.submit(
          wallet: wallet, kind: TxKind.reply, to: older.from, amount: 1, fee: 1, message: utf('a reply'), reference: older.id);
      await until(client, what: 'flag proof', () => client.provenFlagged(me, older.id) != null);
      final flag = await client.submit(wallet: wallet, kind: TxKind.flag, fee: 1, reference: older.id);
      expect(
          () => client.submit(wallet: wallet, kind: TxKind.flag, fee: 1, reference: older.id),
          throwsA(isA<TxProblem>().having((p) => p.kind, 'kind', TxProblemKind.alreadyFlagged)),
          reason: 'one flag per address per message');
      String txState(Transaction t) {
        final view = client.lookupTx(t.id);
        final status = client.statusOf(t.id);
        final where = view == null ? 'unknown' : (view.confirmed ? 'mined at ${view.height}' : 'pending');
        return '${t.kind.name} nonce ${t.nonce}: $where, node said ${status?.code.name} ${status?.reason ?? ''}';
      }

      await until(client, what: 'reply and flag mined', () =>
          (client.lookupTx(reply.id)?.confirmed ?? false) && (client.lookupTx(flag.id)?.confirmed ?? false),
          state: () => '${txState(reply)}; ${txState(flag)}; proven nonce ${client.account(me)?.nonce}');
      await until(client, what: 'flagged proven', () => client.provenFlagged(me, older.id) == true);
      final thread = client.threads().firstWhere((t) => t.root.tx.id == older.id);
      expect((thread.replies, thread.flags), (1, 1));
      // That flag was the author's own: a retraction. Its text is deleted here
      // and never fetched again; the reply keeps its own.
      final withdrawn = client.lookupTx(older.id)!;
      expect(client.contentWithdrawn(withdrawn.tx), isTrue);
      expect(client.liveContent(withdrawn), isNull);
      expect(client.contentExpected(withdrawn.tx), isFalse);
      expect(client.liveContent(client.lookupTx(reply.id)!), isNotNull);

      // Another device opens its Threads tab on this chain: while its blocks
      // arrive, newest first, no thread it has listed is ever moved. New
      // ones only join at the end.
      final reader = await node.connect(MurmurClient());
      final upTo = reader.height;
      var listed = <String>[];
      void check() {
        final now = [for (final t in reader.threads(upTo: upTo)) t.root.tx.id];
        expect(now.take(listed.length), listed, reason: 'a listed thread moved');
        listed = now;
        reader.requestOlder(); // as the list does while it has room
      }

      reader.addListener(check);
      check();
      await until(reader, what: 'every thread listed', () => !reader.canLoadOlder && !reader.threadsHeldBack);
      reader.removeListener(check);
      check();
      expect(listed, containsAll([orphan.id, older.id]));
      // And it ends as the list of the device that saw them being sent,
      // which got them in another order.
      expect(listed, [for (final t in client.threads(upTo: upTo)) t.root.tx.id]);
    }, timeout: const Timeout(Duration(minutes: 3)));
  
    test('invitations: funded cards are claimed by a new wallet, or taken back', () async {
      final client = await (await short(mining: true)).connect(MurmurClient());
      final inviter = miner;
      await until(client, () => client.availableTo(inviter.addressHex) != null);
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
      await until(client, () => addresses.every((a) => (client.account(a)?.balance ?? 0) == costs.perCard));
      print('2 cards funded with ${costs.perCard} each');
  
      // A newcomer claims the first into a brand-new wallet.
      final newcomer = await MurmurWallet.generate();
      await sweepInvitation(client: client, invite: invites[0], to: newcomer.address);
      // The inviter takes back the second.
      await sweepInvitation(client: client, invite: invites[1], to: inviter.address);
      await until(client, () => (client.account(newcomer.addressHex)?.balance ?? 0) > 0);
      await until(client, () => addresses.every((a) => client.account(a)?.balance == 0));
      expect(client.account(newcomer.addressHex)!.balance, costs.perCard - costs.claimFee);
      expect(inviteState(client, cards[0], addresses[0]), InviteState.claimed);
      expect(inviterOf(client, addresses[0]), inviter.addressHex);
      print('claimed ${client.account(newcomer.addressHex)!.balance} into a new wallet: '
          '${costs.perCard - costs.claimFee} = five threads');
    }, timeout: const Timeout(Duration(minutes: 3)));
  }, skip: nodeSkip);
}
